###########################################################################
#                                                                         
#  FILE 2 — EVENT STUDY REGRESSIONS & ENDOGENEITY CHECKS                 
#                                                                         
#  PREREQUISITES: Run 01_CPU_construction.R first (or have the file       
#  data/CPU_all_indices.csv and data/bdd_final.csv ready).                
#                                                                         
#  What this file does:                                                   
#    1. Loads firm-level stock data & computes realized volatility        
#    2. Loads CPU index and detects spikes (both methods)                 
#    3. Builds event panels (firm x spike x event window)                 
#    4. Runs bivariate regressions (no controls)                          
#    5. Adds VIX as a control                                             
#    6. Tests for endogeneity (Granger, VAR, cross-correlation)           
#    7. VIX(t-3)                                                          
#    8. Produces all regression plots and summary tables                  
#                                                                         
#                                                                         
###########################################################################

# =========================================================================
# SETUP
# =========================================================================

library(tidyverse)
library(lubridate)
library(zoo)
library(fixest)        # fast fixed-effects regressions (feols)
library(lmtest)        # Granger causality tests
library(vars)          # VAR models

rm(list = ls())
dir.create("plots", showWarnings = FALSE)

# Event window: 2 months before to 2 months after the spike
window <- -2:2


# =========================================================================
# SECTION 1: LOAD DATA
# =========================================================================

# Firm-level daily stock data (VWAP, VIX, etc.)
df  <- read_csv("data/bdd_final.csv")

# CPU index (computed in File 1)
cpu <- read_csv("data/CPU_all_indices.csv")


# =========================================================================
# SECTION 2: COMPUTE REALIZED VOLATILITY
# =========================================================================
# Realized volatility = how much a stock's price actually moved in a month.
#   1. Daily returns = (price today - price yesterday) / price yesterday
#   2. Monthly realized vol = SD of daily returns x sqrt(21)
#      (21 = average trading days per month)

real_vol <- df %>%
  arrange(company_name, date) %>%
  group_by(company_name) %>%
  mutate(daily_return = (VWAP - lag(VWAP)) / lag(VWAP)) %>%
  ungroup() %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(company_name, month) %>%
  summarise(
    realized_vol = sd(daily_return, na.rm = TRUE) * sqrt(21),
    .groups = "drop"
  )


# =========================================================================
# SECTION 3: PREPARE CPU INDEX & DETECT SPIKES
# =========================================================================
# We use CPU_2 (the 2-lag variant = 3-month average window).

CPU_index <- cpu %>%
  filter(date >= "2016-11-01") %>%
  arrange(date) %>%
  rename(CPU = CPU_2) %>%
  mutate(
    roll_mean = rollmean(CPU, k = 12, fill = NA, align = "right"),
    roll_sd   = rollapply(CPU, width = 12, FUN = sd, fill = NA, align = "right"),
    spike_raw = CPU > roll_mean + 1.5 * roll_sd
  ) %>%
  filter(date >= "2017-01-01")

# --- Method 1: Rolling threshold ---
spike_months <- CPU_index %>%
  filter(spike_raw) %>%
  arrange(date) %>%
  mutate(
    gap         = as.numeric(difftime(date, lag(date), units = "days")) / 30,
    gap         = ifelse(is.na(gap), 99, gap),
    new_cluster = gap > 4,
    cluster_id  = cumsum(new_cluster)
  )

