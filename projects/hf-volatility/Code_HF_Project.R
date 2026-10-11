
##################
# 1. LOAD PACKAGES
##################
# install.packages("xts")
# install.packages("rugarch")
# install.packages("moments")
# install.packages("xts")
# install.packages("xtable")
# install.packages("httr")
# install.packages("jsonlite")
# install.packages("tidyverse")

library(xts)
library(rugarch)
library(moments)
library(xtable)
library(httr)
library(jsonlite)
library(tidyverse)
rm(list=ls())

dir.create("figures", showWarnings = FALSE)
dir.create("tables", showWarnings = FALSE)
dir.create("data", showWarnings = FALSE)

##################
# 1.Bis: Create the dataset 
# For some reasons, when we rerun it changes the dataset, probably because of the 
# API restriction and therefore affect the results. 
# Hence we put this part in comment so it does not affect the results but you can 
# see how to get the data by yourself if you want to replicate the analysis.
# The initial dataset is available in "data/SP500_1_min.csv" and was obtained using the code below.
##################

# API key (need to create an account on "massive.com" to have your personal one)
#api_key <- "..." 

# Parameters 
#ticker <- "SPY"               # Stock code
#date_debut <- "2024-04-01"    # Starting date 
#date_fin <- "2024-07-11"      # Ending Date (because of the API restiction 
# it was not possible to have the data after this date

# url building 
#url <- paste0(
#  "https://api.polygon.io/v2/aggs/ticker/",
#  ticker,
#  "/range/1/minute/",           
#  date_debut, "/", date_fin,
#  "?adjusted=true&sort=asc&limit=50000&apiKey=", api_key
#)


# Load the data 
#response <- GET(url)

# Convert in a data frame 
#raw_data <- fromJSON(content(response, "text", encoding = "UTF-8"))
#hf_data <- as.data.frame(raw_data$results)


# Rename data to have it in an understandable format (v = volume, vw = vwap, o = open, c = close, h = high, l = low, t = timestamp)
#names(hf_data) <- c("volume", "vwap", "open", "close", "high", "low", "timestamp", "transactions")

# Convert the date format
#hf_data$timestamp <- as.POSIXct(hf_data$timestamp / 1000, origin = "1970-01-01", tz = "America/New_York")

# Reorganise column for simplicity
#hf_data <- hf_data %>%
 # select(timestamp, open, high, low, close, volume, vwap, transactions) %>%
#  arrange(timestamp)

#Save it (if you want)
#write.csv(hf_data, "data/SP500_1_min.csv", row.names = FALSE)

##################
# 2. LOAD THE DATA
##################

hf_data <- read.csv("data/SP500_1_min.csv", stringsAsFactors = FALSE)

hf_data$timestamp <- as.POSIXct(hf_data$timestamp, tz = "America/New_York")

head(hf_data)

##################
# 3. FILTER: TRADING HOURS + REMOVE DUPLICATES
##################

hf_data <- hf_data %>%
  arrange(timestamp) %>%
  distinct(timestamp, .keep_all = TRUE) %>%
  mutate(
    hour_min = as.numeric(format(timestamp, "%H")) * 60 +
      as.numeric(format(timestamp, "%M")),
    date = as.Date(timestamp, tz = "America/New_York")) %>%
  filter(hour_min >= 570, hour_min <= 960) %>%  # 9:30 - 16:00
  filter(!is.na(timestamp), !is.na(close))

##################
# 4. FUNCTION TO AGGREGATE AND COMPUTE RETURNS AT ANY FREQUENCY
##################

# Subsample prices every k minutes and compute returns + daily RV
compute_daily_rv <- function(data, k) {
  # Keep every k-th minute starting from 9:30
  sub <- data %>%
    group_by(date) %>%
    filter((row_number() - 1) %% k == 0) %>%
    mutate(ret = log(close) - log(dplyr::lag(close))) %>%
    filter(!is.na(ret)) %>%
    # Daily RV = sum of squared returns
    summarise(RV = sum(ret^2), .groups = "drop")
  return(sub)
}

##################
# 5. SIGNATURE PLOT: RV at different frequencies
##################

