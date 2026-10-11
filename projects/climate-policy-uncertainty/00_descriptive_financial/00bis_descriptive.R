#----------------------------------------------------------------------------#
#                                   PACKAGES                                 #
#----------------------------------------------------------------------------#

library(tidyverse)
library(readxl)
library(plm)
library(modelsummary)
library(knitr)
library(kableExtra)
library(tidyquant)
library(ggplot2)
library(dplyr)
library(scales)
library(xtable)

#----------------------------------------------------------------------------#
#                                DATA CLEANING                               #
#----------------------------------------------------------------------------#

rm(list=ls())
# Dataset Path on the computer + wd
path = ("data/DATA_company.xlsx")

# Downloading all the data from the computer into 30 small datasets + VIX + WTI
for (x in 1:30) {
  assign(paste0("bdd_", x), read_excel(path, skip = 3, sheet = x, col_names = T))
}

vix <- read_excel("data/VIXCLS.xlsx", col_names = T)
wti <- read_excel("data/WTI.xlsx",skip = 5, col_names = T)

# Function that clean and tidy the data 
cleaner <- function(x){
  x <- x[-c(1,2),] # delete the first 2 rows 
  company <- trimws(sub("-.*$", "", names(x)[2])) # create company name value 
  x$company_name <- company # create the company name column 
  colnames(x) <- c("date", 'VWAP', "employees", "R&D", "capital_expenditure",
                   "total_assets", "hist_vol_(5y)", "debt/equity", "total_CO2_emission",
                   "green_revenue_(%)", "company_name") # rename the columns 
  x$date <- as.Date(as.numeric(x$date), origin = "1899-12-30") # transform the date column from the excel format to a clasical format
  cols <- setdiff(names(x), c("date", "company_name")) # List of columns that we need to convert in integer
  x[cols] <- lapply(x[cols], as.numeric) # converting the columns into integer 
  return(x)
}

# Creating a list with the datasets names 
name <- paste0("bdd_", 1:30)

# List of tibble with all the datasets inside
bdd_list <- lapply(name, get)

# Applying the cleaner function to all the datasets in the list 
bdd_list_clean <- lapply(bdd_list, cleaner)

# Use the bind_rows function to merge all the datasets and have the final one 
bdd_final <- bind_rows(bdd_list_clean)

# Cleaning environment 
rm(list = setdiff(ls(), c("bdd_final", "vix", "wti")))

# Creating a sector column 
bdd_final <- bdd_final %>%
  mutate(
    sector = case_when(
      company_name %in% c("APPLE",
                          "CISCO SYSTEMS",
                          "INTERNATIONAL BUS.MCHS.",
                          "MICROSOFT",
                          "NVIDIA",
                          "SALESFORCE") ~ "Information Technology",
      
      company_name %in% c("AMERICAN EXPRESS",
                          "GOLDMAN SACHS GP.",
                          "JP MORGAN CHASE & CO.",
                          "VISA 'A'") ~ "Financials",
      
      company_name %in% c("AMGEN",
                          "JOHNSON & JOHNSON",
                          "MERCK & COMPANY",
                          "UNITEDHEALTH GROUP") ~ "Healthcare / Biopharmaceuticals",
      
      company_name %in% c("AMAZON.COM",
                          "HOME DEPOT",
                          "MCDONALDS",
                          "NIKE 'B'",
                          "WALMART") ~ "Consumer Discretionary / Retailing",
      
      company_name %in% c("COCA COLA",
                          "PROCTER & GAMBLE") ~ "Consumer Staples",
      
      company_name %in% c("3M",
                          "BOEING",
                          "CATERPILLAR",
                          "HONEYWELL INTL.") ~ "Industrials",
      
      company_name == "CHEVRON" ~ "Energy",
      
      company_name == "WALT DISNEY" ~ "Broadcasting & Entertainment",
      
      company_name == "TRAVELERS COS." ~ "Insurance",
      
      company_name == "VERIZON COMMUNICATIONS" ~ "Telecommunications",
      
      company_name == "SHERWIN" ~ "Materials",
      
      TRUE ~ "Others"
    )
  )


vix <- vix %>%
  rename(date = 1, vix = 2) %>%
  mutate(date = as.Date(date))

wti <- wti %>%
  rename(date = 1, wti = 2) %>%
  mutate(date = as.Date(date))

bdd_final <- full_join(bdd_final, vix, by = "date")
bdd_final <- full_join(bdd_final, wti, by = "date")


#----------------------------------------------------------------------------#
#                            NEW DATA DOWNLOADING                            #
#----------------------------------------------------------------------------#

tickers <- c("AAPL", "MSFT", "NVDA", "CSCO", "IBM", "CRM",     # IT
             "AXP", "GS", "JPM", "V",                          # Financials
             "AMGN", "JNJ", "MRK", "UNH",                      # Healthcare
             "AMZN", "HD", "MCD", "NKE", "WMT",                # Consumer Disc.
             "KO", "PG",                                       # Consumer Staples
             "MMM", "BA", "CAT", "HON",                        # Industrials
             "CVX",                                            # Energy
             "DIS", "TRV", "VZ", "SHW")                        # Others