spike_episodes <- spike_months %>%
  group_by(cluster_id) %>%
  slice_max(CPU, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(date)

keep <- numeric(); last_kept <- as.Date("1900-01-01")
for (j in seq_len(nrow(spike_episodes))) {
  ms <- as.numeric(difftime(spike_episodes$date[j], last_kept, units = "days")) / 30
  if (ms >= 5) { keep <- c(keep, j); last_kept <- spike_episodes$date[j] }
}
spike_dates_rolling <- spike_episodes$date[keep]

cat("Rolling threshold spikes:", length(spike_dates_rolling), "\n")
print(spike_dates_rolling)

# --- Method 2: Local maxima (preferred) ---
detect_spikes_localmax <- function(cpu_series, min_gap = 5, threshold_sd = 1.5) {
  dates  <- cpu_series$date
  values <- cpu_series$CPU
  n      <- length(dates)
  
  local_max <- rep(FALSE, n)
  for (k in 2:(n - 1)) {
    if (is.na(values[k]) | is.na(values[k - 1]) | is.na(values[k + 1])) next
    if (values[k] > values[k - 1] & values[k] > values[k + 1]) local_max[k] <- TRUE
  }
  
  threshold     <- mean(values, na.rm = TRUE) + threshold_sd * sd(values, na.rm = TRUE)
  candidate_idx <- which(local_max & values > threshold)
  if (length(candidate_idx) == 0) return(as.Date(character(0)))
  
  kept <- c(); kept_dates <- as.Date(character(0))
  for (idx in candidate_idx) {
    candidate_date <- dates[idx]
    if (length(kept_dates) == 0) {
      kept <- c(kept, idx); kept_dates <- c(kept_dates, candidate_date); next
    }
    gaps <- abs(as.numeric(difftime(candidate_date, kept_dates, units = "days"))) / 30
    if (all(gaps >= min_gap)) {
      kept <- c(kept, idx); kept_dates <- c(kept_dates, candidate_date)
    } else {
      conflict_i <- which(gaps < min_gap)
      if (values[idx] > values[kept[conflict_i]] * 1.20) {
        kept[conflict_i] <- idx; kept_dates[conflict_i] <- candidate_date
      }
    }
  }
  sort(dates[kept])
}

cpu_for_detection    <- CPU_index %>% filter(!is.na(CPU)) %>% dplyr::select(date, CPU)
spike_dates_localmax <- detect_spikes_localmax(cpu_for_detection)

cat("Local maxima spikes:", length(spike_dates_localmax), "\n")
print(spike_dates_localmax)


# =========================================================================
# SECTION 4: BUILD EVENT PANELS
# =========================================================================
# Each row = one company x one spike x one relative time period
# rel_time = -2 is the reference (baseline) period.

# --- Panel for Rolling Threshold ---
event_panel <- expand_grid(
  spike_date   = spike_dates_rolling,
  company_name = unique(real_vol$company_name),
  rel_time     = window
) %>%
  mutate(month = spike_date %m+% months(rel_time)) %>%
  left_join(real_vol,                                      by = c("company_name", "month")) %>%
  left_join(CPU_index %>% dplyr::select(date, CPU),        by = c("month" = "date")) %>%
  mutate(rel_time = factor(rel_time, levels = window),
         rel_time = relevel(rel_time, ref = "-2"))

# --- Panel for Local Maxima (preferred) ---
event_panel_lm <- expand_grid(
  spike_date   = spike_dates_localmax,
  company_name = unique(real_vol$company_name),
  rel_time     = window
) %>%
  mutate(month = spike_date %m+% months(rel_time)) %>%
  left_join(real_vol,                                      by = c("company_name", "month")) %>%
  left_join(CPU_index %>% dplyr::select(date, CPU),        by = c("month" = "date")) %>%
  mutate(rel_time = factor(rel_time, levels = window),
         rel_time = relevel(rel_time, ref = "-2"))


# =========================================================================
# SECTION 5: BIVARIATE REGRESSIONS (no controls)
# =========================================================================
# MODEL: realized_vol = b0 + b1*rel_time + alpha_i + epsilon
#   - rel_time dummies: -1, 0, +1, +2 (ref = -2)
#   - alpha_i: company fixed effects
#   - Clustered standard errors by company

reg <- feols(
  realized_vol ~ rel_time | company_name,
  data = event_panel, cluster = ~company_name
)

reg_lm <- feols(
  realized_vol ~ rel_time | company_name,
  data = event_panel_lm, cluster = ~company_name
)

cat("\n=== BIVARIATE: Rolling threshold ===\n")
summary(reg)
cat("\n=== BIVARIATE: Local maxima (preferred) ===\n")
summary(reg_lm)


# =========================================================================
# SECTION 6: PLOT — Bivariate Results (both methods side by side)
# =========================================================================

extract_coefs <- function(reg_model, label) {
  broom::tidy(reg_model, conf.int = TRUE) %>%
    filter(str_detect(term, "^rel_time-?[0-9]+$")) %>%
    mutate(rel_time = as.integer(str_extract(term, "-?[0-9]+"))) %>%
    bind_rows(tibble(term = "rel_time-2", estimate = 0,
                     conf.low = 0, conf.high = 0, rel_time = -2L)) %>%
    arrange(rel_time) %>%
    mutate(spec = label)
}

coef_comparison <- bind_rows(
  extract_coefs(reg,    "Rolling threshold"),
  extract_coefs(reg_lm, "Local maxima")
) %>%
  mutate(spec = factor(spec, levels = c("Rolling threshold", "Local maxima")))

p_comparison <- ggplot(coef_comparison, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.35, linetype = "dashed") +
  geom_vline(xintercept = 0, color = "grey40", linewidth = 0.4,  linetype = "dashed") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.15, color = "#2C3E50", linewidth = 0.5) +
  geom_point(size = 2.5, shape = 19, color = "#2C3E50") +
  facet_wrap(~ spec, ncol = 2,
             labeller = as_labeller(c(
               "Rolling threshold" = "Panel A - Rolling threshold",
               "Local maxima"      = "Panel B - Local maxima (preferred)"))) +
  scale_x_continuous(breaks = window) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.001)) +
  labs(x = "Months relative to CPU spike",
       y = "Realized Volatility (coefficient estimate)",
       subtitle = "Baseline: no controls, company fixed effects only") +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 9.5, hjust = 0, margin = margin(b = 4)),
    strip.background   = element_blank(),
    axis.title.x       = element_text(size = 9.5, margin = margin(t = 8)),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8)),
    axis.text          = element_text(size = 8, color = "grey20"),
    axis.ticks         = element_line(color = "grey70", linewidth = 0.3),
    axis.ticks.length  = unit(2.5, "pt"),
    axis.line.x        = element_line(color = "grey40", linewidth = 0.35),
    axis.line.y        = element_blank(),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.35),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.background   = element_rect(fill = "grey98", color = NA),
    panel.spacing      = unit(1.2, "lines"),
    legend.position    = "none"
  )

ggsave("plots/event_study_realvol_comparison.png", p_comparison,
       width = 8, height = 5, dpi = 300, bg = "white")
p_comparison

# Summary table (both methods)
etable(reg, reg_lm,
       keep    = "rel_time",
       headers = c("Rolling threshold", "Local maxima"),
       title   = "Bivariate event study: Realized volatility around CPU spikes")


# =========================================================================
# SECTION 7: ADD VIX CONTROL
# =========================================================================
# VIX = CBOE Volatility Index, a market-wide measure of expected volatility.
# We average daily VIX into a monthly series and merge into event panels.

vix_monthly <- df %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month) %>%
  summarise(vix_ctrl = mean(vix, na.rm = TRUE), .groups = "drop")

# Merge VIX into both event panels
event_panel <- event_panel %>%
  dplyr::select(-any_of(c("vix", "vix.x", "vix.y"))) %>%
  left_join(vix_monthly, by = "month") %>%
  rename(vix = vix_ctrl)

event_panel_lm <- event_panel_lm %>%
  dplyr::select(-any_of(c("vix", "vix.x", "vix.y"))) %>%
  left_join(vix_monthly, by = "month") %>%
  rename(vix = vix_ctrl)

cat("VIX NAs in event_panel:", sum(is.na(event_panel$vix)), "\n")


# =========================================================================
# SECTION 8: REGRESSIONS WITH VIX CONTROL
# =========================================================================
# MODEL: realized_vol = b*rel_time + g*VIX + alpha_i + epsilon
#
# Adding VIX should NOT eliminate the CPU effect if CPU has an
# independent impact. But if VIX and CPU share contemporaneous
# variation, VIX might absorb the CPU effect.

reg_vix <- feols(
  realized_vol ~ rel_time + vix | company_name,
  data = event_panel, cluster = ~company_name
)

reg_lm_vix <- feols(
  realized_vol ~ rel_time + vix | company_name,
  data = event_panel_lm, cluster = ~company_name
)

cat("\n=== VIX CONTROL: Rolling threshold ===\n")
summary(reg_vix)
cat("\n=== VIX CONTROL: Local maxima ===\n")
summary(reg_lm_vix)


# =========================================================================
# SECTION 9: PLOT — Baseline vs VIX (both methods)
# =========================================================================

# Rolling threshold: baseline vs VIX
coef_rolling_specs <- bind_rows(
  extract_coefs(reg,     "Baseline"),
  extract_coefs(reg_vix, "VIX control")
) %>%
  mutate(spec = factor(spec, levels = c("Baseline", "VIX control")))