rv_1m  <- compute_daily_rv(hf_data, 1)
rv_2m  <- compute_daily_rv(hf_data, 2)
rv_5m  <- compute_daily_rv(hf_data, 5)
rv_10m <- compute_daily_rv(hf_data, 10)
rv_15m <- compute_daily_rv(hf_data, 15)

avg_rv <- c(mean(rv_1m$RV), mean(rv_2m$RV), mean(rv_5m$RV),
            mean(rv_10m$RV), mean(rv_15m$RV))
freqs  <- c(1, 2, 5, 10, 15)

png("figures/signature_plot.png", width = 800, height = 500)
par(mfrow = c(1,1))
plot(freqs, avg_rv, type = "b", pch = 19, col = "blue", lwd = 2,
     xlab = "Sampling frequency (minutes)",
     ylab = "Average daily RV",
     main = "RV Signature Plot")
grid()

dev.off()

##################
# 6. DAILY REALIZED VOLATILITY (5-min + daily)
##################

# Daily volatility (using daily data)
daily_close <- hf_data %>%
  group_by(date) %>%
  summarise(close = last(close), .groups = "drop") %>%
  arrange(date)

daily_var <- daily_close %>%
  mutate(
    ret = log(close) - log(dplyr::lag(close)),
    var_daily = ret^2) %>%
  filter(!is.na(ret))

# Daily RV (using 5 minutes frequency data)
rv_daily <- compute_daily_rv(hf_data, 5)

# Comparison dataset for plot 
comparison <- rv_5m %>%
  inner_join(daily_var %>% select(date, var_daily), by = "date")

# Plot comparaison
png("figures/variance_comparison.png", width = 800, height = 500)
par(mfrow = c(1,2))

plot(comparison$date, comparison$RV, type = "l", col = "blue", lwd = 2,
     xlab = "Date", ylab = "Realized Variance",
     main = "Variance (5-min)")
grid()

plot(comparison$date, comparison$var_daily, type = "l", col = "red", lwd = 2,
     xlab = "Date", ylab = "Variance",
     main = "Variance (Daily)")
grid()

dev.off()
par(mfrow = c(1,1))

##################
# 7. AGGREGATE DAILY VOLUME AND TRANSACTIONS
##################

daily_activity <- hf_data %>%
  group_by(date) %>%
  summarise(
    volume = sum(volume, na.rm = TRUE),
    trans = sum(transactions, na.rm = TRUE), .groups = "drop")

# Merge with RV
rv_daily <- rv_daily %>%
  left_join(daily_activity, by = "date")

head(rv_daily)

##################
# 8. DESCRIPTIVE STATISTICS
##################

cat("\n  Descriptive Statistics: Daily RV  \n")
cat("Mean:    ", mean(rv_daily$RV), "\n")
cat("Std:     ", sd(rv_daily$RV), "\n")
cat("Skewness:", skewness(rv_daily$RV), "\n")
cat("Kurtosis:", kurtosis(rv_daily$RV), "\n")

# Autocorrelation of RV (shows long memory)

png("figures/acf_plot.png", width = 800, height = 400)
par(mfrow = c(1,2))

acf(rv_daily$RV, lag.max = 30, main = "ACF of Daily RV")
acf(log(rv_daily$RV), lag.max = 30, main = "ACF of log(RV)")

dev.off()
# Distribution of log(RV)
png("figures/distribution_RV.png", width = 800, height = 400)
par(mfrow = c(1,1))
hist(rv_daily$RV, breaks = 20, probability = TRUE,
     main = "Distribution of Daily RV", xlab = "RV", col = "lightblue")
lines(density(rv_daily$RV), col = "red", lwd = 2)
dev.off()

##################
# DESCRIPTIVE STATISTICS: VOLUME AND TRANSACTIONS
##################

desc_activity <- data.frame(
  Statistic = c("Mean", "Std. Dev", "Min", "Max"),
  Volume    = c(mean(rv_daily$volume), sd(rv_daily$volume),
                min(rv_daily$volume), max(rv_daily$volume)),
  Transactions = c(mean(rv_daily$trans), sd(rv_daily$trans),
                   min(rv_daily$trans), max(rv_daily$trans))
)