# Map tickers to company names to match your existing df
ticker_map <- tibble(
  symbol       = tickers,
  company_name = c("APPLE", "MICROSOFT", "NVIDIA", "CISCO SYSTEMS",
                   "INTERNATIONAL BUS.MCHS.", "SALESFORCE",
                   "AMERICAN EXPRESS", "GOLDMAN SACHS GP.",
                   "JP MORGAN CHASE & CO.", "VISA 'A'",
                   "AMGEN", "JOHNSON & JOHNSON", "MERCK & COMPANY",
                   "UNITEDHEALTH GROUP",
                   "AMAZON.COM", "HOME DEPOT", "MCDONALDS",
                   "NIKE 'B'", "WALMART",
                   "COCA COLA", "PROCTER & GAMBLE",
                   "3M", "BOEING", "CATERPILLAR", "HONEYWELL INTL.",
                   "CHEVRON",
                   "WALT DISNEY", "TRAVELERS COS.",
                   "VERIZON COMMUNICATIONS", "SHERWIN")
)

# Sector map for heterogeneity analysis
sector_map <- tibble(
  symbol = tickers,
  sector = c(rep("Information Technology", 6),
             rep("Financials", 4),
             rep("Healthcare", 4),
             rep("Consumer Discretionary", 5),
             rep("Consumer Staples", 2),
             rep("Industrials", 4),
             "Energy",
             "Broadcasting & Entertainment",
             "Insurance",
             "Telecommunications",
             "Materials")
)

# Download raw daily data
raw_prices <- tq_get(
  tickers,
  from = "2016-01-01",   # start early for rolling window initialization
  to   = Sys.Date(),
  get  = "stock.prices"
)


#----------------------------------------------------------------------------#
#                            NEW DATA CLEANING                               #
#----------------------------------------------------------------------------#

# Create return column on the VWAP
bdd_final_clean <- bdd_final %>%
  filter(!is.na(VWAP)) %>%
  mutate(VWAP = as.numeric(VWAP),
         VWAP_return = (VWAP - dplyr::lag(VWAP)) / dplyr::lag(VWAP))

# Create monthly realized volatility from the VWAP
real_vol <- bdd_final_clean %>%
  arrange(company_name, date) %>%
  group_by(company_name) %>%
  mutate(daily_return = (VWAP - dplyr::lag(VWAP)) / dplyr::lag(VWAP)) %>%
  ungroup() %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(company_name, month) %>%
  summarise(realized_vol = sd(daily_return, na.rm = TRUE) * sqrt(21), .groups = "drop") #here sqrt(21) because 21 trading days in a month on average.

# Rename column to merge 
real_vol <- real_vol %>%
  rename(date = month)

# Abnormal traiding volume 
monthly_firm <- raw_prices %>%
  arrange(symbol, date) %>%  
  group_by(symbol) %>%
  mutate(daily_return = (adjusted - lag(adjusted)) / lag(adjusted)) %>%
  ungroup() %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(symbol, month) %>%
  summarise(avg_volume   = mean(volume, na.rm=TRUE),
            total_volume = sum(volume,  na.rm=TRUE),
            log_volume   = log(mean(volume, na.rm=TRUE)),
            realized_vol = sd(daily_return, na.rm=TRUE) * sqrt(21),
            monthly_return = last(adjusted) / first(adjusted) - 1,
            turnover     = mean(abs(daily_return), na.rm=TRUE),
            .groups="drop") %>%
  left_join(ticker_map, by="symbol") %>%
  left_join(sector_map, by="symbol") %>%
  filter(month >= as.Date("2017-01-01"))


monthly_firm <- monthly_firm %>%
  arrange(symbol, month) %>%
  group_by(symbol) %>%
  mutate(vol_roll_mean = rollmean(log_volume, k=12, fill=NA, align="right"),
         abnormal_vol  = log_volume - lag(vol_roll_mean)) %>%
  ungroup()

monthly_firm <- monthly_firm %>%
  rename(date = month)


# Merging all the new data into the database
bdd_final_clean <- full_join(bdd_final_clean, ticker_map, by = "company_name")
bdd_final_clean <- full_join(bdd_final_clean, raw_prices, by = c("symbol", "date"))
bdd_final_clean <- full_join(bdd_final_clean, real_vol, by = c("company_name", "date"))
bdd_final_clean <- left_join(bdd_final_clean, monthly_firm %>% 
                               select(c("company_name", "date"), abnormal_vol), by = c("company_name", "date"))

# write_csv(bdd_final_clean, "bdd_final_clean.csv")

#----------------------------------------------------------------------------#
#                             SUMMARY STATISTICS                             #
#----------------------------------------------------------------------------#

df <- bdd_final_clean

# ─────────────────────────────────────────────
# 2. Descriptive statistics function
# ─────────────────────────────────────────────
desc_stats <- function(x) {
  x <- na.omit(x)
  data.frame(
    Mean         = mean(x),
    Median       = median(x),
    SD           = sd(x),
    Min          = min(x),
    P25          = quantile(x, 0.25),
    P75          = quantile(x, 0.75),
    Max          = max(x),
    row.names    = NULL
  )
}

# Variable names 
variables <- c(
  VWAP_return = "Returns VWAP",
  realized_vol = "Realized Volatility",
  abnormal_vol = "Abnormal Volume"
)

# ─────────────────────────────────────────────
# 3. Company level board
# ─────────────────────────────────────────────
company_tbl <- do.call(rbind, lapply(names(variables), function(var) {
  row <- desc_stats(df[[var]])
  cbind(Variable = variables[[var]], row)
}))
rownames(company_tbl) <- NULL


# ─────────────────────────────────────────────
# 5. Round function
# ─────────────────────────────────────────────
fmt <- function(tbl) {
  num_cols <- sapply(tbl, is.numeric)
  tbl[num_cols] <- lapply(tbl[num_cols], round, digits = 4)
  tbl
}