p_rolling_specs <- ggplot(coef_rolling_specs, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.35, linetype = "dashed") +
  geom_vline(xintercept = 0, color = "grey40", linewidth = 0.40, linetype = "dashed") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.15, color = "#2C3E50", linewidth = 0.5) +
  geom_point(size = 2.5, shape = 19, color = "#2C3E50") +
  facet_wrap(~ spec, ncol = 2) +
  scale_x_continuous(breaks = window) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.001)) +
  labs(x = "Months relative to CPU spike",
       y = "Realized Volatility (coefficient estimate)",
       subtitle = "Rolling threshold — Baseline vs VIX control") +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 9.5, hjust = 0, margin = margin(b = 4)),
    strip.background   = element_blank(),
    axis.title.x       = element_text(size = 9.5, margin = margin(t = 8)),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8)),
    axis.text          = element_text(size = 8, color = "grey20"),
    axis.ticks         = element_line(color = "grey70", linewidth = 0.3),
    axis.ticks.length  = unit(2.5, "pt"),
    axis.line.x        = element_line(color = "grey40", linewidth = 0.35),
    axis.line.y        = element_blank(),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.35),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.background   = element_rect(fill = "grey98", color = NA),
    panel.spacing      = unit(1.2, "lines"),
    legend.position    = "none"
  )

ggsave("plots/event_study_rolling_baseline_vs_vix.png", p_rolling_specs,
       width = 8, height = 5, dpi = 300, bg = "white")
p_rolling_specs

# Local maxima: baseline vs VIX
coef_lm_specs <- bind_rows(
  extract_coefs(reg_lm,     "Baseline"),
  extract_coefs(reg_lm_vix, "VIX control")
) %>%
  mutate(spec = factor(spec, levels = c("Baseline", "VIX control")))

p_lm_specs <- ggplot(coef_lm_specs, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.35, linetype = "dashed") +
  geom_vline(xintercept = 0, color = "grey40", linewidth = 0.40, linetype = "dashed") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.15, color = "#2C3E50", linewidth = 0.5) +
  geom_point(size = 2.5, shape = 19, color = "#2C3E50") +
  facet_wrap(~ spec, ncol = 2) +
  scale_x_continuous(breaks = window) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.001)) +
  labs(x = "Months relative to CPU spike",
       y = "Realized Volatility (coefficient estimate)",
       subtitle = "Local maxima (preferred) — Baseline vs VIX control") +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 9.5, hjust = 0, margin = margin(b = 4)),
    strip.background   = element_blank(),
    axis.title.x       = element_text(size = 9.5, margin = margin(t = 8)),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8)),
    axis.text          = element_text(size = 8, color = "grey20"),
    axis.ticks         = element_line(color = "grey70", linewidth = 0.3),
    axis.ticks.length  = unit(2.5, "pt"),
    axis.line.x        = element_line(color = "grey40", linewidth = 0.35),
    axis.line.y        = element_blank(),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.35),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.background   = element_rect(fill = "grey98", color = NA),
    panel.spacing      = unit(1.2, "lines"),
    legend.position    = "none"
  )

ggsave("plots/event_study_localmax_baseline_vs_vix.png", p_lm_specs,
       width = 8, height = 5, dpi = 300, bg = "white")
p_lm_specs
# =========================================================================
# =========================================================================
#
#  ENDOGENEITY ANALYSIS — IS VIX A "BAD CONTROL"?
#
# =========================================================================
# =========================================================================
#
#   1. Granger causality: does CPU predict future VIX?
#   2. VAR model: joint dynamics test
#   3. Cross-correlation plot: visual lead-lag diagnostic
#   4. VIX(t-3): first truly predetermined lag given CPU(t:t-2) window

# =========================================================================
# SECTION 10: BUILD MONTHLY CPU-VIX TIME SERIES
# =========================================================================

cpu_vix_ts <- CPU_index %>%
  dplyr::select(date, CPU) %>%
  left_join(vix_monthly, by = c("date" = "month")) %>%
  filter(!is.na(CPU) & !is.na(vix_ctrl)) %>%
  arrange(date)

# =========================================================================
# SECTION 11: GRANGER CAUSALITY TESTS
# =========================================================================

gc_cpu_to_vix <- grangertest(vix_ctrl ~ CPU,      order = 3, data = cpu_vix_ts)
gc_vix_to_cpu <- grangertest(CPU      ~ vix_ctrl, order = 3, data = cpu_vix_ts)

cat("\n=== Granger causality: CPU -> VIX (H0: CPU does NOT cause VIX) ===\n")
print(gc_cpu_to_vix)
cat("\n=== Granger causality: VIX -> CPU (H0: VIX does NOT cause CPU) ===\n")
print(gc_vix_to_cpu)

# =========================================================================
# SECTION 12: VAR-BASED GRANGER CAUSALITY
# =========================================================================

var_data <- cpu_vix_ts %>%
  dplyr::select(CPU, vix_ctrl) %>%
  as.data.frame()

lag_select <- VARselect(var_data, lag.max = 6, type = "const")
opt_lag    <- as.integer(lag_select$selection["AIC(n)"])
cat("\nOptimal VAR lag (AIC):", opt_lag, "\n")

var_model <- vars::VAR(var_data, p = opt_lag, type = "const")

cat("\n=== VAR Granger causality: does CPU cause VIX? ===\n")
print(causality(var_model, cause = "CPU"))

# =========================================================================
# SECTION 13: CROSS-CORRELATION PLOT
# =========================================================================

max_lag  <- 6
ccf_vals <- ccf(cpu_vix_ts$CPU, cpu_vix_ts$vix_ctrl,
                lag.max = max_lag, plot = FALSE)

ccf_df <- tibble(
  lag = ccf_vals$lag[, 1, 1],
  acf = ccf_vals$acf[, 1, 1]
)