print(xtable(desc_activity,
             digits  = 0,
             caption = "Descriptive Statistics: Daily Volume and Transactions",
             label   = "tab:activity"),
      include.rownames = FALSE,
      file = "tables/table_activity.tex")

##################
# 10. BUILD HAR-RV COMPONENTS
##################

n_days <- nrow(rv_daily)
rv_vec <- rv_daily$RV

# Weekly RV (5-day average) and Monthly RV (22-day average)
rv_week  <- rep(NA, n_days)
rv_month <- rep(NA, n_days)

for (t in 5:n_days) {
  rv_week[t] <- mean(rv_vec[(t-4):t])
}

for (t in 22:n_days) {
  rv_month[t] <- mean(rv_vec[(t-21):t])
}

# Build the HAR dataframe (start from day 23)
start <- 23
end   <- n_days

har_data <- data.frame(
  date     = rv_daily$date[start:end],
  RV       = rv_vec[start:end],             # RV(t)
  RV_lag1  = rv_vec[(start-1):(end-1)],     # RV(t-1)
  RV_week  = rv_week[(start-1):(end-1)],    # RV_week(t-1)
  RV_month = rv_month[(start-1):(end-1)],   # RV_month(t-1)
  volume   = rv_daily$volume[(start-1):(end-1)],
  trans      = rv_daily$trans[(start-1):(end-1)]
)

har_data <- na.omit(har_data)
cat("\nHAR dataset:", nrow(har_data), "observations\n")
head(har_data)

##################
# 11. MODEL ESTIMATION
##################

# Model 1: HAR-RV ###
har_rv <- lm(RV ~ RV_lag1 + RV_week + RV_month, data = har_data)
cat("\n  HAR-RV Model  \n")
summary(har_rv)

# Model 2: HAR-RV-X (with volume and transactions) ###
har_rvx <- lm(RV ~ RV_lag1 + RV_week + RV_month + volume + trans, data = har_data)
cat("\n  HAR-RV-X Model  \n")
summary(har_rvx)
##################
# IN-SAMPLE FIT PLOT
##################
n_is <- nrow(har_data) - 15
png("figures/insample_fit.png", width = 800, height = 500)
plot(har_data$date[1:n_is], har_data$RV[1:n_is], 
     type = "l", col = "black", lwd = 2,
     xlab = "Date", ylab = "Realized Variance",
     main = "In-Sample Fit: HAR-RV")
lines(har_data$date[1:n_is], fitted(har_rv)[1:n_is], 
      col = "blue", lwd = 2, lty = 2)
legend("topright", legend = c("Actual RV", "HAR-RV Fitted"),
       col = c("black", "blue"), lwd = 2, lty = c(1, 2))
grid()
dev.off()

##################
# 12. GARCH(1,1) BENCHMARK ON DAILY RETURNS
##################

# Compute daily returns (close-to-close)
daily_close <- hf_data %>%
  group_by(date) %>%
  summarise(close = last(close), .groups = "drop") %>%
  arrange(date)

daily_ret <- data.frame(
  date = daily_close$date[-1],
  ret  = 100 * diff(log(daily_close$close))  # in %
)

# Fit GARCH(1,1)
spec <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1,1)),
  mean.model     = list(armaOrder = c(0,0), include.mean = TRUE),
  distribution.model = "norm"
)

garch_fit <- ugarchfit(spec, data = daily_ret$ret)
cat("\n  GARCH(1,1) Model  \n")
print(garch_fit)

# sigma^2 in %^2 -> convert to decimal
garch_sigma2 <- as.numeric(sigma(garch_fit)^2) / 10000
garch_dates  <- daily_ret$date

##################
# TABLE 1: HAR-RV and HAR-RV-X side by side
##################

coef_har  <- summary(har_rv)$coefficients
coef_harx <- summary(har_rvx)$coefficients

adj_r2_har  <- round(summary(har_rv)$adj.r.squared, 3)
adj_r2_harx <- round(summary(har_rvx)$adj.r.squared, 3)
fpval_har   <- round(pf(summary(har_rv)$fstatistic[1],
                        summary(har_rv)$fstatistic[2],
                        summary(har_rv)$fstatistic[3], 
                        lower.tail = FALSE), 3)