company_tbl <- fmt(company_tbl)

# ─────────────────────────────────────────────
# 6. Xtable board export 
# ─────────────────────────────────────────────
make_xtable <- function(tbl, caption, label) {
  xtable(
    tbl,
    caption = caption,
    label   = label,
    digits  = c(0, 0, 4, 4, 4, 4, 4, 4, 4)
  )
}

xtbl_company <- make_xtable(
  company_tbl,
  caption = "Descriptives statistics Company level",
  label   = "tab:desc_company"
)

print(xtbl_company)


#----------------------------------------------------------------------------#
#                          SUMMARY STATISTICS PLOTS                          #
#----------------------------------------------------------------------------#

# ============================================================
#  VWAP Return Distribution Plots — One per Company
# ============================================================

# ── 2. Load data ──────────────────────────────────────────
df <- bdd_final_clean %>%
  filter(!is.na(VWAP_return), !is.na(company_name), company_name != "NA",
         as.Date(date) >= as.Date("2017-01-01")) %>%
  mutate(VWAP_return = as.numeric(VWAP_return))

companies <- sort(unique(df$company_name))
cat(sprintf("Companies found: %d\n", length(companies)))

# ── 3. Output directory ───────────────────────────────────
output_dir <- "plots/vwap_return_plots"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── 4. Custom theme ───────────────────────────────────────
theme_vwap <- theme_minimal(base_size = 13) +
  theme(
    plot.title        = element_text(face = "bold", size = 15, hjust = 0.5,
                                     margin = margin(b = 6)),
    plot.subtitle     = element_text(hjust = 0.5, colour = "grey45", size = 11),
    axis.title        = element_text(size = 11),
    axis.text         = element_text(colour = "grey30"),
    panel.grid.major  = element_line(colour = "grey90"),
    panel.grid.minor  = element_blank(),
    plot.background   = element_rect(fill = "white", colour = NA),
    panel.background  = element_rect(fill = "white", colour = NA),
    legend.position   = "bottom",
    legend.key.width  = unit(1.8, "cm"),
    legend.text       = element_text(size = 10)
  )

# ── 5. Per-company plots ──────────────────────────────────
for (comp in companies) {
  
  sub <- df %>% filter(company_name == comp)
  
  mu   <- mean(sub$VWAP_return,   na.rm = TRUE)
  med  <- median(sub$VWAP_return, na.rm = TRUE)
  sdev <- sd(sub$VWAP_return,     na.rm = TRUE)
  skew <- mean(((sub$VWAP_return - mu) / sdev)^3, na.rm = TRUE)
  kurt <- mean(((sub$VWAP_return - mu) / sdev)^4, na.rm = TRUE)
  n    <- nrow(sub)
  
  sector_label <- sub %>%
    filter(!is.na(sector)) %>%
    pull(sector) %>%
    first()
  if (is.null(sector_label) || is.na(sector_label)) sector_label <- "Unknown"
  
  # Data frame for vlines — enables legend mapping
  vlines_df <- data.frame(
    xintercept = c(mu, med),
    Indicator  = c("Mean", "Median")
  )
  
  p <- ggplot(sub, aes(x = VWAP_return)) +
    
    # Histogram (fixed colour, not in legend)
    geom_histogram(
      aes(y = after_stat(density)),
      bins      = 60,
      fill      = "#2E86AB",
      colour    = "white",
      alpha     = 0.85,
      linewidth = 0.2
    ) +
    
    # Normal distribution overlay for comparison
    stat_function(
      aes(colour = "Normal fit", linetype = "Normal fit"),
      fun       = dnorm,
      args      = list(mean = mu, sd = sdev),
      linewidth = 0.9,
      linetype  = "dotted"
    ) +
    
    # KDE curve — mapped so it enters the legend
    geom_density(
      aes(colour = "KDE Density", linetype = "KDE Density"),
      linewidth = 1.1
    ) +
    
    # Mean & Median lines — mapped via vlines_df
    geom_vline(
      data      = vlines_df,
      aes(xintercept = xintercept,
          colour     = Indicator,
          linetype   = Indicator),
      linewidth = 0.9
    ) +
    
    scale_colour_manual(
      name   = NULL,
      values = c(
        "KDE Density" = "#E84855",
        "Normal fit"  = "#6A0572",
        "Mean"        = "#F4A261",
        "Median"      = "#2EC4B6"
      )
    ) +
    
    scale_linetype_manual(
      name   = NULL,
      values = c(
        "KDE Density" = "solid",
        "Normal fit"  = "dotted",
        "Mean"        = "dashed",
        "Median"      = "dotdash"
      )
    ) +
    
    # Merge colour + linetype into one legend
    guides(
      colour   = guide_legend(override.aes = list(linewidth = 1.2)),
      linetype = guide_legend()
    ) +
    
    # Stats annotation box (includes skewness & kurtosis — key for log returns)
    annotate(
      "label",
      x      = Inf,
      y      = Inf,
      label  = sprintf(
        "n        = %d\nMean   = %.5f\nMedian = %.5f\nSD       = %.5f\nSkew   = %.3f\nKurt    = %.3f",
        n, mu, med, sdev, skew, kurt
      ),
      hjust  = 1.05,
      vjust  = 1.15,
      size   = 3.2,
      fill   = "white",
      colour = "grey20",
      family = "mono"
    ) +
    
    scale_x_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    scale_y_continuous(labels = scales::label_number(accuracy = 0.1)) +
    
    labs(
      title    = comp,
      subtitle = sprintf("Sector: %s  |  VWAP Returns", sector_label),
      x        = "VWAP Return",
      y        = "Density"
    ) +
    theme_vwap
  
  safe_name <- gsub("[^A-Za-z0-9_]", "_", comp)
  safe_name <- gsub("_+", "_", safe_name)
  safe_name <- trimws(safe_name, which = "both")
  
  filename <- file.path(output_dir, sprintf("VWAP_Return_%s.png", safe_name))
  
  ggsave(
    filename = filename,
    plot     = p,
    width    = 9,
    height   = 5.5,
    dpi      = 180,
    bg       = "white"
  )
  
  cat(sprintf("  ✔  Saved: %s\n", basename(filename)))
}