p_ccf <- ggplot(ccf_df, aes(x = lag, y = acf)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.35) +
  geom_hline(yintercept = c(-1, 1) * 1.96 / sqrt(nrow(cpu_vix_ts)),
             color = "#c0392b", linetype = "dashed", linewidth = 0.4) +
  geom_segment(aes(xend = lag, yend = 0), color = "#2C3E50", linewidth = 0.8) +
  geom_point(size = 2.5, shape = 19, color = "#2C3E50") +
  annotate("text", x = -max_lag * 0.85, y = max(ccf_df$acf) * 0.95,
           label = "<- VIX leads CPU", size = 3, color = "grey40", hjust = 0) +
  annotate("text", x = max_lag * 0.05, y = max(ccf_df$acf) * 0.95,
           label = "CPU leads VIX ->", size = 3, color = "grey40", hjust = 0) +
  scale_x_continuous(breaks = -max_lag:max_lag) +
  labs(x        = "Lag (months, positive = CPU leads VIX)",
       y        = "Cross-correlation",
       subtitle = "Red dashed lines = 95% confidence bands under white-noise null") +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle    = element_text(size = 9, color = "grey35",
                                    margin = margin(b = 10)),
    plot.margin      = margin(14, 16, 10, 14),
    plot.background  = element_rect(fill = "white", color = NA),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "grey98", color = NA)
  )

ggsave("plots/cpu_vix_crosscorrelation.png", p_ccf,
       width = 7, height = 4.5, dpi = 300, bg = "white")
p_ccf

# =========================================================================
# SECTION 14: TRULY PREDETERMINED VIX(t-3)
# =========================================================================

event_panel <- event_panel %>%
  arrange(company_name, month) %>%
  group_by(company_name) %>%
  mutate(vix_lag3 = lag(vix, 3)) %>%
  ungroup()

event_panel_lm <- event_panel_lm %>%
  arrange(company_name, month) %>%
  group_by(company_name) %>%
  mutate(vix_lag3 = lag(vix, 3)) %>%
  ungroup()

# Rolling threshold
reg_vix_lag3 <- feols(
  realized_vol ~ rel_time + vix_lag3 | company_name,
  data    = event_panel,
  cluster = ~company_name
)

# Local maxima (preferred)
reg_lm_vix_lag3 <- feols(
  realized_vol ~ rel_time + vix_lag3 | company_name,
  data    = event_panel_lm,
  cluster = ~company_name
)

cat("\n=== TRULY PREDETERMINED VIX(t-3): Rolling threshold ===\n")
summary(reg_vix_lag3)
cat("\n=== TRULY PREDETERMINED VIX(t-3): Local maxima ===\n")
summary(reg_lm_vix_lag3)

# =========================================================================
# SECTION 15: SUMMARY TABLES — Baseline / Raw VIX / VIX(t-3)
# =========================================================================

cat("\n=== SUMMARY TABLE: Rolling threshold ===\n")
etable(
  reg, reg_vix, reg_vix_lag3,
  keep    = "rel_time",
  headers = c("Baseline", "Raw VIX", "VIX(-3)"),
  title   = "Robustness: VIX endogeneity - Rolling threshold"
)

etable(
  reg, reg_vix, reg_vix_lag3,
  keep    = "rel_time",
  headers = c("Baseline", "Raw VIX", "VIX(-3)"),
  title   = "Robustness: VIX endogeneity - Rolling threshold",
  file    = "plots/table_vix_endogeneity_rolling.tex"
)

cat("\n=== SUMMARY TABLE: Local maxima ===\n")
etable(
  reg_lm, reg_lm_vix, reg_lm_vix_lag3,
  keep    = "rel_time",
  headers = c("Baseline", "Raw VIX", "VIX(-3)"),
  title   = "Robustness: VIX endogeneity - Local maxima"
)

etable(
  reg_lm, reg_lm_vix, reg_lm_vix_lag3,
  keep    = "rel_time",
  headers = c("Baseline", "Raw VIX", "VIX(-3)"),
  title   = "Robustness: VIX endogeneity - Local maxima",
  file    = "plots/table_vix_endogeneity_localmax.tex"
)

# =========================================================================
# SECTION 16: PLOT — 3-panel comparison (Baseline / Raw VIX / VIX(t-3))
# =========================================================================

# --- Rolling threshold ---
coef_rolling_endo <- bind_rows(
  extract_coefs(reg,          "Baseline"),
  extract_coefs(reg_vix,      "Raw VIX\n[bad control]"),
  extract_coefs(reg_vix_lag3, "VIX(-3)\n[predetermined]")
) %>%
  mutate(spec = factor(spec, levels = c(
    "Baseline",
    "Raw VIX\n[bad control]",
    "VIX(-3)\n[predetermined]"
  )))

p_rolling_endo <- ggplot(coef_rolling_endo,
                         aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60",
             linewidth = 0.35, linetype = "dashed") +
  geom_vline(xintercept = 0, color = "grey40",
             linewidth = 0.40, linetype = "dashed") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.15, color = "#2C3E50", linewidth = 0.5) +
  geom_point(size = 2.5, shape = 19, color = "#2C3E50") +
  facet_wrap(~ spec, ncol = 3,
             labeller = as_labeller(c(
               "Baseline"                  = "Panel A \u2014 Baseline",
               "Raw VIX\n[bad control]"    = "Panel B \u2014 Raw VIX\n[bad control]",
               "VIX(-3)\n[predetermined]"  = "Panel C \u2014 VIX(t\u22123)\n[predetermined]"
             ))) +
  scale_x_continuous(breaks = window) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.001)) +
  labs(
    subtitle = "Rolling threshold \u2014 Baseline vs Raw VIX vs VIX(t\u22123)",
    x        = "Months relative to CPU spike",
    y        = "Realized Volatility (coefficient estimate)",
    caption  = paste0(
      "Notes: Panel A = no VIX control. Panel B = contemporaneous VIX (bad control: ",
      "within-month simultaneity with CPU).\n",
      "Panel C = VIX(t\u22123): first lag with no overlap with CPU(t:t\u22122) input window ",
      "\u2014 fully predetermined by construction.\n",
      "Company fixed effects and standard errors clustered by company throughout."
    )
  ) +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35",
                                      margin = margin(b = 12)),
    plot.caption       = element_text(size = 7.5, color = "grey40",
                                      hjust = 0, margin = margin(t = 10)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 9.5,
                                      hjust = 0, margin = margin(b = 4)),
    strip.background   = element_blank(),
    axis.title.x       = element_text(size = 9.5, margin = margin(t = 8)),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8)),
    axis.text          = element_text(size = 8, color = "grey20"),
    axis.ticks         = element_line(color = "grey70", linewidth = 0.3),
    axis.ticks.length  = unit(2.5, "pt"),
    axis.line.x        = element_line(color = "grey40", linewidth = 0.35),
    axis.line.y        = element_blank(),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.35),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.background   = element_rect(fill = "grey98", color = NA),
    panel.spacing      = unit(1.2, "lines"),
    legend.position    = "none"
  )