fpval_harx  <- round(pf(summary(har_rvx)$fstatistic[1],
                        summary(har_rvx)$fstatistic[2],
                        summary(har_rvx)$fstatistic[3], 
                        lower.tail = FALSE), 3)

fmt <- function(x) formatC(x, format = "e", digits = 2)

row_names <- c("Intercept", "$RV_{t-1}^{(d)}$", "$RV_{t-1}^{(w)}$", 
               "$RV_{t-1}^{(m)}$", "$Vol_{t-1}$", "$Txn_{t-1}$",
               "Adj. $R^2$", "F $p$-value")

tab <- data.frame(
  Variable  = row_names,
  Est_HAR   = c(fmt(coef_har[,1]),  "--", "--", adj_r2_har,  "--"),
  Pval_HAR  = c(round(coef_har[,4], 3), "--", "--", "--", fpval_har),
  Est_HARX  = c(fmt(coef_harx[,1]), adj_r2_harx, "--"),
  Pval_HARX = c(round(coef_harx[,4], 3), "--", fpval_harx)
)

print(xtable(tab,
             caption = "In-Sample Estimation Results: HAR-RV and HAR-RV-X",
             label   = "tab:insample"),
      include.rownames = FALSE,
      sanitize.text.function = identity,
      file = "tables/table_insample.tex")

##################
# TABLE 2: GARCH(1,1)
##################

coef_garch <- as.data.frame(garch_fit@fit$matcoef)
coef_garch <- coef_garch[, c(1, 2, 4)]  # Estimate, Std.Error, p-value
colnames(coef_garch) <- c("Estimate", "Std. Error", "$p$-value")
rownames(coef_garch) <- c("$\\mu$", "$\\omega$", "$\\alpha_1$", "$\\beta_1$")

print(xtable(coef_garch,
             digits  = 4,
             caption = "In-Sample Estimation Results: GARCH(1,1)",
             label   = "tab:garch"),
      sanitize.text.function = identity,
      file = "tables/table_garch.tex")

##################
# 13. OUT-OF-SAMPLE FORECASTING
##################

n_oos <- 15
n_is  <- nrow(har_data) - n_oos

cat("\nIn-sample:", n_is, "days | Out-of-sample:", n_oos, "days\n")

# HAR-RV rolling forecast 
har_forecast <- rep(NA, n_oos)
for (i in 1:n_oos) {
  train <- har_data[1:(n_is + i - 1), ]
  model <- lm(RV ~ RV_lag1 + RV_week + RV_month, data = train)
  test  <- har_data[n_is + i, ]
  har_forecast[i] <- predict(model, newdata = test)
}

# HAR-RV-X rolling forecast 
harx_forecast <- rep(NA, n_oos)
for (i in 1:n_oos) {
  train <- har_data[1:(n_is + i - 1), ]
  model <- lm(RV ~ RV_lag1 + RV_week + RV_month + volume + trans, data = train)
  test  <- har_data[n_is + i, ]
  harx_forecast[i] <- predict(model, newdata = test)
}

#### GARCH forecast 
# Match GARCH dates with HAR out-of-sample dates
oos_dates <- har_data$date[(n_is + 1):(n_is + n_oos)]
garch_df  <- data.frame(date = garch_dates, sigma2 = garch_sigma2)
garch_oos <- garch_df %>% filter(date %in% oos_dates)
garch_forecast <- garch_oos$sigma2

# Actual RV
rv_actual <- har_data$RV[(n_is + 1):(n_is + n_oos)]

##################
# 14. FORECAST EVALUATION
##################

rmse <- function(actual, forecast) sqrt(mean((actual - forecast)^2))
mae  <- function(actual, forecast) mean(abs(actual - forecast))
r2_oos <- function(actual, forecast) {
  1 - sum((actual - forecast)^2) / sum((actual - mean(actual))^2)
}

# Make sure lengths match
n_eval <- min(length(rv_actual), length(garch_forecast))
rv_actual_eval    <- rv_actual[1:n_eval]
garch_forecast_eval <- garch_forecast[1:n_eval]
har_forecast_eval   <- har_forecast[1:n_eval]
harx_forecast_eval  <- harx_forecast[1:n_eval]