cat(sprintf("\nAll plots saved to: %s\n", output_dir))




# ============================================================
#  VWAP Return — Monthly Time Series Plots — One per Company
# ============================================================

# ── 2. Load data ──────────────────────────────────────────
df <- bdd_final_clean %>%
  filter(!is.na(VWAP_return), !is.na(company_name), company_name != "NA",
         as.Date(date) >= as.Date("2017-01-01")) %>%
  mutate(VWAP_return = as.numeric(VWAP_return))

# ── Aggregate to monthly (sum of daily log returns) ───────
df_monthly <- df %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(company_name, sector, month) %>%
  summarise(
    VWAP_return = sum(VWAP_return, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(company_name, month)

companies <- sort(unique(df_monthly$company_name))
cat(sprintf("Companies found: %d\n", length(companies)))

# ── 3. Output directory ───────────────────────────────────
output_dir <- "plots/vwap_logreturn_timeseries_monthly"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── 4. Custom theme ───────────────────────────────────────
theme_ts <- theme_minimal(base_size = 13) +
  theme(
    plot.title        = element_text(face = "bold", size = 15, hjust = 0.5,
                                     margin = margin(b = 4)),
    plot.subtitle     = element_text(hjust = 0.5, colour = "grey45", size = 11),
    axis.title        = element_text(size = 11),
    axis.text         = element_text(colour = "grey30"),
    panel.grid.major  = element_line(colour = "grey90"),
    panel.grid.minor  = element_blank(),
    plot.background   = element_rect(fill = "white", colour = NA),
    panel.background  = element_rect(fill = "white", colour = NA),
    legend.position   = "bottom",
    legend.key.width  = unit(1.4, "cm"),
    legend.text       = element_text(size = 10)
  )

# ── 5. Per-company plots ──────────────────────────────────
for (comp in companies) {
  
  sub <- df_monthly %>% filter(company_name == comp)
  
  mu   <- mean(sub$VWAP_return, na.rm = TRUE)
  sdev <- sd(sub$VWAP_return,   na.rm = TRUE)
  n    <- nrow(sub)
  
  sector_label <- sub %>%
    filter(!is.na(sector)) %>%
    pull(sector) %>%
    first()
  if (is.null(sector_label) || is.na(sector_label)) sector_label <- "Unknown"
  
  sub <- sub %>%
    mutate(direction = ifelse(VWAP_return >= 0, "Positive", "Negative"))
  
  hlines_df <- data.frame(
    yintercept = c(mu, mu + sdev, mu - sdev),
    Reference  = c("Mean", "+1 SD", "\u22121 SD")
  )
  
  p <- ggplot(sub, aes(x = month)) +
    
    # Zero line
    geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.4) +
    
    # Monthly bars coloured by sign
    geom_col(
      aes(y = VWAP_return, fill = direction),
      width = 25,   # ~25 days wide in date units
      alpha = 0.80
    ) +
    
    # Reference lines (mean, ±1 SD)
    geom_hline(
      data      = hlines_df,
      aes(yintercept = yintercept,
          colour     = Reference,
          linetype   = Reference),
      linewidth = 0.85
    ) +
    
    scale_fill_manual(
      name   = NULL,
      values = c("Positive" = "#2EC4B6", "Negative" = "#E84855")
    ) +
    
    scale_colour_manual(
      name   = NULL,
      values = c(
        "Mean"    = "#F4A261",
        "+1 SD"   = "#6A0572",
        "\u22121 SD" = "#6A0572"
      )
    ) +
    
    scale_linetype_manual(
      name   = NULL,
      values = c(
        "Mean"    = "dashed",
        "+1 SD"   = "dotted",
        "\u22121 SD" = "dotted"
      )
    ) +
    
    guides(
      fill     = guide_legend(override.aes = list(alpha = 0.85)),
      colour   = guide_legend(override.aes = list(linewidth = 1.1)),
      linetype = guide_legend()
    ) +
    
    # Stats annotation box
    annotate(
      "label",
      x      = min(sub$month),
      y      = Inf,
      label  = sprintf(
        "n (months) = %d\nMean         = %.4f\nSD             = %.4f",
        n, mu, sdev
      ),
      hjust  = -0.05,
      vjust  = 1.15,
      size   = 3.2,
      fill   = "white",
      colour = "grey20",
      family = "mono"
    ) +
    
    scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y",
      expand      = expansion(mult = c(0.01, 0.01))
    ) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    
    labs(
      title    = comp,
      subtitle = sprintf("Sector: %s  |  VWAP Monthly Returns (sum of daily)", sector_label),
      x        = NULL,
      y        =  "Return"
    ) +
    theme_ts
  
  safe_name <- gsub("[^A-Za-z0-9_]", "_", comp)
  safe_name <- gsub("_+", "_", safe_name)
  safe_name <- trimws(safe_name, which = "both")
  
  filename <- file.path(output_dir, sprintf("VWAP_Return_Monthly_%s.png", safe_name))
  
  ggsave(
    filename = filename,
    plot     = p,
    width    = 11,
    height   = 5,
    dpi      = 180,
    bg       = "white"
  )
  
  cat(sprintf("  ✔  Saved: %s\n", basename(filename)))
}