ggsave("plots/event_study_rolling_endogeneity.png", p_rolling_endo,
       width = 11, height = 5, dpi = 300, bg = "white")
p_rolling_endo

# --- Local maxima (preferred) ---
coef_lm_endo <- bind_rows(
  extract_coefs(reg_lm,          "Baseline"),
  extract_coefs(reg_lm_vix,      "Raw VIX\n[bad control]"),
  extract_coefs(reg_lm_vix_lag3, "VIX(-3)\n[predetermined]")
) %>%
  mutate(spec = factor(spec, levels = c(
    "Baseline",
    "Raw VIX\n[bad control]",
    "VIX(-3)\n[predetermined]"
  )))

p_lm_endo <- ggplot(coef_lm_endo,
                    aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60",
             linewidth = 0.35, linetype = "dashed") +
  geom_vline(xintercept = 0, color = "grey40",
             linewidth = 0.40, linetype = "dashed") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                width = 0.15, color = "#2C3E50", linewidth = 0.5) +
  geom_point(size = 2.5, shape = 19, color = "#2C3E50") +
  facet_wrap(~ spec, ncol = 3,
             labeller = as_labeller(c(
               "Baseline"                  = "Panel A \u2014 Baseline",
               "Raw VIX\n[bad control]"    = "Panel B \u2014 Raw VIX\n[bad control]",
               "VIX(-3)\n[predetermined]"  = "Panel C \u2014 VIX(t\u22123)\n[predetermined]"
             ))) +
  scale_x_continuous(breaks = window) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.001)) +
  labs(
    subtitle = "Local maxima (preferred) \u2014 Baseline vs Raw VIX vs VIX(t\u22123)",
    x        = "Months relative to CPU spike",
    y        = "Realized Volatility (coefficient estimate)",
    caption  = paste0(
      "Notes: Panel A = no VIX control. Panel B = contemporaneous VIX (bad control: ",
      "within-month simultaneity with CPU).\n",
      "Panel C = VIX(t\u22123): first lag with no overlap with CPU(t:t\u22122) input window ",
      "\u2014 fully predetermined by construction.\n",
      "Company fixed effects and standard errors clustered by company throughout."
    )
  ) +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35",
                                      margin = margin(b = 12)),
    plot.caption       = element_text(size = 7.5, color = "grey40",
                                      hjust = 0, margin = margin(t = 10)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 9.5,
                                      hjust = 0, margin = margin(b = 4)),
    strip.background   = element_blank(),
    axis.title.x       = element_text(size = 9.5, margin = margin(t = 8)),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8)),
    axis.text          = element_text(size = 8, color = "grey20"),
    axis.ticks         = element_line(color = "grey70", linewidth = 0.3),
    axis.ticks.length  = unit(2.5, "pt"),
    axis.line.x        = element_line(color = "grey40", linewidth = 0.35),
    axis.line.y        = element_blank(),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.35),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.background   = element_rect(fill = "grey98", color = NA),
    panel.spacing      = unit(1.2, "lines"),
    legend.position    = "none"
  )

ggsave("plots/event_study_localmax_endogeneity.png", p_lm_endo,
       width = 11, height = 5, dpi = 300, bg = "white")
p_lm_endo

# =========================================================================
# =========================================================================
#
#  Other regressions:
#
# =========================================================================
# =========================================================================
# - Realized Vol
  #For both rolling window and local maxima method 
    # Naive regression: realized_vol ~ rel_time + company FE
    # (bad) Vix control 
    # Vix(t-3) control

# - Abnormal Trading Volume
  #For both rolling window and local maxima method 
    # Naive regression: abnormal_trade_vol ~ rel_time + company FE
    # (bad) Vix control 
    # Vix(t-3) control

# - First difference log trading volume
  #For both rolling window and local maxima method 
    # Naive regression: first_diff ~ rel_time + company FE
    # (bad) Vix control 
    # Vix(t-3) control

# - Arithmetic Returns
  #For both rolling window and local maxima method 
    # Naive regression: ar_returns ~ rel_time + company FE
    # (bad) Vix control 
    # Vix(t-3) control
# =========================================================================
# =========================================================================
#
#  EXTENDED REGRESSIONS — ALL OUTCOME VARIABLES
#  Structure:
#    BLOCK 1 — Build all variables from raw sources
#    BLOCK 2 — Merge into master dataframe & save CSV
#    BLOCK 3 — Aggregate to monthly & build event panels
#    BLOCK 4 — All regressions (6 per variable)
#    BLOCK 5 — Plots (6 individual + 2 combined per variable)
#    BLOCK 6 — Tables (6 individual + 2 combined per variable)
#
# =========================================================================

library(tidyquant)
library(tidyverse)
library(lubridate)
library(zoo)
library(fixest)

# =========================================================================
# BLOCK 1: BUILD ALL VARIABLES FROM RAW SOURCES
# =========================================================================

# ── 1a. Tickers & name bridge ─────────────────────────────────────────────
tickers <- c("AAPL","MSFT","NVDA","CSCO","IBM","CRM",
             "AXP","GS","JPM","V",
             "AMGN","JNJ","MRK","UNH",
             "AMZN","HD","MCD","NKE","WMT",
             "KO","PG",
             "MMM","BA","CAT","HON",
             "CVX","DIS","TRV","VZ","SHW")

ticker_map <- tibble(
  symbol       = tickers,
  company_name = c(
    "APPLE","MICROSOFT","NVIDIA","CISCO SYSTEMS",
    "INTERNATIONAL BUS.MCHS.","SALESFORCE",
    "AMERICAN EXPRESS","GOLDMAN SACHS GP.",
    "JP MORGAN CHASE & CO.","VISA 'A'",
    "AMGN","JOHNSON & JOHNSON","MERCK & COMPANY",
    "UNITEDHEALTH GROUP",
    "AMAZON.COM","HOME DEPOT","MCDONALDS",
    "NIKE 'B'","WALMART",
    "COCA COLA","PROCTER & GAMBLE",
    "3M","BOEING","CATERPILLAR","HONEYWELL INTL.",
    "CHEVRON","WALT DISNEY","TRAVELERS COS.",
    "VERIZON COMMUNICATIONS","SHERWIN"
  )
)

# ── 1b. Download daily price & volume from Yahoo Finance ─────────────────
cat("Downloading price/volume data (extended window for rolling mean)...\n")