cat("\n  OUT-OF-SAMPLE FORECAST EVALUATION  \n")

cat("\n  RMSE  \n ")
cat("GARCH(1,1): ", rmse(rv_actual_eval, garch_forecast_eval), "\n")
cat("HAR-RV:     ", rmse(rv_actual_eval, har_forecast_eval), "\n")
cat("HAR-RV-X:   ", rmse(rv_actual_eval, harx_forecast_eval), "\n")

cat("\n  MAE  \n")
cat("GARCH(1,1): ", mae(rv_actual_eval, garch_forecast_eval), "\n")
cat("HAR-RV:     ", mae(rv_actual_eval, har_forecast_eval), "\n")
cat("HAR-RV-X:   ", mae(rv_actual_eval, harx_forecast_eval), "\n")

cat("\n R2 (OOS) \n")
cat("GARCH(1,1): ", r2_oos(rv_actual_eval, garch_forecast_eval), "\n")
cat("HAR-RV:     ", r2_oos(rv_actual_eval, har_forecast_eval), "\n")
cat("HAR-RV-X:   ", r2_oos(rv_actual_eval, harx_forecast_eval), "\n")

##################
# 15. FORECAST COMPARISON PLOT
##################

png("figures/forecast_comparison.png", width = 800, height = 500)
par(mfrow = c(1,1))
y_range <- range(c(rv_actual_eval, har_forecast_eval,
                   harx_forecast_eval, garch_forecast_eval), na.rm = TRUE)

plot(1:n_eval, rv_actual_eval, type = "b", pch = 19, col = "black", lwd = 2,
     ylim = y_range,
     xlab = "Day (out-of-sample)", ylab = "RV",
     main = "Out-of-Sample Forecast Comparison")
lines(1:n_eval, har_forecast_eval,   col = "blue",  lwd = 2, type = "b", pch = 17)
lines(1:n_eval, harx_forecast_eval,  col = "red",   lwd = 2, type = "b", pch = 15)
lines(1:n_eval, garch_forecast_eval, col = "green",  lwd = 2, type = "b", pch = 18)
legend("topright",
       legend = c("Actual RV", "HAR-RV", "HAR-RV-X", "GARCH(1,1)"),
       col = c("black","blue","red","green"),
       pch = c(19,17,15,18), lwd = 2, cex = 0.8)
grid()
dev.off()

##################
# 16. DIEBOLD-MARIANO TEST
##################

e_har   <- rv_actual_eval - har_forecast_eval
e_garch <- rv_actual_eval - garch_forecast_eval
e_harx  <- rv_actual_eval - harx_forecast_eval

dm_test <- function(e1, e2) {
  d <- e1^2 - e2^2
  t_stat <- mean(d) / (sd(d) / sqrt(length(d)))
  p_val  <- 2 * (1 - pnorm(abs(t_stat)))
  return(c(t_stat = round(t_stat, 4), p_value = round(p_val, 4)))
}

cat("\n  DIEBOLD-MARIANO TESTS  \n")
cat("\nHAR-RV vs GARCH(1,1):\n")
print(dm_test(e_har, e_garch))

cat("\nHAR-RV-X vs GARCH(1,1):\n")
print(dm_test(e_harx, e_garch))

cat("\nHAR-RV-X vs HAR-RV:\n")
print(dm_test(e_harx, e_har))

cat("\n  DONE  \n")

##################
# ROBUSTNESS: INTRADAY HAR (5-min RV aggregated at 30min/half-day/daily)
##################

# Build 5-minute returns for all days
intraday_5m <- hf_data %>%
  arrange(timestamp) %>%
  group_by(date) %>%
  filter((row_number() - 1) %% 5 == 0) %>%
  mutate(ret = log(close) - log(dplyr::lag(close))) %>%
  filter(!is.na(ret)) %>%
  mutate(
    # interval index within the day (1 to approx 78)
    interval = row_number(),
    # 30-min block (6 five-minute intervals)
    block_30m = ceiling(interval / 6),
    # half-day block (39 five-minute intervals)
    block_hd  = ceiling(interval / 39)
  ) %>%
  ungroup()