cat(sprintf("\nAll plots saved to: %s\n", output_dir))


# ============================================================
#  Volume Distribution Plots — One per Company
# ============================================================

# ── 2. Load data ──────────────────────────────────────────
df <- bdd_final_clean %>%
  filter(!is.na(abnormal_vol), !is.na(company_name), company_name != "NA",
         as.Date(date) >= as.Date("2017-01-01")) %>%
  mutate(abnormal_vol = as.numeric(abnormal_vol))

companies <- sort(unique(df$company_name))
cat(sprintf("Companies found: %d\n", length(companies)))

# ── 3. Output directory ───────────────────────────────────
output_dir <- "plots/volume_plots"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── 4. Custom theme ───────────────────────────────────────
theme_vol <- theme_minimal(base_size = 13) +
  theme(
    plot.title        = element_text(face = "bold", size = 15, hjust = 0.5,
                                     margin = margin(b = 6)),
    plot.subtitle     = element_text(hjust = 0.5, colour = "grey45", size = 11),
    axis.title        = element_text(size = 11),
    axis.text         = element_text(colour = "grey30"),
    panel.grid.major  = element_line(colour = "grey90"),
    panel.grid.minor  = element_blank(),
    plot.background   = element_rect(fill = "white", colour = NA),
    panel.background  = element_rect(fill = "white", colour = NA),
    legend.position   = "bottom",
    legend.key.width  = unit(1.8, "cm"),
    legend.text       = element_text(size = 10)
  )

# ── 5. Per-company plots ──────────────────────────────────
for (comp in companies) {
  
  sub <- df %>% filter(company_name == comp)
  
  mu   <- mean(sub$abnormal_vol,   na.rm = TRUE)
  med  <- median(sub$abnormal_vol, na.rm = TRUE)
  sdev <- sd(sub$abnormal_vol,     na.rm = TRUE)
  skew <- mean(((sub$abnormal_vol - mu) / sdev)^3, na.rm = TRUE)
  kurt <- mean(((sub$abnormal_vol - mu) / sdev)^4, na.rm = TRUE)
  n    <- nrow(sub)
  
  sector_label <- sub %>%
    filter(!is.na(sector)) %>%
    pull(sector) %>%
    first()
  if (is.null(sector_label) || is.na(sector_label)) sector_label <- "Unknown"
  
  # Data frame for vlines — enables legend mapping
  vlines_df <- data.frame(
    xintercept = c(mu, med),
    Indicator  = c("Mean", "Median")
  )
  
  p <- ggplot(sub, aes(x = abnormal_vol)) +
    
    # Histogram (fixed colour, not in legend)
    geom_histogram(
      aes(y = after_stat(density)),
      bins      = 60,
      fill      = "#2E86AB",
      colour    = "white",
      alpha     = 0.85,
      linewidth = 0.2
    ) +
    
    # Normal distribution overlay for comparison
    stat_function(
      aes(colour = "Normal fit", linetype = "Normal fit"),
      fun       = dnorm,
      args      = list(mean = mu, sd = sdev),
      linewidth = 0.9
    ) +
    
    # KDE curve — mapped so it enters the legend
    geom_density(
      aes(colour = "KDE Density", linetype = "KDE Density"),
      linewidth = 1.1
    ) +
    
    # Mean & Median lines — mapped via vlines_df
    geom_vline(
      data      = vlines_df,
      aes(xintercept = xintercept,
          colour     = Indicator,
          linetype   = Indicator),
      linewidth = 0.9
    ) +
    
    scale_colour_manual(
      name   = NULL,
      values = c(
        "KDE Density" = "#E84855",
        "Normal fit"  = "#6A0572",
        "Mean"        = "#F4A261",
        "Median"      = "#2EC4B6"
      )
    ) +
    
    scale_linetype_manual(
      name   = NULL,
      values = c(
        "KDE Density" = "solid",
        "Normal fit"  = "dotted",
        "Mean"        = "dashed",
        "Median"      = "dotdash"
      )
    ) +
    
    # Merge colour + linetype into one legend
    guides(
      colour   = guide_legend(override.aes = list(linewidth = 1.2)),
      linetype = guide_legend()
    ) +
    
    # Stats annotation box
    annotate(
      "label",
      x      = Inf,
      y      = Inf,
      label  = sprintf(
        "n        = %d\nMean   = %s\nMedian = %s\nSD       = %s\nSkew   = %.3f\nKurt    = %.3f",
        n,
        format(round(mu),   big.mark = ",", scientific = FALSE),
        format(round(med),  big.mark = ",", scientific = FALSE),
        format(round(sdev), big.mark = ",", scientific = FALSE),
        skew, kurt
      ),
      hjust  = 1.05,
      vjust  = 1.15,
      size   = 3.2,
      fill   = "white",
      colour = "grey20",
      family = "mono"
    ) +
    
    scale_x_continuous(labels = scales::label_number(scale_cut = cut_short_scale())) +
    scale_y_continuous(labels = scales::label_number(accuracy = 0.1)) +
    
    labs(
      title    = comp,
      subtitle = sprintf("Sector: %s  |  Daily Trading Volume", sector_label),
      x        = "Volume (number of shares)",
      y        = "Density"
    ) +
    theme_vol
  
  safe_name <- gsub("[^A-Za-z0-9_]", "_", comp)
  safe_name <- gsub("_+", "_", safe_name)
  safe_name <- trimws(safe_name, which = "both")
  
  filename <- file.path(output_dir, sprintf("Volume_%s.png", safe_name))
  
  ggsave(
    filename = filename,
    plot     = p,
    width    = 9,
    height   = 5.5,
    dpi      = 180,
    bg       = "white"
  )
  
  cat(sprintf("  ✔  Saved: %s\n", basename(filename)))
}