raw_prices <- tq_get(
  tickers,
  from = "2015-11-01",   
  to   = Sys.Date(),
  get  = "stock.prices"
)

cat(sprintf("Downloaded %d rows for %d tickers\n",
            nrow(raw_prices), n_distinct(raw_prices$symbol)))

# ── 1c. Daily returns & realized vol from df (VWAP) ──────────────────────
# These use VWAP from df — consistent with existing realized_vol (Section 2)
daily_vwap <- df %>%
  filter(!is.na(VWAP), !is.na(company_name), company_name != "NA") %>%
  mutate(VWAP = as.numeric(VWAP),
         date = as.Date(date)) %>%
  arrange(company_name, date) %>%
  group_by(company_name) %>%
  mutate(daily_return_vwap = (VWAP - lag(VWAP)) / lag(VWAP)) %>%
  ungroup()

# Monthly realized volatility (sqrt(21) annualisation)
realized_vol_m <- daily_vwap %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(company_name, month) %>%
  summarise(realized_vol = sd(daily_return_vwap, na.rm = TRUE) * sqrt(21),
            .groups = "drop")

# Monthly arithmetic returns from VWAP
ar_returns_m <- daily_vwap %>%
  mutate(month = floor_date(date, "month")) %>%
  arrange(company_name, date) %>%
  group_by(company_name, month) %>%
  summarise(ar_returns = (last(VWAP) - first(VWAP)) / first(VWAP),
            .groups = "drop")

# =========================================================================
# BLOCK 1d — Volume variables from tidyquant
# =========================================================================

volume_m_raw <- raw_prices %>%
  arrange(symbol, date) %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(symbol, month) %>%
  summarise(
    log_volume = log(mean(volume, na.rm = TRUE) + 1),
    .groups    = "drop"
  ) %>%
  arrange(symbol, month) %>%
  group_by(symbol) %>%
  mutate(
    # 12-month rolling mean of log_volume — right-aligned (uses past 12m)
    # With download starting Nov 2015, this is fully populated by Nov 2016,
    # meaning abnormal_vol has no NAs from Jan 2017 onwards.
    vol_roll_mean = rollmean(log_volume, k = 12, fill = NA, align = "right"),
    abnormal_vol  = log_volume - lag(vol_roll_mean),
    fd_log_volume = log_volume - lag(log_volume)
  ) %>%
  ungroup() %>%
  # NOTE: do NOT filter by date here — the master_df filter below handles
  # the final sample window. Filtering here would re-introduce NAs at the
  # start of the analysis window.
  left_join(ticker_map, by = "symbol") %>%
  dplyr::select(company_name, month, log_volume, abnormal_vol, fd_log_volume)

cat("\n--- Volume variable coverage (full download window) ---\n")
cat("abnormal_vol  non-NA:", sum(!is.na(volume_m_raw$abnormal_vol)),  "\n")
cat("fd_log_volume non-NA:", sum(!is.na(volume_m_raw$fd_log_volume)), "\n")

# Quick sanity check: confirm no NAs in analysis window
volume_check <- volume_m_raw %>%
  filter(month >= as.Date("2017-01-01"))
cat("\nIn analysis window (Jan 2017+):\n")
cat("abnormal_vol  NAs:", sum(is.na(volume_check$abnormal_vol)),  "\n")
cat("fd_log_volume NAs:", sum(is.na(volume_check$fd_log_volume)), "\n")


# =========================================================================
# BLOCK 2: MERGE INTO MASTER DATAFRAME & SAVE CSV
# =========================================================================
# One row per (company_name, month). All outcome variables in one frame.
# full_join ensures no observations are silently dropped from any source.

# Also bring in firm fundamentals from df (monthly average where needed)
fundamentals_m <- df %>%
  filter(!is.na(company_name), company_name != "NA") %>%
  mutate(date  = as.Date(date),
         month = floor_date(date, "month")) %>%
  group_by(company_name, sector, month) %>%
  summarise(
    vix      = mean(vix,  na.rm = TRUE),
    wti      = mean(wti,  na.rm = TRUE),
    .groups  = "drop"
  )

master_df <- realized_vol_m %>%
  full_join(ar_returns_m,   by = c("company_name", "month")) %>%
  full_join(volume_m_raw,   by = c("company_name", "month")) %>%
  full_join(fundamentals_m, by = c("company_name", "month")) %>%
  arrange(company_name, month) %>%
  filter(month >= as.Date("2017-01-01"))

# Verify company_name coverage matches df
companies_df     <- unique(df$company_name[df$company_name != "NA" &
                                             !is.na(df$company_name)])
companies_master <- unique(master_df$company_name)
missing          <- setdiff(companies_df, companies_master)
if (length(missing) > 0) {
  cat("\nWARNING — companies in df but missing from master_df:\n")
  print(missing)
} else {
  cat("\nAll", length(companies_df), "companies matched successfully.\n")
}

cat("\n--- master_df coverage ---\n")
cat("Rows          :", nrow(master_df), "\n")
cat("Companies     :", n_distinct(master_df$company_name), "\n")
cat("Date range    :",
    as.character(min(master_df$month, na.rm = TRUE)), "to",
    as.character(max(master_df$month, na.rm = TRUE)), "\n")
for (v in c("realized_vol","ar_returns","abnormal_vol","fd_log_volume")) {
  cat(sprintf("  %-15s non-NA: %d\n", v, sum(!is.na(master_df[[v]]))))
}

# Save to disk
dir.create("data", showWarnings = FALSE)
write_csv(master_df, "data/master_firm_monthly.csv")
cat("\nMaster dataframe saved: data/master_firm_monthly.csv\n")


# =========================================================================
# BLOCK 3: AGGREGATE TO MONTHLY & BUILD EVENT PANELS
# =========================================================================
# master_df is already monthly. We just need to:
#   (a) compute VIX(t-3) on the calendar series
#   (b) build two event panels (rolling / local maxima)

# ── 3a. VIX(t-3) on calendar series ─────────────────────────────────────
vix_monthly <- master_df %>%
  group_by(month) %>%
  summarise(vix_ctrl = mean(vix, na.rm = TRUE), .groups = "drop") %>%
  arrange(month) %>%
  mutate(vix_lag3 = lag(vix_ctrl, 3))