# Compute RV at 30-minute frequency (sum of squared 5-min returns per 30-min block)
rv_30m <- intraday_5m %>%
  group_by(date, block_30m) %>%
  summarise(RV = sum(ret^2), .groups = "drop") %>%
  arrange(date, block_30m)

# For each 30-min observation, we compute the three HAR components:
# short  = RV of previous 30-min block
# medium = average RV over previous half-day (6 blocks of 30min)
# long   = average RV over previous full day (13 blocks of 30min)

rv_30m <- rv_30m %>%
  mutate(row_id = row_number()) %>%
  mutate(
    RV_short  = dplyr::lag(RV, 1),
    RV_medium = zoo::rollmean(dplyr::lag(RV, 1), k = 6,  fill = NA, align = "right"),
    RV_long   = zoo::rollmean(dplyr::lag(RV, 1), k = 13, fill = NA, align = "right")
  ) %>%
  filter(!is.na(RV_short), !is.na(RV_medium), !is.na(RV_long))

cat("\nIntraday HAR dataset:", nrow(rv_30m), "observations\n")

# Split: last 15 days out-of-sample
oos_dates_intra <- tail(unique(rv_30m$date), 15)
rv_30m_is  <- rv_30m %>% filter(!date %in% oos_dates_intra)
rv_30m_oos <- rv_30m %>% filter(date %in% oos_dates_intra)

# Estimate intraday HAR
har_intra <- lm(RV ~ RV_short + RV_medium + RV_long, data = rv_30m_is)
cat("\n Intraday HAR (30-min) in-sample \n")
print(summary(har_intra))

# Forecast
intra_forecast <- predict(har_intra, newdata = rv_30m_oos)
rv_actual_intra <- rv_30m_oos$RV

cat("\n ROBUSTNESS: Intraday HAR (30-min) \n")
cat("In-sample adj R2: ", round(summary(har_intra)$adj.r.squared, 3), "\n")
cat("RMSE: ", rmse(rv_actual_intra, intra_forecast), "\n")
cat("MAE:  ", mae(rv_actual_intra, intra_forecast), "\n")
cat("R2:   ", r2_oos(rv_actual_intra, intra_forecast), "\n")

##################
# ROBUSTNESS: HAR-RV WITHOUT MONTHLY COMPONENT
##################

# Only need 5 days initialization instead of 22
start_dw <- 6

har_data_dw <- data.frame(
  date    = rv_daily$date[start_dw:n_days],
  RV      = rv_vec[start_dw:n_days],
  RV_lag1 = rv_vec[(start_dw-1):(n_days-1)],
  RV_week = rv_week[(start_dw-1):(n_days-1)],
  volume  = rv_daily$volume[(start_dw-1):(n_days-1)],
  trans   = rv_daily$trans[(start_dw-1):(n_days-1)]
)

har_data_dw <- na.omit(har_data_dw)
cat("\nHAR-DW dataset:", nrow(har_data_dw), "observations\n")

n_oos_dw <- 15
n_is_dw  <- nrow(har_data_dw) - n_oos_dw

har_dw <- lm(RV ~ RV_lag1 + RV_week, data = har_data_dw)
cat("\n=== HAR-RV (Daily + Weekly only) ===\n")
print(summary(har_dw))

har_forecast_dw <- rep(NA, n_oos_dw)
for (i in 1:n_oos_dw) {
  train <- har_data_dw[1:(n_is_dw + i - 1), ]
  model <- lm(RV ~ RV_lag1 + RV_week, data = train)
  test  <- har_data_dw[n_is_dw + i, ]
  har_forecast_dw[i] <- predict(model, newdata = test)
}

rv_actual_dw <- har_data_dw$RV[(n_is_dw + 1):(n_is_dw + n_oos_dw)]

cat("\n ROBUSTNESS: HAR-DW (no monthly component) \n")
cat("In-sample obs: ", n_is_dw, "\n")
cat("In-sample adj R2: ", round(summary(har_dw)$adj.r.squared, 3), "\n")
cat("RMSE: ", rmse(rv_actual_dw, har_forecast_dw), "\n")
cat("MAE:  ", mae(rv_actual_dw, har_forecast_dw), "\n")
cat("R2:   ", r2_oos(rv_actual_dw, har_forecast_dw), "\n")