cat(sprintf("\nAll plots saved to: %s\n", output_dir))


# ============================================================
#  Volume — Monthly Time Series Plots — One per Company
# ============================================================

# ── 2. Load data ──────────────────────────────────────────
df <- bdd_final_clean %>%
  filter(!is.na(abnormal_vol), !is.na(company_name), company_name != "NA",
         as.Date(date) >= as.Date("2017-01-01")) %>%
  mutate(
    abnormal_vol = as.numeric(abnormal_vol),
    date   = as.Date(date)
  )

# ── Aggregate to monthly (sum of daily volumes) ───────────
df_monthly <- df %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(company_name, sector, month) %>%
  summarise(
    abnormal_vol = sum(abnormal_vol, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(company_name, month)

companies <- sort(unique(df_monthly$company_name))
cat(sprintf("Companies found: %d\n", length(companies)))

# ── 3. Output directory ───────────────────────────────────
output_dir <- "plots/volume_timeseries_monthly"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── 4. Custom theme ───────────────────────────────────────
theme_ts <- theme_minimal(base_size = 13) +
  theme(
    plot.title        = element_text(face = "bold", size = 15, hjust = 0.5,
                                     margin = margin(b = 4)),
    plot.subtitle     = element_text(hjust = 0.5, colour = "grey45", size = 11),
    axis.title        = element_text(size = 11),
    axis.text         = element_text(colour = "grey30"),
    panel.grid.major  = element_line(colour = "grey90"),
    panel.grid.minor  = element_blank(),
    plot.background   = element_rect(fill = "white", colour = NA),
    panel.background  = element_rect(fill = "white", colour = NA),
    legend.position   = "bottom",
    legend.key.width  = unit(1.4, "cm"),
    legend.text       = element_text(size = 10)
  )

# ── 5. Per-company plots ──────────────────────────────────
for (comp in companies) {
  
  sub <- df_monthly %>% filter(company_name == comp)
  
  mu   <- mean(sub$abnormal_vol, na.rm = TRUE)
  sdev <- sd(sub$abnormal_vol,   na.rm = TRUE)
  n    <- nrow(sub)
  
  sector_label <- sub %>%
    filter(!is.na(sector)) %>%
    pull(sector) %>%
    first()
  if (is.null(sector_label) || is.na(sector_label)) sector_label <- "Unknown"
  
  # Colour bars above/below mean
  sub <- sub %>%
    mutate(direction = ifelse(abnormal_vol >= mu, "Above mean", "Below mean"))
  
  hlines_df <- data.frame(
    yintercept = c(mu, mu + sdev, mu - sdev),
    Reference  = c("Mean", "+1 SD", "\u22121 SD")
  )
  
  p <- ggplot(sub, aes(x = month)) +
    
    # Monthly bars coloured by above/below mean
    geom_col(
      aes(y = abnormal_vol, fill = direction),
      width = 25,
      alpha = 0.80
    ) +
    
    # Reference lines (mean, ±1 SD)
    geom_hline(
      data      = hlines_df,
      aes(yintercept = yintercept,
          colour     = Reference,
          linetype   = Reference),
      linewidth = 0.85
    ) +
    
    scale_fill_manual(
      name   = NULL,
      values = c("Above mean" = "#2EC4B6", "Below mean" = "#E84855")
    ) +
    
    scale_colour_manual(
      name   = NULL,
      values = c(
        "Mean"         = "#F4A261",
        "+1 SD"        = "#6A0572",
        "\u22121 SD"   = "#6A0572"
      )
    ) +
    
    scale_linetype_manual(
      name   = NULL,
      values = c(
        "Mean"         = "dashed",
        "+1 SD"        = "dotted",
        "\u22121 SD"   = "dotted"
      )
    ) +
    
    guides(
      fill     = guide_legend(override.aes = list(alpha = 0.85)),
      colour   = guide_legend(override.aes = list(linewidth = 1.1)),
      linetype = guide_legend()
    ) +
    
    # Stats annotation box
    annotate(
      "label",
      x      = min(sub$month),
      y      = Inf,
      label  = sprintf(
        "n (months) = %d\nMean         = %s\nSD             = %s",
        n,
        format(round(mu,3),   big.mark = ",", scientific = FALSE),
        format(round(sdev,3), big.mark = ",", scientific = FALSE)
      ),
      hjust  = -0.05,
      vjust  = 1.15,
      size   = 3.2,
      fill   = "white",
      colour = "grey20",
      family = "mono"
    ) +
    
    scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y",
      expand      = expansion(mult = c(0.01, 0.01))
    ) +
    scale_y_continuous(labels = scales::label_number(scale_cut = cut_short_scale())) +
    
    labs(
      title    = comp,
      subtitle = sprintf("Sector: %s  |  Monthly Trading Volume (sum of daily)", sector_label),
      x        = NULL,
      y        = "Volume (shares)"
    ) +
    theme_ts
  
  safe_name <- gsub("[^A-Za-z0-9_]", "_", comp)
  safe_name <- gsub("_+", "_", safe_name)
  safe_name <- trimws(safe_name, which = "both")
  
  filename <- file.path(output_dir, sprintf("Volume_Monthly_%s.png", safe_name))
  
  ggsave(
    filename = filename,
    plot     = p,
    width    = 11,
    height   = 5,
    dpi      = 180,
    bg       = "white"
  )
  
  cat(sprintf("  ✔  Saved: %s\n", basename(filename)))
}

cat(sprintf("\nAll plots saved to: %s\n", output_dir))


# ============================================================
#  Realized Volatility Distribution Plots — One per Company
# ============================================================

# ── 2. Load data ──────────────────────────────────────────
df <- bdd_final_clean %>%
  filter(!is.na(realized_vol), !is.na(company_name), company_name != "NA",
         as.Date(date) >= as.Date("2017-01-01")) %>%
  mutate(realized_vol = as.numeric(realized_vol))

companies <- sort(unique(df$company_name))
cat(sprintf("Companies found: %d\n", length(companies)))

# ── 3. Output directory ───────────────────────────────────
output_dir <- "plots/realized_vol_plots"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── 4. Custom theme ───────────────────────────────────────
theme_vol <- theme_minimal(base_size = 13) +
  theme(
    plot.title        = element_text(face = "bold", size = 15, hjust = 0.5,
                                     margin = margin(b = 6)),
    plot.subtitle     = element_text(hjust = 0.5, colour = "grey45", size = 11),
    axis.title        = element_text(size = 11),
    axis.text         = element_text(colour = "grey30"),
    panel.grid.major  = element_line(colour = "grey90"),
    panel.grid.minor  = element_blank(),
    plot.background   = element_rect(fill = "white", colour = NA),
    panel.background  = element_rect(fill = "white", colour = NA),
    legend.position   = "bottom",
    legend.key.width  = unit(1.8, "cm"),
    legend.text       = element_text(size = 10)
  )

# ── 5. Per-company plots ──────────────────────────────────
for (comp in companies) {
  
  sub <- df %>% filter(company_name == comp)
  
  mu   <- mean(sub$realized_vol,   na.rm = TRUE)
  med  <- median(sub$realized_vol, na.rm = TRUE)
  sdev <- sd(sub$realized_vol,     na.rm = TRUE)
  skew <- mean(((sub$realized_vol - mu) / sdev)^3, na.rm = TRUE)
  kurt <- mean(((sub$realized_vol - mu) / sdev)^4, na.rm = TRUE)
  n    <- nrow(sub)
  
  sector_label <- sub %>%
    filter(!is.na(sector)) %>%
    pull(sector) %>%
    first()
  if (is.null(sector_label) || is.na(sector_label)) sector_label <- "Unknown"
  
  vlines_df <- data.frame(
    xintercept = c(mu, med),
    Indicator  = c("Mean", "Median")
  )
  
  p <- ggplot(sub, aes(x = realized_vol)) +
    
    # Histogram
    geom_histogram(
      aes(y = after_stat(density)),
      bins      = 60,
      fill      = "#2E86AB",
      colour    = "white",
      alpha     = 0.85,
      linewidth = 0.2
    ) +
    
    # Normal distribution overlay
    stat_function(
      aes(colour = "Normal fit", linetype = "Normal fit"),
      fun       = dnorm,
      args      = list(mean = mu, sd = sdev),
      linewidth = 0.9
    ) +
    
    # KDE curve
    geom_density(
      aes(colour = "KDE Density", linetype = "KDE Density"),
      linewidth = 1.1
    ) +
    
    # Mean & Median vertical lines
    geom_vline(
      data      = vlines_df,
      aes(xintercept = xintercept,
          colour     = Indicator,
          linetype   = Indicator),
      linewidth = 0.9
    ) +
    
    scale_colour_manual(
      name   = NULL,
      values = c(
        "KDE Density" = "#E84855",
        "Normal fit"  = "#6A0572",
        "Mean"        = "#F4A261",
        "Median"      = "#2EC4B6"
      )
    ) +
    
    scale_linetype_manual(
      name   = NULL,
      values = c(
        "KDE Density" = "solid",
        "Normal fit"  = "dotted",
        "Mean"        = "dashed",
        "Median"      = "dotdash"
      )
    ) +
    
    guides(
      colour   = guide_legend(override.aes = list(linewidth = 1.2)),
      linetype = guide_legend()
    ) +
    
    annotate(
      "label",
      x      = Inf,
      y      = Inf,
      label  = sprintf(
        "n        = %d\nMean   = %.4f\nMedian = %.4f\nSD       = %.4f\nSkew   = %.3f\nKurt    = %.3f",
        n, mu, med, sdev, skew, kurt
      ),
      hjust  = 1.05,
      vjust  = 1.15,
      size   = 3.2,
      fill   = "white",
      colour = "grey20",
      family = "mono"
    ) +
    
    scale_x_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    scale_y_continuous(labels = scales::label_number(accuracy = 0.1)) +
    
    labs(
      title    = comp,
      subtitle = sprintf("Sector: %s  |  Realized Volatility", sector_label),
      x        = "Realized Volatility",
      y        = "Density"
    ) +
    theme_vol
  
  safe_name <- gsub("[^A-Za-z0-9_]", "_", comp)
  safe_name <- gsub("_+", "_", safe_name)
  safe_name <- trimws(safe_name, which = "both")
  
  filename <- file.path(output_dir, sprintf("RealizedVol_%s.png", safe_name))
  
  ggsave(
    filename = filename,
    plot     = p,
    width    = 9,
    height   = 5.5,
    dpi      = 180,
    bg       = "white"
  )
  
  cat(sprintf("  ✔  Saved: %s\n", basename(filename)))
}

cat(sprintf("\nAll plots saved to: %s\n", output_dir))

# ============================================================
#  Realized Volatility — Monthly Time Series — One per Company
# ============================================================

# ── 2. Load data ──────────────────────────────────────────
df <- bdd_final_clean %>%
  filter(!is.na(realized_vol), !is.na(company_name), company_name != "NA",
         as.Date(date) >= as.Date("2017-01-01")) %>%
  mutate(
    realized_vol = as.numeric(realized_vol),
    date         = as.Date(date)
  )

# ── Aggregate to monthly (mean of daily realized vol) ─────
df_monthly <- df %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(company_name, sector, month) %>%
  summarise(
    realized_vol = mean(realized_vol, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(company_name, month)

companies <- sort(unique(df_monthly$company_name))
cat(sprintf("Companies found: %d\n", length(companies)))

# ── 3. Output directory ───────────────────────────────────
output_dir <- "plots/realized_vol_timeseries_monthly"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── 4. Custom theme ───────────────────────────────────────
theme_ts <- theme_minimal(base_size = 13) +
  theme(
    plot.title        = element_text(face = "bold", size = 15, hjust = 0.5,
                                     margin = margin(b = 4)),
    plot.subtitle     = element_text(hjust = 0.5, colour = "grey45", size = 11),
    axis.title        = element_text(size = 11),
    axis.text         = element_text(colour = "grey30"),
    panel.grid.major  = element_line(colour = "grey90"),
    panel.grid.minor  = element_blank(),
    plot.background   = element_rect(fill = "white", colour = NA),
    panel.background  = element_rect(fill = "white", colour = NA),
    legend.position   = "bottom",
    legend.key.width  = unit(1.4, "cm"),
    legend.text       = element_text(size = 10)
  )

# ── 5. Per-company plots ──────────────────────────────────
for (comp in companies) {
  
  sub <- df_monthly %>% filter(company_name == comp)
  
  mu   <- mean(sub$realized_vol, na.rm = TRUE)
  sdev <- sd(sub$realized_vol,   na.rm = TRUE)
  n    <- nrow(sub)
  
  sector_label <- sub %>%
    filter(!is.na(sector)) %>%
    pull(sector) %>%
    first()
  if (is.null(sector_label) || is.na(sector_label)) sector_label <- "Unknown"
  
  # Colour bars above/below mean
  sub <- sub %>%
    mutate(direction = ifelse(realized_vol >= mu, "Above mean", "Below mean"))
  
  hlines_df <- data.frame(
    yintercept = c(mu, mu + sdev, mu - sdev),
    Reference  = c("Mean", "+1 SD", "\u22121 SD")
  )
  
  p <- ggplot(sub, aes(x = month)) +
    
    # Monthly bars coloured by above/below mean
    geom_col(
      aes(y = realized_vol, fill = direction),
      width = 25,
      alpha = 0.80
    ) +
    
    # Reference lines (mean, ±1 SD)
    geom_hline(
      data      = hlines_df,
      aes(yintercept = yintercept,
          colour     = Reference,
          linetype   = Reference),
      linewidth = 0.85
    ) +
    
    scale_fill_manual(
      name   = NULL,
      values = c("Above mean" = "#E84855", "Below mean" = "#2EC4B6")
    ) +
    
    scale_colour_manual(
      name   = NULL,
      values = c(
        "Mean"       = "#F4A261",
        "+1 SD"      = "#6A0572",
        "\u22121 SD" = "#6A0572"
      )
    ) +
    
    scale_linetype_manual(
      name   = NULL,
      values = c(
        "Mean"       = "dashed",
        "+1 SD"      = "dotted",
        "\u22121 SD" = "dotted"
      )
    ) +
    
    guides(
      fill     = guide_legend(override.aes = list(alpha = 0.85)),
      colour   = guide_legend(override.aes = list(linewidth = 1.1)),
      linetype = guide_legend()
    ) +
    
    # Stats annotation box
    annotate(
      "label",
      x      = min(sub$month),
      y      = Inf,
      label  = sprintf(
        "n (months) = %d\nMean         = %.4f\nSD             = %.4f",
        n, mu, sdev
      ),
      hjust  = -0.05,
      vjust  = 1.15,
      size   = 3.2,
      fill   = "white",
      colour = "grey20",
      family = "mono"
    ) +
    
    scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y",
      expand      = expansion(mult = c(0.01, 0.01))
    ) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    
    labs(
      title    = comp,
      subtitle = sprintf("Sector: %s  |  Monthly Realized Volatility (mean of daily)", sector_label),
      x        = NULL,
      y        = "Realized Volatility"
    ) +
    theme_ts
  
  safe_name <- gsub("[^A-Za-z0-9_]", "_", comp)
  safe_name <- gsub("_+", "_", safe_name)
  safe_name <- trimws(safe_name, which = "both")
  
  filename <- file.path(output_dir, sprintf("RealizedVol_Monthly_%s.png", safe_name))
  
  ggsave(
    filename = filename,
    plot     = p,
    width    = 11,
    height   = 5,
    dpi      = 180,
    bg       = "white"
  )
  
  cat(sprintf("  ✔  Saved: %s\n", basename(filename)))
}

cat(sprintf("\nAll plots saved to: %s\n", output_dir))

########## END