# ── 3b. Event panel builder ───────────────────────────────────────────────
build_event_panel <- function(spike_dates, master_df,
                              CPU_index, vix_monthly, window) {
  expand_grid(
    spike_date   = spike_dates,
    company_name = unique(master_df$company_name),
    rel_time     = window
  ) %>%
    mutate(month = spike_date %m+% months(rel_time)) %>%
    left_join(master_df  %>% dplyr::select(company_name, month,
                                           realized_vol, ar_returns,
                                           abnormal_vol, fd_log_volume),
              by = c("company_name", "month")) %>%
    left_join(CPU_index  %>% dplyr::select(date, CPU),
              by = c("month" = "date")) %>%
    left_join(vix_monthly,
              by = "month") %>%
    rename(vix = vix_ctrl) %>%
    mutate(rel_time = factor(rel_time, levels = window),
           rel_time = relevel(rel_time, ref = "-2"))
}

panel_rolling  <- build_event_panel(spike_dates_rolling,  master_df,
                                    CPU_index, vix_monthly, window)
panel_localmax <- build_event_panel(spike_dates_localmax, master_df,
                                    CPU_index, vix_monthly, window)

cat("\n--- Event panel sizes ---\n")
cat("Rolling   :", nrow(panel_rolling),
    "rows |", n_distinct(panel_rolling$company_name),  "companies\n")
cat("Local max :", nrow(panel_localmax),
    "rows |", n_distinct(panel_localmax$company_name), "companies\n")

var_names <- c("realized_vol", "abnormal_vol", "fd_log_volume", "ar_returns")
cat("\n--- Outcome coverage in panels (% non-NA) ---\n")
for (v in var_names) {
  cat(sprintf("  %-15s  rolling: %.1f%%   localmax: %.1f%%\n", v,
              mean(!is.na(panel_rolling[[v]]))  * 100,
              mean(!is.na(panel_localmax[[v]])) * 100))
}


# =========================================================================
# BLOCK 4: ALL REGRESSIONS
# =========================================================================
# For each variable x each spike method: 3 specs = 6 regressions per variable.
#   Spec 1 — Baseline:  y ~ rel_time | company_name
#   Spec 2 — Raw VIX:   y ~ rel_time + vix | company_name   (bad control)
#   Spec 3 — VIX(t-3):  y ~ rel_time + vix_lag3 | company_name

# Store all regression objects in a named list for easy retrieval
regs <- list()

for (var in var_names) {
  
  cat(sprintf("\n--- Regressions: %s ---\n", var))
  
  f_base <- as.formula(sprintf("%s ~ rel_time | company_name", var))
  f_vix  <- as.formula(sprintf("%s ~ rel_time + vix | company_name", var))
  f_vix3 <- as.formula(sprintf("%s ~ rel_time + vix_lag3 | company_name", var))
  
  regs[[var]] <- list(
    rolling = list(
      base = feols(f_base, data = panel_rolling,  cluster = ~company_name),
      vix  = feols(f_vix,  data = panel_rolling,  cluster = ~company_name),
      vix3 = feols(f_vix3, data = panel_rolling,  cluster = ~company_name)
    ),
    localmax = list(
      base = feols(f_base, data = panel_localmax, cluster = ~company_name),
      vix  = feols(f_vix,  data = panel_localmax, cluster = ~company_name),
      vix3 = feols(f_vix3, data = panel_localmax, cluster = ~company_name)
    )
  )
  
  # Print all 6 summaries
  for (method in c("rolling", "localmax")) {
    for (spec in c("base", "vix", "vix3")) {
      cat(sprintf("\n  [%s | %s]\n", var, paste(method, spec, sep = " - ")))
      print(summary(regs[[var]][[method]][[spec]]))
    }
  }
}

cat("\nAll regressions complete.\n")


# =========================================================================
# BLOCK 5: PLOTS
# =========================================================================
# Per variable:
#   6 individual plots (1 per regression)
#   2 combined plots   (3 specs side-by-side, one per detection method)

# ── Shared helpers ────────────────────────────────────────────────────────
theme_reg <- theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35",
                                      margin = margin(b = 12)),
    plot.caption       = element_text(size = 7.5, color = "grey40",
                                      hjust = 0, margin = margin(t = 10)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 9.5,
                                      hjust = 0, margin = margin(b = 4)),
    strip.background   = element_blank(),
    axis.title.x       = element_text(size = 9.5, margin = margin(t = 8)),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8)),
    axis.text          = element_text(size = 8, color = "grey20"),
    axis.ticks         = element_line(color = "grey70", linewidth = 0.3),
    axis.ticks.length  = unit(2.5, "pt"),
    axis.line.x        = element_line(color = "grey40", linewidth = 0.35),
    axis.line.y        = element_blank(),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.35),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.background   = element_rect(fill = "grey98", color = NA),
    panel.spacing      = unit(1.2, "lines"),
    legend.position    = "none"
  )

# extract_coefs already defined in Section 6 of existing script

# Single-panel coefficient plot (for individual plots)
single_coef_plot <- function(reg_model, plot_title, plot_subtitle, y_label) {
  coef_df <- extract_coefs(reg_model, "est")
  ggplot(coef_df, aes(x = rel_time, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey60",
               linewidth = 0.35, linetype = "dashed") +
    geom_vline(xintercept = 0, color = "grey40",
               linewidth = 0.40, linetype = "dashed") +
    geom_ribbon(aes(ymin = conf.low, ymax = conf.high),
                fill = "#2C3E50", alpha = 0.12) +
    geom_line(color = "#2C3E50", linewidth = 0.6, lineend = "round") +
    geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                  width = 0.12, color = "#2C3E50", linewidth = 0.45) +
    geom_point(size = 2.5, shape = 19, color = "#2C3E50") +
    scale_x_continuous(breaks = window) +
    scale_y_continuous(labels = scales::number_format(accuracy = 0.001)) +
    labs(title    = plot_title,
         subtitle = plot_subtitle,
         x        = "Months relative to CPU spike",
         y        = y_label,
         caption  = paste0(
           "Notes: Company fixed effects. Standard errors clustered by company.\n",
           "Reference period: rel_time = \u22122. Shaded band = 95% CI."
         )) +
    theme_reg
}

# Multi-panel combined plot (for the 3-spec combined plots)
combined_coef_plot <- function(coef_list, plot_subtitle, y_label) {
  # coef_list: named list with names used as spec labels
  combined <- bind_rows(
    mapply(function(coef_df, label) {
      coef_df %>% mutate(spec = label)
    }, coef_list, names(coef_list), SIMPLIFY = FALSE)
  ) %>%
    mutate(spec = factor(spec, levels = names(coef_list)))
  
  panel_labels <- setNames(
    paste0("Panel ", LETTERS[seq_along(coef_list)], " \u2014 ", names(coef_list)),
    names(coef_list)
  )
  
  ggplot(combined, aes(x = rel_time, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey60",
               linewidth = 0.35, linetype = "dashed") +
    geom_vline(xintercept = 0, color = "grey40",
               linewidth = 0.40, linetype = "dashed") +
    geom_errorbar(aes(ymin = conf.low, ymax = conf.high),
                  width = 0.15, color = "#2C3E50", linewidth = 0.5) +
    geom_point(size = 2.5, shape = 19, color = "#2C3E50") +
    facet_wrap(~ spec, ncol = 3,
               labeller = as_labeller(panel_labels)) +
    scale_x_continuous(breaks = window) +
    scale_y_continuous(labels = scales::number_format(accuracy = 0.001)) +
    labs(subtitle = plot_subtitle,
         x        = "Months relative to CPU spike",
         y        = y_label,
         caption  = paste0(
           "Notes: Company fixed effects. Standard errors clustered by company.\n",
           "VIX(t\u22123): first VIX lag with no overlap with CPU(t:t\u22122) inputs.\n",
           "Reference period: rel_time = \u22122."
         )) +
    theme_reg
}

# Spec metadata
spec_meta <- list(
  base = list(label = "Baseline",          subtitle = "No controls"),
  vix  = list(label = "Raw VIX",           subtitle = "Contemporaneous VIX [bad control]"),
  vix3 = list(label = "VIX(t\u22123)",     subtitle = "VIX(t\u22123) — truly predetermined")
)

method_meta <- list(
  rolling  = "Rolling threshold",
  localmax = "Local maxima (preferred)"
)

outcome_labels <- list(
  realized_vol  = "Realized Volatility (coefficient estimate)",
  abnormal_vol  = "Abnormal Log Trading Volume (coefficient estimate)",
  fd_log_volume = "First Difference Log Volume (coefficient estimate)",
  ar_returns    = "Arithmetic Return (coefficient estimate)"
)

outcome_subtitles <- list(
  realized_vol  = "Realized Volatility",
  abnormal_vol  = "Abnormal Trading Volume",
  fd_log_volume = "First-Difference Log Trading Volume",
  ar_returns    = "Arithmetic Returns"
)

# ── Create directories ────────────────────────────────────────────────────
for (v in var_names) {
  dir.create(file.path("plots",  v), showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path("tables", v), showWarnings = FALSE, recursive = TRUE)
}

# ── Plot loop ─────────────────────────────────────────────────────────────
for (var in var_names) {
  
  ylab     <- outcome_labels[[var]]
  subtitle <- outcome_subtitles[[var]]
  
  cat(sprintf("\nSaving plots: %s\n", var))
  
  for (method in c("rolling", "localmax")) {
    
    method_label <- method_meta[[method]]
    
    # ── 6 individual plots ──────────────────────────────────────────────
    for (spec in c("base", "vix", "vix3")) {
      
      spec_label    <- spec_meta[[spec]]$label
      spec_subtitle <- spec_meta[[spec]]$subtitle
      reg_model     <- regs[[var]][[method]][[spec]]
      
      p <- single_coef_plot( 
        reg_model    = reg_model,
        plot_title   = sprintf("%s — %s", subtitle, spec_label),
        plot_subtitle = sprintf("%s | %s", method_label, spec_subtitle),
        y_label      = ylab
      )
      
      fname <- sprintf("%s_%s.png", method, spec)
      ggsave(file.path("plots", var, fname),
             p, width = 7, height = 4.5, dpi = 300, bg = "white")
      cat(sprintf("  \u2714 plots/%s/%s\n", var, fname))
    }
    
    # ── 1 combined plot (3 specs side by side) ──────────────────────────
    coef_list <- list(
      "Baseline"       = extract_coefs(regs[[var]][[method]][["base"]], "Baseline"),
      "Raw VIX"        = extract_coefs(regs[[var]][[method]][["vix"]],  "Raw VIX"),
      "VIX(t\u22123)"  = extract_coefs(regs[[var]][[method]][["vix3"]], "VIX(t\u22123)")
    )
    
    p_combined <- combined_coef_plot(
      coef_list     = coef_list,
      plot_subtitle = sprintf("%s \u2014 %s: all three specifications",
                              method_label, subtitle),
      y_label       = ylab
    )
    
    fname_combined <- sprintf("%s_combined.png", method)
    ggsave(file.path("plots", var, fname_combined),
           p_combined, width = 11, height = 5, dpi = 300, bg = "white")
    cat(sprintf("  \u2714 plots/%s/%s\n", var, fname_combined))
  }
}


# =========================================================================
# BLOCK 6: TABLES
# =========================================================================
# Per variable:
#   6 individual tables (1 per regression)
#   2 combined tables   (3 specs together, one per detection method)

for (var in var_names) {
  
  subtitle <- outcome_subtitles[[var]]
  cat(sprintf("\nSaving tables: %s\n", var))
  
  for (method in c("rolling", "localmax")) {
    
    method_label <- method_meta[[method]]
    
    # ── 3 individual tables ─────────────────────────────────────────────
    for (spec in c("base", "vix", "vix3")) {
      
      spec_label <- spec_meta[[spec]]$label
      reg_model  <- regs[[var]][[method]][[spec]]
      
      fname <- sprintf("%s_%s.tex", method, spec)
      etable(
        reg_model,
        keep    = "rel_time",
        title   = sprintf("%s — %s | %s", subtitle, method_label, spec_label),
        file    = file.path("tables", var, fname)
      )
      cat(sprintf("  \u2714 tables/%s/%s\n", var, fname))
    }
    
    # ── 1 combined table (3 specs) ──────────────────────────────────────
    fname_combined <- sprintf("%s_combined.tex", method)
    etable(
      regs[[var]][[method]][["base"]],
      regs[[var]][[method]][["vix"]],
      regs[[var]][[method]][["vix3"]],
      keep    = "rel_time",
      headers = c("Baseline", "Raw VIX", "VIX(t-3)"),
      title   = sprintf("%s — %s: Baseline vs Raw VIX vs VIX(t-3)",
                        subtitle, method_label),
      file    = file.path("tables", var, fname_combined)
    )
    cat(sprintf("  \u2714 tables/%s/%s\n", var, fname_combined))
  }
}


