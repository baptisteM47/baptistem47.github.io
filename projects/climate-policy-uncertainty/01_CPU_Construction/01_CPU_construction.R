###########################################################################
#                                                                         
#  FILE 1 — CPU INDEX CONSTRUCTION & SPIKE DETECTION                    
#                                                                         
#  What this file does:                                                   
#    1. Loads raw text data (campaign materials + legislation)             
#    2. Builds document embeddings using GloVe word vectors               
#    3. Computes the CPU index (cosine distance between texts)            
#    4. Detects "spike" events using two methods:                         
#       - Rolling threshold (mean + 1.5 SD over 12-month window)         
#       - Local maxima (peaks above global mean + 1.5 SD)                
#    5. Produces all CPU descriptive statistics plots                                   
#                                                                         
#                                                                         
###########################################################################

# =========================================================================
# SETUP — Load packages and clear workspace
# =========================================================================

library(text2vec)      
library(tidyverse)    
library(lubridate)     
library(data.table)    # fast file reading with fread()
library(stopwords)     # list of common English words to exclude
library(stargazer)     
library(ggplot2)      
library(zoo)           # rolling window functions (rollmean, rollapply)

rm(list = ls())       

dir.create("plots", showWarnings = FALSE)
dir.create("data",  showWarnings = FALSE)


# =========================================================================
# SECTION 1: LOAD RAW TEXT DATA
# =========================================================================
# We have two datasets:
#   - APP: campaign/political communication materials (e.g., press releases)
#   - Legislation: actual legislative texts (bills)
#
# We aggregate both to MONTHLY level by concatenating all texts within
# each month into a single document. This gives us one "document" per
# month per source.

APP         <- read_csv("data/APP_climate.csv")
Legislation <- read_csv("data/legi_climate_dataset.csv")

# Aggregate to monthly: paste all texts from the same month together
APP_m <- APP %>%
  mutate(month = floor_date(as.Date(date_published), "month")) %>%
  group_by(month) %>%
  summarise(text = paste(text, collapse = " "), .groups = "drop")

BILLS_m <- Legislation %>%
  mutate(month = floor_date(as.Date(date_published), "month")) %>%
  group_by(month) %>%
  summarise(text = paste(text, collapse = " "), .groups = "drop")


# =========================================================================
# SECTION 2: BUILD DOCUMENT EMBEDDINGS
# =========================================================================
# WHAT ARE EMBEDDINGS?
#   Each word can be represented as a vector of numbers (e.g., 100 numbers).
#   Words with similar meanings have similar vectors.
#   We use pre-trained GloVe vectors (trained on Wikipedia + news).
#
# WHAT IS A DOCUMENT EMBEDDING?
#   We represent an entire document as the average of its word vectors.
#   This gives us a single 100-dimensional vector per document.
#
# WHY?
#   We can then measure how "similar" two documents are using cosine
#   similarity. If campaign materials and legislation say similar things,
#   the cosine similarity is high (close to 1). If they diverge, it's low.

# Combine all documents for vocabulary building
all_docs <- c(APP_m$text, BILLS_m$text)

# Tokenize: split each document into individual words
it <- itoken(all_docs, tokenizer = word_tokenizer, progressbar = FALSE)

# Load pre-trained GloVe word vectors (100 dimensions per word)
glove_path  <- "data/glove.2024.wikigiga.100d.txt"
embeddings  <- fread(glove_path, data.table = FALSE, quote = "", header = FALSE)

# Convert to a matrix: rows = words, columns = 100 embedding dimensions
word_vectors            <- as.matrix(embeddings[, -1])
rownames(word_vectors)  <- embeddings[[1]]

# Build vocabulary: only keep words that (a) appear in our texts AND
# (b) have a GloVe vector, AND (c) are not stopwords ("the", "is", etc.)
vocab <- create_vocabulary(it, stopwords = stopwords("en")) %>%
  filter(term %in% rownames(word_vectors))

# Create a document-term matrix (DTM):
# Rows = documents, Columns = words, Values = word counts
vectorizer <- vocab_vectorizer(vocab)
dtm        <- create_dtm(it, vectorizer)

# Function to compute one document's embedding:
# Take the words that appear in the document, look up their GloVe vectors,
# and average them into a single 100-dim vector.
doc_embedding <- function(doc_id, dtm, word_vectors) {
  wts   <- dtm[doc_id, ]                              # word counts for this doc
  idx   <- which(wts > 0)                             # which words appear?
  if (length(idx) == 0) return(rep(0, ncol(word_vectors)))
  words <- colnames(dtm)[idx]
  words <- words[words %in% rownames(word_vectors)]    # keep only words with vectors
  if (length(words) == 0) return(rep(0, ncol(word_vectors)))
  colMeans(word_vectors[words, , drop = FALSE])        # average word vectors
}

# Compute embeddings for all APP documents and all BILLS documents
n_app     <- nrow(APP_m)

APP_emb   <- t(sapply(seq_len(n_app),         function(i) doc_embedding(i,          dtm, word_vectors)))
BILLS_emb <- t(sapply(seq_len(nrow(BILLS_m)),  function(i) doc_embedding(n_app + i,  dtm, word_vectors)))

# Cosine similarity function:
# Measures angle between two vectors. Range: -1 to +1.
# +1 = identical direction (very similar), 0 = unrelated, -1 = opposite
cosine_sim <- function(x, y) {
  if (all(x == 0) || all(y == 0)) return(NA_real_)
  sum(x * y) / (sqrt(sum(x^2)) * sqrt(sum(y^2)))
}


# =========================================================================
# SECTION 3: COMPUTE CPU INDICES (with different lag windows)
# =========================================================================
# CPU = "Climate Policy Uncertainty"
# CPU(t) = 1 - cosine_similarity(campaign_embedding(t), legislation_embedding(t))
#
# When campaign materials and legislation are very similar, CPU is LOW
#   (policy is aligned with what was promised)
# When they diverge, CPU is HIGH
#   (uncertainty about whether promises become law)
#
# We compute 4 variants with different lag windows:
#   - CPU(t):     compare campaign text at month t vs legislation at month t
#   - CPU(t:t-1): average campaign text from months t and t-1 vs legislation at t
#   - CPU(t:t-2): average campaign text from t, t-1, t-2 vs legislation at t
#   - CPU(t:t-3): average campaign text from t, t-1, t-2, t-3 vs legislation at t
#
# The lag variants smooth out noise in the campaign materials by averaging
# over multiple months. Our preferred specification uses CPU(t:t-2) = 3 months.

compute_CPU <- function(max_lag, APP_emb, BILLS_emb, APP_m, BILLS_m) {
  # Start date accounts for the lag window (need enough history)
  start_date <- as.Date("2016-11-01") %m+% months(max_lag)

  result <- lapply(seq_len(nrow(APP_m)), function(i) {
    t0        <- APP_m$month[i]
    bills_idx <- which(BILLS_m$month == t0)

    # If no legislation exists for this month, return NA
    if (length(bills_idx) == 0)
      return(tibble(date = t0, cosine_similarity = NA_real_, CPU = NA_real_))

    # Average the APP embeddings over the lag window [t, t-1, ..., t-max_lag]
    lag_indices    <- seq(i, i - max_lag, by = -1)
    lag_indices    <- lag_indices[lag_indices >= 1]
    app_emb_lagged <- colMeans(APP_emb[lag_indices, , drop = FALSE])

    # Compute similarity and CPU
    sim <- cosine_sim(app_emb_lagged, BILLS_emb[bills_idx, ])
    tibble(date = t0, cosine_similarity = sim, CPU = 1 - sim)
  })

  bind_rows(result) %>% filter(date >= start_date)
}

# Compute all 4 lag variants
CPU_index   <- compute_CPU(0, APP_emb, BILLS_emb, APP_m, BILLS_m)  # no lag
CPU_index_1 <- compute_CPU(1, APP_emb, BILLS_emb, APP_m, BILLS_m)  # 1-month lag
CPU_index_2 <- compute_CPU(2, APP_emb, BILLS_emb, APP_m, BILLS_m)  # 2-month lag (preferred)
CPU_index_3 <- compute_CPU(3, APP_emb, BILLS_emb, APP_m, BILLS_m)  # 3-month lag

# Store them in a list for easy looping
cpu_list   <- list(CPU_index, CPU_index_1, CPU_index_2, CPU_index_3)
cpu_labels <- c("CPU (t)", "CPU (t:t-1)", "CPU (t:t-2)", "CPU (t:t-3)")
colors     <- c("#2C3E50", "#1a6fb5", "#c0392b", "#6C3483")


# =========================================================================
# SECTION 4: SUMMARY STATISTICS
# =========================================================================
# For each lag variant, compute basic descriptive stats (mean, median, SD, etc.)
# Also create a standardized (z-score) version: CPU_z = (CPU - mean) / SD

for (k in seq_along(cpu_list)) {
  df    <- cpu_list[[k]]
  label <- cpu_labels[k]

  # Standardize: subtract mean, divide by SD → mean=0, SD=1
  df <- df %>% mutate(CPU_z = as.numeric(scale(CPU)))

  # Summary stats for raw CPU
  cpu_summary <- df %>%
    summarise(Mean    = round(mean(CPU, na.rm = TRUE), 4),
              Median  = round(median(CPU, na.rm = TRUE), 4),
              Sd.Dev  = round(sd(CPU, na.rm = TRUE), 4),
              Min     = round(min(CPU, na.rm = TRUE), 4),
              Max     = round(max(CPU, na.rm = TRUE), 4))

  # Summary stats for standardized CPU
  cpu_z_summary <- df %>%
    summarise(Mean    = round(mean(CPU_z, na.rm = TRUE), 4),
              Median  = round(median(CPU_z, na.rm = TRUE), 4),
              Sd.Dev  = round(sd(CPU_z, na.rm = TRUE), 4),
              Min     = round(min(CPU_z, na.rm = TRUE), 4),
              Max     = round(max(CPU_z, na.rm = TRUE), 4))

  # Print LaTeX tables (will appear in console)
  stargazer(cpu_summary,   type = "latex", summary = FALSE, rownames = FALSE,
            title = paste("Summary Statistics for", label))
  stargazer(cpu_z_summary, type = "latex", summary = FALSE, rownames = FALSE,
            title = paste("Summary Statistics for", label, "(standardized)"))

  # Save back (now includes CPU_z column)
  cpu_list[[k]] <- df
}


# =========================================================================
# SECTION 5: PLOT — CPU Time Series (all 4 lag variants, no spikes)
# =========================================================================
# A simple 2x2 grid showing how each CPU variant evolves over time.
# This is the "raw" CPU before any spike detection.

cpu_long <- bind_rows(lapply(seq_along(cpu_list), function(k) {
  cpu_list[[k]] %>%
    dplyr::select(date, CPU) %>%
    mutate(index = cpu_labels[k])
})) %>%
  mutate(index = factor(index, levels = cpu_labels))

p <- ggplot(cpu_long, aes(x = date, y = CPU, color = index)) +
  geom_line(lwd = 0.65, lineend = "round") +
  facet_wrap(~ index, ncol = 2, scales = "free_y",
             labeller = as_labeller(c(
               "CPU (t)"     = "Panel A - CPU (t)",
               "CPU (t:t-1)" = "Panel B - CPU (t : t-1)",
               "CPU (t:t-2)" = "Panel C - CPU (t : t-2)",
               "CPU (t:t-3)" = "Panel D - CPU (t : t-3)"))) +
  scale_color_manual(values = setNames(colors, cpu_labels)) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y",
               expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                     expand = expansion(mult = c(0.05, 0.08))) +
  labs(subtitle = "Monthly cosine distance between campaign materials and legislative texts, 2017-present",
       x = NULL, y = "CPU Index",
       caption = "Notes: Each panel reports 1 minus the cosine similarity between the average GloVe embedding\nof campaign materials (over the indicated window) and legislative texts at time t.") +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.caption       = element_text(size = 7.5, color = "grey40", hjust = 0, margin = margin(t = 10)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 9.5, hjust = 0, margin = margin(b = 4)),
    strip.background   = element_blank(),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8), angle = 90),
    axis.text.x        = element_text(size = 8, color = "grey20"),
    axis.text.y        = element_text(size = 8, color = "grey20"),
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

ggsave("plots/CPU_all_lags.png", p, width = 8, height = 6, dpi = 300, bg = "white")
p


# =========================================================================
# SECTION 6: SAVE ALL CPU INDICES TO DISK
# =========================================================================
# Merge all 4 variants into one wide data frame and save as CSV.
# This file will be read by File 2 (regressions) so we don't have to
# recompute embeddings every time.

CPU_all <- cpu_list[[1]] %>%
  dplyr::select(date, cosine_similarity, CPU, CPU_z) %>%
  rename(cos_CPU = cosine_similarity, CPU_z0 = CPU_z, CPU_0 = CPU)

for (k in 2:4) {
  CPU_all <- CPU_all %>%
    left_join(
      cpu_list[[k]] %>%
        dplyr::select(date, cosine_similarity, CPU, CPU_z) %>%
        rename_with(~ paste0(., "_", k - 1), -date),
      by = "date"
    )
}

write_csv(CPU_all, "data/CPU_all_indices.csv")
cat("CPU indices saved to data/CPU_all_indices.csv\n")


# =========================================================================
# SECTION 7: SPIKE DETECTION — METHOD 1: ROLLING THRESHOLD
# =========================================================================
# IDEA: A spike is a month where CPU is "unusually high" compared to
# recent history. We define "unusually high" as:
#   CPU(t) > rolling_mean(12 months) + 1.5 * rolling_SD(12 months)
#
# CLUSTERING: If multiple consecutive months are flagged, we keep only
# the highest peak within each cluster. We also enforce a minimum
# 5-month gap between spikes to avoid overlapping event windows.

# --- Helper function: detect rolling spikes for any CPU variant ---
get_spikes_rolling <- function(df, label) {
  df %>%
    arrange(date) %>%
    mutate(
      # 12-month rolling statistics (right-aligned = uses past 12 months)
      roll_mean = rollmean(CPU, k = 12, fill = NA, align = "right"),
      roll_sd   = rollapply(CPU, width = 12, FUN = sd, fill = NA, align = "right"),
      # Flag months above the threshold
      spike_raw = CPU > roll_mean + 1.5 * roll_sd
    ) %>%
    filter(spike_raw) %>%
    # Cluster nearby spikes (within 4 months of each other)
    mutate(
      gap         = as.numeric(difftime(date, lag(date), units = "days")) / 30,
      gap         = ifelse(is.na(gap), 99, gap),
      new_cluster = gap > 4,
      cluster_id  = cumsum(new_cluster)
    ) %>%
    # Keep only the peak within each cluster
    group_by(cluster_id) %>%
    slice_max(CPU, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    arrange(date) %>%
    # Enforce minimum 5-month gap between kept spikes
    {
      kept <- numeric(); last_kept <- as.Date("1900-01-01")
      for (j in seq_len(nrow(.))) {
        ms <- as.numeric(difftime(.$date[j], last_kept, units = "days")) / 30
        if (ms >= 5) { kept <- c(kept, j); last_kept <- .$date[j] }
      }
      slice(., kept)
    } %>%
    dplyr::select(date) %>%
    mutate(index = label)
}


# =========================================================================
# SECTION 8: SPIKE DETECTION — METHOD 2: LOCAL MAXIMA
# =========================================================================
# IDEA: A spike is a LOCAL MAXIMUM — a month where CPU is strictly higher
# than both the month before and the month after. Additionally, it must
# be above the global mean + 1.5*SD threshold.
#
# This is our PREFERRED method because:
#   - It identifies true peaks (not just high-but-flat periods)
#   - Less sensitive to the rolling window length
#   - More intuitive: a spike = a peak in the time series
#
# We still enforce a minimum 5-month gap between spikes.

detect_spikes_localmax <- function(cpu_series, min_gap = 5, threshold_sd = 1.5) {
  dates  <- cpu_series$date
  values <- cpu_series$CPU
  n      <- length(dates)

  # Step 1: Find local maxima (strictly higher than both neighbors)
  local_max <- rep(FALSE, n)
  for (k in 2:(n - 1)) {
    if (is.na(values[k]) | is.na(values[k - 1]) | is.na(values[k + 1])) next
    if (values[k] > values[k - 1] & values[k] > values[k + 1]) local_max[k] <- TRUE
  }

  # Step 2: Keep only local maxima above the global threshold
  threshold     <- mean(values, na.rm = TRUE) + threshold_sd * sd(values, na.rm = TRUE)
  candidate_idx <- which(local_max & values > threshold)
  if (length(candidate_idx) == 0) return(as.Date(character(0)))

  # Step 3: Enforce minimum gap between spikes
  # If two spikes are too close, keep the higher one (unless 20%+ higher)
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

# Helper to apply local max detection on any CPU variant
get_spikes_localmax <- function(df, label, min_gap = 5, threshold_sd = 1.5) {
  df_clean <- df %>% arrange(date) %>% filter(!is.na(CPU)) %>% dplyr::select(date, CPU)
  tibble(date = detect_spikes_localmax(df_clean, min_gap, threshold_sd), index = label)
}


# =========================================================================
# SECTION 9: APPLY SPIKE DETECTION TO OUR PREFERRED CPU (t:t-2)
# =========================================================================
# We use CPU_2 (the 2-lag variant = 3-month window) for all regressions.
# Here we detect spikes using both methods on this series.

# --- Reload CPU from disk (so this section can run independently) ---
CPU_all <- read_csv("data/CPU_all_indices.csv")

CPU_index <- CPU_all %>%
  filter(date >= "2016-11-01") %>%
  arrange(date) %>%
  rename(CPU = CPU_2) %>%
  mutate(
    roll_mean = rollmean(CPU, k = 12, fill = NA, align = "right"),
    roll_sd   = rollapply(CPU, width = 12, FUN = sd, fill = NA, align = "right"),
    spike_raw = CPU > roll_mean + 1.5 * roll_sd
  ) %>%
  filter(date >= "2017-01-01")

# Rolling threshold spikes (Method 1)
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

cat("Rolling threshold — Number of spikes:", length(spike_dates_rolling), "\n")
print(spike_dates_rolling)

# Local maxima spikes (Method 2 — preferred)
cpu_for_detection     <- CPU_index %>% filter(!is.na(CPU)) %>% dplyr::select(date, CPU)
spike_dates_localmax  <- detect_spikes_localmax(cpu_for_detection)

cat("Local maxima — Number of spikes:", length(spike_dates_localmax), "\n")
print(spike_dates_localmax)


# =========================================================================
# SECTION 10: PLOT — CPU with Rolling Threshold Spikes (2x2)
# =========================================================================

spike_lines_rolling <- bind_rows(
  get_spikes_rolling(cpu_list[[1]], "CPU (t)"),
  get_spikes_rolling(cpu_list[[2]], "CPU (t:t-1)"),
  get_spikes_rolling(cpu_list[[3]], "CPU (t:t-2)"),
  get_spikes_rolling(cpu_list[[4]], "CPU (t:t-3)")
) %>%
  mutate(index = factor(index, levels = cpu_labels))

p_rolling_spikes <- ggplot(cpu_long, aes(x = date, y = CPU, color = index)) +
  geom_vline(data = spike_lines_rolling, aes(xintercept = date),
             color = "grey50", linewidth = 0.35, linetype = "dashed", alpha = 0.8) +
  geom_line(lwd = 0.65, lineend = "round") +
  facet_wrap(~ index, ncol = 2, scales = "free_y",
             labeller = as_labeller(c(
               "CPU (t)"     = "Panel A - CPU (t)",
               "CPU (t:t-1)" = "Panel B - CPU (t : t-1)",
               "CPU (t:t-2)" = "Panel C - CPU (t : t-2)",
               "CPU (t:t-3)" = "Panel D - CPU (t : t-3)"))) +
  geom_point(data = spike_lines_rolling %>% left_join(cpu_long, by = c("date", "index")),
             aes(x = date, y = CPU), color = "#c0392b", size = 2, shape = 19) +
  scale_color_manual(values = setNames(colors, cpu_labels)) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y",
               expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                     expand = expansion(mult = c(0.05, 0.08))) +
  labs(subtitle = "Rolling 12-month threshold spike detection (mean + 1.5 SD)",
       x = NULL, y = "CPU Index",
       caption = "Notes: Red dots indicate identified spike episodes.\nThreshold: rolling 12-month mean + 1.5 SD. Minimum 5-month gap enforced.") +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.caption       = element_text(size = 7.5, color = "grey40", hjust = 0, margin = margin(t = 10)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 9.5, hjust = 0, margin = margin(b = 4)),
    strip.background   = element_blank(),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8), angle = 90),
    axis.text.x        = element_text(size = 8, color = "grey20"),
    axis.text.y        = element_text(size = 8, color = "grey20"),
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

ggsave("plots/CPU_all_lags_rolling.png", p_rolling_spikes,
       width = 8, height = 6, dpi = 300, bg = "white")
p_rolling_spikes


# =========================================================================
# SECTION 11: PLOT — CPU with Local Maxima Spikes (2x2)
# =========================================================================

spike_lines_localmax <- bind_rows(
  get_spikes_localmax(cpu_list[[1]], "CPU (t)"),
  get_spikes_localmax(cpu_list[[2]], "CPU (t:t-1)"),
  get_spikes_localmax(cpu_list[[3]], "CPU (t:t-2)"),
  get_spikes_localmax(cpu_list[[4]], "CPU (t:t-3)")
) %>%
  mutate(index = factor(index, levels = cpu_labels))

p_localmax <- ggplot(cpu_long, aes(x = date, y = CPU, color = index)) +
  geom_vline(data = spike_lines_localmax, aes(xintercept = date),
             color = "grey50", linewidth = 0.35, linetype = "dashed", alpha = 0.8) +
  geom_line(lwd = 0.65, lineend = "round") +
  facet_wrap(~ index, ncol = 2, scales = "free_y",
             labeller = as_labeller(c(
               "CPU (t)"     = "Panel A - CPU (t)",
               "CPU (t:t-1)" = "Panel B - CPU (t : t-1)",
               "CPU (t:t-2)" = "Panel C - CPU (t : t-2)",
               "CPU (t:t-3)" = "Panel D - CPU (t : t-3)"))) +
  geom_point(data = spike_lines_localmax %>% left_join(cpu_long, by = c("date", "index")),
             aes(x = date, y = CPU), color = "#c0392b", size = 2, shape = 19) +
  scale_color_manual(values = setNames(colors, cpu_labels)) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y",
               expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                     expand = expansion(mult = c(0.05, 0.08))) +
  labs(subtitle = "Local maxima spike detection (peaks above mean + 1.5 SD, min 5-month gap)",
       x = NULL, y = "CPU Index",
       caption = "Notes: Red dots indicate identified spike episodes.\nSpikes = local maxima strictly higher than both neighbors, above global mean + 1.5 SD.") +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.caption       = element_text(size = 7.5, color = "grey40", hjust = 0, margin = margin(t = 10)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 9.5, hjust = 0, margin = margin(b = 4)),
    strip.background   = element_blank(),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8), angle = 90),
    axis.text.x        = element_text(size = 8, color = "grey20"),
    axis.text.y        = element_text(size = 8, color = "grey20"),
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

ggsave("plots/CPU_all_lags_localmax.png", p_localmax,
       width = 8, height = 6, dpi = 300, bg = "white")
p_localmax


# =========================================================================
# SECTION 12: EVENT STUDY ON CPU ITSELF
# =========================================================================
# Before looking at stock market outcomes, we check: what does CPU itself
# look like around spike events? We expect a clear inverted-V pattern:
# CPU rises leading up to the spike, peaks at t=0, then falls.
#

window <- -2:2   # event window: 2 months before to 2 months after

# Shared ggplot theme for all event study plots (to avoid repetition)
event_theme <- theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.caption       = element_text(size = 7.5, color = "grey40", hjust = 0, margin = margin(t = 10)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 9.5, hjust = 0, margin = margin(b = 4)),
    strip.background   = element_blank(),
    axis.title.x       = element_text(size = 9.5, margin = margin(t = 8)),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8), angle = 90),
    axis.text.x        = element_text(size = 8, color = "grey20"),
    axis.text.y        = element_text(size = 8, color = "grey20"),
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


# --- Generic stacking function ---
# Given a list of spike dates and the CPU data, compute mean CPU
# in the event window across all spikes.
stack_event_window <- function(df, spike_dates, label) {
  event_stack <- lapply(spike_dates, function(t0) {
    idx0 <- which(df$date == t0)
    lapply(window, function(w) {
      idx_w <- idx0 + w
      if (idx_w < 1 || idx_w > nrow(df)) return(NULL)
      tibble(event_time = w, CPU = df$CPU[idx_w], spike_date = t0)
    }) %>% bind_rows()
  }) %>% bind_rows()
  
  event_stack %>%
    group_by(event_time) %>%
    summarise(mean_CPU = mean(CPU, na.rm = TRUE),
              se       = sd(CPU, na.rm = TRUE) / sqrt(n()),
              .groups  = "drop") %>%
    mutate(index = label)
}


# =========================================================================
# SECTION 12a: METHOD 1 — Rolling Threshold Event Study (2x2)
# =========================================================================
# For each CPU lag variant, detect spikes with rolling threshold,
# then stack the event windows and compute the average CPU pattern.

run_event_study_rolling <- function(df, label) {
  # Detect spikes using rolling threshold
  df <- df %>%
    arrange(date) %>%
    mutate(
      roll_mean = rollmean(CPU, k = 12, fill = NA, align = "right"),
      roll_sd   = rollapply(CPU, width = 12, FUN = sd, fill = NA, align = "right"),
      spike     = CPU > roll_mean + 1.5 * roll_sd
    )
  
  spike_months <- df %>%
    filter(spike) %>%
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
  spike_dates <- spike_episodes$date[keep]
  
  stack_event_window(df, spike_dates, label)
}

event_results_rolling <- bind_rows(
  run_event_study_rolling(cpu_list[[1]], "CPU (t)"),
  run_event_study_rolling(cpu_list[[2]], "CPU (t:t-1)"),
  run_event_study_rolling(cpu_list[[3]], "CPU (t:t-2)"),
  run_event_study_rolling(cpu_list[[4]], "CPU (t:t-3)")
)

p_event_rolling <- ggplot(event_results_rolling, aes(x = event_time, y = mean_CPU)) +
  geom_ribbon(aes(ymin = mean_CPU - 1.96 * se, ymax = mean_CPU + 1.96 * se, fill = index),
              alpha = 0.15) +
  geom_line(aes(color = index), lwd = 0.65, lineend = "round") +
  geom_point(aes(color = index), size = 1.8, shape = 19) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.4) +
  facet_wrap(~ index, ncol = 2,
             labeller = as_labeller(c(
               "CPU (t)"     = "Panel A - CPU (t)",
               "CPU (t:t-1)" = "Panel B - CPU (t : t-1)",
               "CPU (t:t-2)" = "Panel C - CPU (t : t-2)",
               "CPU (t:t-3)" = "Panel D - CPU (t : t-3)"))) +
  scale_x_continuous(breaks = window) +
  scale_color_manual(values = setNames(colors, cpu_labels)) +
  scale_fill_manual(values = setNames(colors, cpu_labels)) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                     expand = expansion(mult = c(0.05, 0.08))) +
  labs(subtitle = "Rolling threshold — Average CPU in +/- 2 month window around spikes",
       x = "Months relative to spike", y = "CPU Index",
       caption = "Notes: Spikes detected via 12-month rolling mean + 1.5 SD.\nShaded bands = 95% CI. Dashed line = spike date (t = 0).") +
  event_theme

ggsave("plots/CPU_event_study_rolling.png", p_event_rolling,
       width = 8, height = 6, dpi = 300, bg = "white")
p_event_rolling


# =========================================================================
# SECTION 12b: METHOD 2 — Local Maxima Event Study (2x2)
# =========================================================================
# Same thing but using local maxima detection (our preferred method).

run_event_study_localmax <- function(df, label) {
  # Detect spikes using local maxima
  df_clean    <- df %>% arrange(date) %>% filter(!is.na(CPU)) %>% dplyr::select(date, CPU)
  spike_dates <- detect_spikes_localmax(df_clean)
  
  stack_event_window(df, spike_dates, label)
}

event_results_localmax <- bind_rows(
  run_event_study_localmax(cpu_list[[1]], "CPU (t)"),
  run_event_study_localmax(cpu_list[[2]], "CPU (t:t-1)"),
  run_event_study_localmax(cpu_list[[3]], "CPU (t:t-2)"),
  run_event_study_localmax(cpu_list[[4]], "CPU (t:t-3)")
)

p_event_localmax <- ggplot(event_results_localmax, aes(x = event_time, y = mean_CPU)) +
  geom_ribbon(aes(ymin = mean_CPU - 1.96 * se, ymax = mean_CPU + 1.96 * se, fill = index),
              alpha = 0.15) +
  geom_line(aes(color = index), lwd = 0.65, lineend = "round") +
  geom_point(aes(color = index), size = 1.8, shape = 19) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.4) +
  facet_wrap(~ index, ncol = 2,
             labeller = as_labeller(c(
               "CPU (t)"     = "Panel A - CPU (t)",
               "CPU (t:t-1)" = "Panel B - CPU (t : t-1)",
               "CPU (t:t-2)" = "Panel C - CPU (t : t-2)",
               "CPU (t:t-3)" = "Panel D - CPU (t : t-3)"))) +
  scale_x_continuous(breaks = window) +
  scale_color_manual(values = setNames(colors, cpu_labels)) +
  scale_fill_manual(values = setNames(colors, cpu_labels)) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                     expand = expansion(mult = c(0.05, 0.08))) +
  labs(subtitle = "Local maxima — Average CPU in +/- 2 month window around spikes (preferred)",
       x = "Months relative to spike", y = "CPU Index",
       caption = "Notes: Spikes detected as local maxima above global mean + 1.5 SD.\nShaded bands = 95% CI. Dashed line = spike date (t = 0).") +
  event_theme

ggsave("plots/CPU_event_study_localmax.png", p_event_localmax,
       width = 8, height = 6, dpi = 300, bg = "white")
p_event_localmax


# =========================================================================
# SECTION 12c: FOCUSED COMPARISON — CPU(t:t-2) only, both methods
# =========================================================================
# Our preferred lag variant is CPU(t:t-2) (3-month window).
# Here we show the event study pattern for this variant using both
# spike detection methods side by side, so the reader can compare.

# Extract CPU(t:t-2) results from both methods and label them
focused_rolling <- event_results_rolling %>%
  filter(index == "CPU (t:t-2)") %>%
  mutate(method = "Rolling threshold")

focused_localmax <- event_results_localmax %>%
  filter(index == "CPU (t:t-2)") %>%
  mutate(method = "Local maxima (preferred)")

focused_comparison <- bind_rows(focused_rolling, focused_localmax) %>%
  mutate(method = factor(method, levels = c("Rolling threshold",
                                            "Local maxima (preferred)")))

p_focused <- ggplot(focused_comparison, aes(x = event_time, y = mean_CPU)) +
  geom_ribbon(aes(ymin = mean_CPU - 1.96 * se, ymax = mean_CPU + 1.96 * se),
              fill = "#c0392b", alpha = 0.15) +
  geom_line(color = "#c0392b", lwd = 0.65, lineend = "round") +
  geom_point(color = "#c0392b", size = 2, shape = 19) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.4) +
  facet_wrap(~ method, ncol = 2) +
  scale_x_continuous(breaks = window) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                     expand = expansion(mult = c(0.05, 0.08))) +
  labs(subtitle = "CPU (t:t-2) — Event window comparison across detection methods",
       x = "Months relative to spike", y = "CPU Index",
       caption = "Notes: Both panels show CPU (t:t-2). Left = rolling 12-month threshold.\nRight = local maxima (preferred). Shaded bands = 95% CI.") +
  event_theme

ggsave("plots/CPU_event_study_comparison_cpu2.png", p_focused,
       width = 8, height = 4.5, dpi = 300, bg = "white")
p_focused

###
# =========================================================================
# SECTION 13: DESCRIPTIVE TEXT ANALYSIS AROUND SPIKES
# =========================================================================
# We want to understand what is happening inside the texts around spikes.
# =========================================================================
# SECTION 13a: TEXT VOLUME HEATMAP
# =========================================================================
# For each spike, count how many paragraphs (or total words) appear in
# campaign materials and legislation in the months around the spike.
# Display as a heatmap: rows = spike episodes, columns = relative time.
# We use local maxima spikes on CPU(t:t-2).

# Count words per month for each source
app_volume <- APP_m %>%
  mutate(n_words_app = str_count(text, "\\S+")) %>%
  dplyr::select(month, n_words_app)

bills_volume <- BILLS_m %>%
  mutate(n_words_bills = str_count(text, "\\S+")) %>%
  dplyr::select(month, n_words_bills)

# Build event window for text volume
volume_panel <- expand_grid(
  spike_date = spike_dates_localmax,
  rel_time   = -2:2
) %>%
  mutate(month = spike_date %m+% months(rel_time)) %>%
  left_join(app_volume,   by = "month") %>%
  left_join(bills_volume, by = "month") %>%
  # Replace NAs with 0 (months with no documents)
  mutate(n_words_app   = replace_na(n_words_app, 0),
         n_words_bills = replace_na(n_words_bills, 0))

# --- Heatmap: Campaign materials volume ---
# Create a label for each spike (date as string)
volume_panel <- volume_panel %>%
  mutate(spike_label = format(spike_date, "%b %Y"))

# Pivot to long format for faceted heatmap
volume_long <- volume_panel %>%
  pivot_longer(cols = c(n_words_app, n_words_bills),
               names_to = "source", values_to = "n_words") %>%
  mutate(source = ifelse(source == "n_words_app",
                         "Campaign Materials", "Legislative Texts"))

p_heatmap <- ggplot(volume_long,
                    aes(x = factor(rel_time), y = reorder(spike_label, spike_date),
                        fill = n_words)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = scales::comma(n_words)), size = 2.8, color = "grey20") +
  facet_wrap(~ source, ncol = 2) +
  scale_fill_gradient(low = "white", high = "#2C3E50", name = "Word count") +
  labs(x = "Months relative to spike",
       y = NULL,
       #subtitle = "Text volume (word count) around CPU spike episodes"
       ) +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle    = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.margin      = margin(14, 16, 10, 14),
    plot.background  = element_rect(fill = "white", color = NA),
    strip.text       = element_text(face = "bold", size = 10),
    axis.text.x      = element_text(size = 9),
    axis.text.y      = element_text(size = 8),
    panel.grid       = element_blank(),
    legend.position  = "bottom",
    legend.key.width = unit(1.5, "cm")
  )

ggsave("plots/text_volume_heatmap.png", p_heatmap,
       width = 10, height = 6, dpi = 300, bg = "white")
p_heatmap


# =========================================================================
# SECTION 13b: CLIMATE DICTIONARY INTENSITY AROUND SPIKES
# =========================================================================
# IDEA: Using the same climate dictionary used to SELECT our documents,
# we count how many dictionary terms appear in each monthly text corpus
# and track how this "climate discourse intensity" behaves around spike dates.
#
# This is a natural complement to the CPU index:
#   - CPU measures DIVERGENCE between campaign & legislative texts
#   - Dictionary intensity measures RAW SALIENCE of climate topics
#
# We compute two variants:
#   (a) Raw count: total dictionary token matches per month
#   (b) Normalized intensity: raw count / total word count (share)
# =========================================================================

# -------------------------------------------------------------------------
# STEP 1: Define the climate dictionary
# -------------------------------------------------------------------------
# All terms from Gavriilidis (2023)

climate_unigrams <- c(
  "ghg", "co2", "carbon", "emission", "methane",
  "environmental", "decarbonization", "renewables", "epa", "doe"
)

climate_bigrams <- c(
  "climate change", "climate crisis", "climate disaster", "climate science",
  "climate scientist", "climate action", "global warming", "climate warming",
  "temperature rise", "global temperature", "greenhouse gas", "renewable energy",
  "renewable fuel", "renewable electricity", "renewable power", "clean energy",
  "clean power", "green energy", "energy efficiency", "fuel economy",
  "fuel efficiency", "fossil fuel", "energy transition", "climate transition",
  "climate mitigation", "climate adaptation", "climate accord", "climate conference",
  "climate activist", "climate demonstration", "energy policy", "energy legislation",
  "energy law", "energy tax", "energy committee", "climate bill", "climate policy",
  "climate legislation", "climate rule", "carbon tax", "carbon price",
  "carbon market", "carbon trading", "carbon limit", "emission trading",
  "emission limit", "emission permit", "emission standard", "ghg rule",
  "ghg limit", "ghg permit", "ghg standard", "fuel standard",
  "waxman markey", "kerry lieberman"
)

climate_trigrams <- c(
  "capture and sequestration", "climate and energy", "sea level rise",
  "environmental protection agency", "energy department", "cap and trade",
  "clean power plan", "energy efficiency program", "fuel economy standard",
  "climate change bill", "clean air act", "climate stewardship act",
  "clear skies act"
)

# All terms combined (longest first so multi-word matches take priority)
all_climate_terms <- c(climate_trigrams, climate_bigrams, climate_unigrams)

# -------------------------------------------------------------------------
# STEP 2: Function to count dictionary hits in a text
# -------------------------------------------------------------------------
# We count each occurrence (not just presence) of each term, case-insensitive.
# For a fair comparison across months of different lengths, we also compute
# the normalized intensity = hits / total_words.

count_climate_hits <- function(text_vec) {
  sapply(text_vec, function(txt) {
    if (is.na(txt) || nchar(txt) == 0) return(0L)
    txt_lower <- tolower(txt)
    # Sum occurrences of all dictionary terms
    total_hits <- sum(sapply(all_climate_terms, function(term) {
      # Use fixed matching for speed; gregexpr returns all positions
      m <- gregexpr(term, txt_lower, fixed = TRUE)[[1]]
      if (m[1] == -1L) 0L else length(m)
    }))
    total_hits
  }, USE.NAMES = FALSE)
}

# -------------------------------------------------------------------------
# Step3
# Single combined summary table: Climate Intensity (APP & BILLS)
# Output: tables/climate_intensity_summary.tex
# -------------------------------------------------------------------------

library(kableExtra)

dir.create("tables", showWarnings = FALSE)

# Compute monthly climate intensity (unchanged from original)
climate_app <- APP_m %>%
  mutate(
    n_words       = str_count(text, "\\S+"),
    climate_hits  = count_climate_hits(text),
    climate_share = climate_hits / pmax(n_words, 1)
  ) %>%
  dplyr::select(month, n_words, climate_hits, climate_share)

climate_bills <- BILLS_m %>%
  mutate(
    n_words       = str_count(text, "\\S+"),
    climate_hits  = count_climate_hits(text),
    climate_share = climate_hits / pmax(n_words, 1)
  ) %>%
  dplyr::select(month, n_words, climate_hits, climate_share)

# Build a single summary data frame (one row per series)
summarise_series <- function(x, label) {
  tibble(
    Series  = label,
    N       = sum(!is.na(x)),
    Mean    = round(mean(x,   na.rm = TRUE), 4),
    Median  = round(median(x, na.rm = TRUE), 4),
    `Std. Dev.` = round(sd(x, na.rm = TRUE), 4),
    Min     = round(min(x,    na.rm = TRUE), 4),
    Max     = round(max(x,    na.rm = TRUE), 4)
  )
}

summary_tbl <- bind_rows(
  summarise_series(climate_app$climate_share,   "Campaign Materials (APP)"),
  summarise_series(climate_bills$climate_share, "Legislative Texts (BILLS)")
)

# Note text (will be wrapped automatically via parbox)
note_text <- paste0(
  "\\textit{Notes:} Climate intensity = number of Gavriilidis (2023) ",
  "climate dictionary matches divided by total monthly word count. ",
  "Sample: monthly observations, 2017--present."
)

# Build and export the table
kbl(
  summary_tbl,
  format    = "latex",
  booktabs  = TRUE,
  linesep   = "",
  caption   = "Descriptive Statistics: Monthly Climate Dictionary Intensity",
  label     = "climate_intensity_summary",   # becomes \label{tab:climate_intensity_summary}
  align     = c("l", "c", "c", "c", "c", "c", "c")
) %>%
  kable_styling(
    latex_options = c("hold_position"),  # [htbp] — keeps table near its call
    full_width    = FALSE                # prevents stretching to page width
  ) %>%
  footnote(
    general         = note_text,
    general_title   = "",
    escape          = FALSE,             # allows \textit{} to render
    threeparttable  = TRUE               # wraps notes in threeparttable
    # → auto line-breaks to table width
  ) %>%
  save_kable("tables/climate_intensity_summary.tex")

cat("Table saved to tables/climate_intensity_summary.tex\n")

# -------------------------------------------------------------------------
# STEP 4: Time series plot — climate intensity over time (both sources)
#         with spike markers (local maxima on CPU t:t-2)
# -------------------------------------------------------------------------

# Combine for plotting
climate_long <- bind_rows(
  climate_app   %>% mutate(source = "Campaign Materials"),
  climate_bills %>% mutate(source = "Legislative Texts")
) %>%
  rename(date = month)

# Spike dates (already computed in Section 9 as spike_dates_localmax)
spike_df <- tibble(date = spike_dates_localmax)

p_climate_ts <- ggplot(climate_long, aes(x = date, y = climate_share, color = source)) +
  geom_vline(data = spike_df, aes(xintercept = date),
             color = "grey60", linewidth = 0.35, linetype = "dashed", alpha = 0.9,
             inherit.aes = FALSE) +
  geom_line(lwd = 0.65, lineend = "round") +
  # Mark spike months on each source line
  geom_point(
    data = climate_long %>% filter(date %in% spike_dates_localmax),
    aes(x = date, y = climate_share),
    color = "#c0392b", size = 2.2, shape = 19
  ) +
  scale_color_manual(
    values = c("Campaign Materials" = "#1a6fb5", "Legislative Texts" = "#2C3E50"),
    name   = NULL
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y",
               expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 0.01),
    expand = expansion(mult = c(0.05, 0.08))
  ) +
  labs(
    #subtitle = "Share of words matching the climate dictionary, by source — local maxima spikes marked",
    x = NULL, y = "Climate term share (% of words)",
    caption = paste0(
      "Notes: Climate intensity = matches from the Gavriilidis (2023) climate dictionary / total words.\n",
      "Red dots = CPU(t:t-2) local-maxima spike months. Dashed lines = same spike dates."
    )
  ) +
  theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.caption       = element_text(size = 7.5, color = "grey40", hjust = 0, margin = margin(t = 10)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    axis.title.y       = element_text(size = 9.5, margin = margin(r = 8), angle = 90),
    axis.text.x        = element_text(size = 8, color = "grey20"),
    axis.text.y        = element_text(size = 8, color = "grey20"),
    axis.ticks         = element_line(color = "grey70", linewidth = 0.3),
    axis.ticks.length  = unit(2.5, "pt"),
    axis.line.x        = element_line(color = "grey40", linewidth = 0.35),
    axis.line.y        = element_blank(),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.35),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.background   = element_rect(fill = "grey98", color = NA),
    legend.position    = "bottom",
    legend.text        = element_text(size = 9)
  )

ggsave("plots/climate_intensity_ts.png", p_climate_ts,
       width = 9, height = 5, dpi = 300, bg = "white")
p_climate_ts

# =========================================================================
# SECTION 13c: TOP-20 CLIMATE DICTIONARY TERMS AT SPIKE MONTHS
# =========================================================================
# For each spike month, count individual term occurrences in APP and BILLS.
# We produce:
#   (a) One faceted plot per spike: top-20 terms, raw count + per-1000-words
#   (b) An aggregated plot: average counts across ALL spike months combined
#
# This tells us WHICH climate topics dominate the discourse at spike moments.
# =========================================================================

# -------------------------------------------------------------------------
# Helper: count each individual term in a single text string
# -------------------------------------------------------------------------
count_terms_in_text <- function(txt) {
  if (is.na(txt) || nchar(trimws(txt)) == 0)
    return(tibble(term = character(), raw_count = integer()))
  
  txt_lower <- tolower(txt)
  
  tibble(term = all_climate_terms) %>%
    mutate(raw_count = sapply(term, function(trm) {
      m <- gregexpr(trm, txt_lower, fixed = TRUE)[[1]]
      if (m[1] == -1L) 0L else length(m)
    })) %>%
    filter(raw_count > 0)
}

# -------------------------------------------------------------------------
# Build term-level counts for every spike month (APP + BILLS)
# -------------------------------------------------------------------------
spike_term_counts <- lapply(spike_dates_localmax, function(t0) {
  
  # Pull the monthly text for this spike (may be absent → empty string)
  app_text <- APP_m %>%
    filter(month == t0) %>%
    pull(text) %>%
    { if (length(.) == 0) "" else . }
  
  bills_text <- BILLS_m %>%
    filter(month == t0) %>%
    pull(text) %>%
    { if (length(.) == 0) "" else . }
  
  # Total word counts (for scaling)
  nw_app   <- max(str_count(app_text,   "\\S+"), 1)
  nw_bills <- max(str_count(bills_text, "\\S+"), 1)
  
  app_counts <- count_terms_in_text(app_text) %>%
    mutate(
      source       = "Campaign Materials",
      total_words  = nw_app,
      per_1000     = raw_count / nw_app * 1000
    )
  
  bills_counts <- count_terms_in_text(bills_text) %>%
    mutate(
      source      = "Legislative Texts",
      total_words = nw_bills,
      per_1000    = raw_count / nw_bills * 1000
    )
  
  bind_rows(app_counts, bills_counts) %>%
    mutate(spike_date  = t0,
           spike_label = format(t0, "%b %Y"))
  
}) %>% bind_rows()

# -------------------------------------------------------------------------
# Helper: build a top-20 horizontal bar plot for one spike month
# -------------------------------------------------------------------------
plot_top20_spike <- function(spike_date_sel, count_data) {
  
  df <- count_data %>% filter(spike_date == spike_date_sel)
  lbl <- format(spike_date_sel, "%B %Y")
  
  if (nrow(df) == 0) {
    message("No dictionary hits found for spike: ", lbl)
    return(NULL)
  }
  
  # Identify top-20 terms by TOTAL raw count across both sources
  top20_terms <- df %>%
    group_by(term) %>%
    summarise(total_raw = sum(raw_count), .groups = "drop") %>%
    slice_max(total_raw, n = 20, with_ties = FALSE) %>%
    pull(term)
  
  df_top <- df %>%
    filter(term %in% top20_terms) %>%
    # Order by combined raw count descending
    mutate(term = factor(term,
                         levels = df %>%
                           filter(term %in% top20_terms) %>%
                           group_by(term) %>%
                           summarise(s = sum(raw_count), .groups = "drop") %>%
                           arrange(s) %>%
                           pull(term)))
  
  source_colors <- c("Campaign Materials" = "#1a6fb5",
                     "Legislative Texts"  = "#2C3E50")
  
  bar_theme <- theme_minimal(base_family = "serif", base_size = 10) +
    theme(
      plot.title         = element_text(size = 10.5, face = "bold", margin = margin(b = 4)),
      plot.subtitle      = element_text(size = 9, color = "grey40", margin = margin(b = 10)),
      plot.caption       = element_text(size = 7.5, color = "grey40", hjust = 0,
                                        margin = margin(t = 8)),
      plot.margin        = margin(12, 14, 10, 12),
      plot.background    = element_rect(fill = "white", color = NA),
      strip.text         = element_text(face = "bold", size = 9.5),
      strip.background   = element_blank(),
      axis.title.x       = element_text(size = 9, margin = margin(t = 6)),
      axis.title.y       = element_blank(),
      axis.text.x        = element_text(size = 8, color = "grey20"),
      axis.text.y        = element_text(size = 8, color = "grey25"),
      axis.ticks.y       = element_blank(),
      axis.line.x        = element_line(color = "grey40", linewidth = 0.35),
      axis.line.y        = element_blank(),
      panel.grid.major.x = element_line(color = "grey90", linewidth = 0.35),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      panel.background   = element_rect(fill = "grey98", color = NA),
      panel.spacing      = unit(1.2, "lines"),
      legend.position    = "bottom",
      legend.title       = element_blank(),
      legend.text        = element_text(size = 9)
    )
  
  # --- Panel A: Raw counts ---
  p_raw <- ggplot(df_top,
                  aes(x = raw_count, y = term, fill = source)) +
    geom_col(position = position_dodge(width = 0.7),
             width = 0.65, alpha = 0.88) +
    geom_text(aes(label = raw_count),
              position = position_dodge(width = 0.7),
              hjust = -0.15, size = 2.6, color = "grey25") +
    scale_fill_manual(values = source_colors) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.18))) +
    labs(title    = paste("Raw occurrence count —", lbl),
         subtitle = "Top 20 climate dictionary terms at spike month",
         x        = "Raw count") +
    bar_theme
  
  # --- Panel B: Per-1000-words (normalized) ---
  p_norm <- ggplot(df_top,
                   aes(x = per_1000, y = term, fill = source)) +
    geom_col(position = position_dodge(width = 0.7),
             width = 0.65, alpha = 0.88) +
    geom_text(aes(label = sprintf("%.2f", per_1000)),
              position = position_dodge(width = 0.7),
              hjust = -0.15, size = 2.6, color = "grey25") +
    scale_fill_manual(values = source_colors) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.22))) +
    labs(title    = paste("Normalized count (per 1 000 words) —", lbl),
         subtitle = "Top 20 climate dictionary terms at spike month",
         x        = "Occurrences per 1 000 words") +
    bar_theme
  
  list(raw = p_raw, norm = p_norm,
       label = format(spike_date_sel, "%Y_%m"))
}

# -------------------------------------------------------------------------
# Generate and save one plot-pair per spike month
# -------------------------------------------------------------------------
dir.create("plots/spike_terms", showWarnings = FALSE)

for (sd in spike_dates_localmax) {
  sd <- as.Date(sd)  # ensure Date class after list iteration
  res <- plot_top20_spike(sd, spike_term_counts)
  if (is.null(res)) next
  
  # Combine raw + norm side by side using patchwork (or cowplot)
  # We use base ggplot saving to avoid requiring patchwork
  ggsave(
    paste0("plots/spike_terms/top20_raw_",  res$label, ".png"),
    res$raw,  width = 8, height = 6, dpi = 300, bg = "white"
  )
  ggsave(
    paste0("plots/spike_terms/top20_norm_", res$label, ".png"),
    res$norm, width = 8, height = 6, dpi = 300, bg = "white"
  )
  cat("Saved plots for spike:", res$label, "\n")
}

# -------------------------------------------------------------------------
# Aggregated plot: average counts across ALL spike months
# -------------------------------------------------------------------------

# Compute average raw count and average per-1000 across spikes (per term/source)
spike_agg <- spike_term_counts %>%
  group_by(term, source) %>%
  summarise(
    mean_raw     = mean(raw_count, na.rm = TRUE),
    mean_per1000 = mean(per_1000,  na.rm = TRUE),
    n_spikes     = n(),
    .groups      = "drop"
  )

# Top-20 by mean raw count (summed across sources)
top20_agg <- spike_agg %>%
  group_by(term) %>%
  summarise(total_mean_raw = sum(mean_raw), .groups = "drop") %>%
  slice_max(total_mean_raw, n = 20, with_ties = FALSE) %>%
  pull(term)

spike_agg_top <- spike_agg %>%
  filter(term %in% top20_agg) %>%
  mutate(term = factor(term,
                       levels = spike_agg %>%
                         filter(term %in% top20_agg) %>%
                         group_by(term) %>%
                         summarise(s = sum(mean_raw), .groups = "drop") %>%
                         arrange(s) %>%
                         pull(term)))

source_colors <- c("Campaign Materials" = "#1a6fb5",
                   "Legislative Texts"  = "#2C3E50")

agg_bar_theme <- theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.caption       = element_text(size = 7.5, color = "grey40", hjust = 0,
                                      margin = margin(t = 10)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 10.5, margin = margin(b = 6)),
    strip.background   = element_blank(),
    axis.title.x       = element_text(size = 9.5, margin = margin(t = 8)),
    axis.title.y       = element_blank(),
    axis.text.x        = element_text(size = 8.5, color = "grey20"),
    axis.text.y        = element_text(size = 8.5, color = "grey25"),
    axis.ticks.y       = element_blank(),
    axis.line.x        = element_line(color = "grey40", linewidth = 0.35),
    axis.line.y        = element_blank(),
    panel.grid.major.x = element_line(color = "grey90", linewidth = 0.35),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.background   = element_rect(fill = "grey98", color = NA),
    panel.spacing      = unit(1.8, "lines"),
    legend.position    = "bottom",
    legend.title       = element_blank(),
    legend.text        = element_text(size = 9.5)
  )

# --- Aggregated raw ---
p_agg_raw <- ggplot(spike_agg_top,
                    aes(x = mean_raw, y = term, fill = source)) +
  geom_col(position = position_dodge(width = 0.72),
           width = 0.65, alpha = 0.88) +
  geom_text(aes(label = sprintf("%.1f", mean_raw)),
            position = position_dodge(width = 0.72),
            hjust = -0.15, size = 2.8, color = "grey25") +
  scale_fill_manual(values = source_colors) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.20))) +
  labs(
    subtitle = paste0("Top 20 climate dictionary terms — average raw count across ",
                      length(spike_dates_localmax), " spike months"),
    x        = "Mean raw count across spike months"
  ) +
  agg_bar_theme

# --- Aggregated normalized ---
p_agg_norm <- ggplot(spike_agg_top,
                     aes(x = mean_per1000, y = term, fill = source)) +
  geom_col(position = position_dodge(width = 0.72),
           width = 0.65, alpha = 0.88) +
  geom_text(aes(label = sprintf("%.2f", mean_per1000)),
            position = position_dodge(width = 0.72),
            hjust = -0.15, size = 2.8, color = "grey25") +
  scale_fill_manual(values = source_colors) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.22))) +
  labs(
    subtitle = paste0("Top 20 climate dictionary terms — average per-1 000-words across ",
                      length(spike_dates_localmax), " spike months"),
    x        = "Mean occurrences per 1 000 words across spike months"
  ) +
  agg_bar_theme

ggsave("plots/spike_terms/top20_agg_raw.png",
       p_agg_raw,  width = 9, height = 6.5, dpi = 300, bg = "white")
ggsave("plots/spike_terms/top20_agg_norm.png",
       p_agg_norm, width = 9, height = 6.5, dpi = 300, bg = "white")

# =========================================================================
# SECTION 13d: SPIKE vs NON-SPIKE — POOLED % OF TOTAL WORDS
# =========================================================================
# We pool all text within each period and compute term frequency on the pooled
# corpus.
#
# Pooled frequency = total hits across all [spike / non-spike] months
#                    / total words across all [spike / non-spike] months
#
# =========================================================================

library(stringi)

# -------------------------------------------------------------------------
# STEP 1: Pool raw hits and total words by period × source
# -------------------------------------------------------------------------

all_months <- sort(unique(c(APP_m$month, BILLS_m$month)))

month_tags <- tibble(month = all_months) %>%
  mutate(is_spike = month %in% spike_dates_localmax,
         period   = ifelse(is_spike, "Spike months", "Non-spike months"))

# Word counts per month × source
monthly_wordcounts <- bind_rows(
  APP_m   %>% mutate(source  = "Campaign Materials",
                     n_words = str_count(text, "\\S+")) %>%
    dplyr::select(month, source, n_words),
  BILLS_m %>% mutate(source  = "Legislative Texts",
                     n_words = str_count(text, "\\S+")) %>%
    dplyr::select(month, source, n_words)
)

# Pool total words by period × source
pooled_wordcounts <- monthly_wordcounts %>%
  left_join(month_tags, by = "month") %>%
  group_by(source, period) %>%
  summarise(total_words = sum(n_words, na.rm = TRUE),
            n_months    = n(),
            .groups     = "drop")

# -------------------------------------------------------------------------
# Vectorised term count matrix (fast — replaces rowwise loop)
# -------------------------------------------------------------------------

app_texts   <- tolower(APP_m$text)
bills_texts <- tolower(BILLS_m$text)

count_matrix <- function(texts, terms) {
  do.call(cbind, lapply(terms, function(t)
    stri_count_fixed(texts, t)
  ))
}

app_mat   <- count_matrix(app_texts,   all_climate_terms)
bills_mat <- count_matrix(bills_texts, all_climate_terms)

mat_to_long <- function(mat, months, source_label) {
  as_tibble(mat, .name_repair = "minimal") %>%
    setNames(all_climate_terms) %>%
    mutate(month = months, source = source_label) %>%
    pivot_longer(
      cols      = all_of(all_climate_terms),
      names_to  = "term",
      values_to = "raw_count"
    ) %>%
    dplyr::select(month, source, term, raw_count)
}

# NOTE: labels must match monthly_wordcounts exactly — no (APP)/(BILLS) suffix
all_term_full <- bind_rows(
  mat_to_long(app_mat,   APP_m$month,   "Campaign Materials"),
  mat_to_long(bills_mat, BILLS_m$month, "Legislative Texts")
)

# Pool raw hits by period × source
pooled_hits <- all_term_full %>%
  left_join(month_tags, by = "month") %>%
  group_by(term, source, period) %>%
  summarise(total_hits = sum(raw_count, na.rm = TRUE),
            .groups    = "drop")

# Merge and compute pooled % of total words
pooled_freq <- pooled_hits %>%
  left_join(pooled_wordcounts, by = c("source", "period")) %>%
  mutate(pct_words = total_hits / total_words * 100)

cat("\n--- Pooled corpus sizes ---\n")
print(pooled_wordcounts)

# -------------------------------------------------------------------------
# STEP 2: Select top-20 terms (by pooled % at spike months)
# -------------------------------------------------------------------------

top20_pooled <- pooled_freq %>%
  filter(period == "Spike months") %>%
  group_by(term) %>%
  summarise(total_pct = sum(pct_words), .groups = "drop") %>%
  slice_max(total_pct, n = 20, with_ties = FALSE) %>%
  pull(term)

term_order_pooled <- pooled_freq %>%
  filter(period == "Spike months", term %in% top20_pooled) %>%
  group_by(term) %>%
  summarise(s = sum(pct_words), .groups = "drop") %>%
  arrange(s) %>%
  pull(term)

pooled_top <- pooled_freq %>%
  filter(term %in% top20_pooled) %>%
  mutate(
    term   = factor(term,   levels = term_order_pooled),
    period = factor(period, levels = c("Non-spike months", "Spike months"))
  )

# -------------------------------------------------------------------------
# Shared palettes and theme
# -------------------------------------------------------------------------

period_colors <- c("Spike months"     = "#c0392b",
                   "Non-spike months" = "#95a5a6")

source_colors <- c("Campaign Materials" = "#1a6fb5",
                   "Legislative Texts"  = "#2C3E50")

comp_bar_theme <- theme_minimal(base_family = "serif", base_size = 11) +
  theme(
    plot.subtitle      = element_text(size = 9.5, color = "grey35", margin = margin(b = 12)),
    plot.caption       = element_text(size = 7.5, color = "grey40", hjust = 0,
                                      margin = margin(t = 10)),
    plot.margin        = margin(14, 16, 10, 14),
    plot.background    = element_rect(fill = "white", color = NA),
    strip.text         = element_text(face = "bold", size = 10, margin = margin(b = 6)),
    strip.background   = element_blank(),
    axis.title.x       = element_text(size = 9.5, margin = margin(t = 8)),
    axis.title.y       = element_blank(),
    axis.text.x        = element_text(size = 8, color = "grey20"),
    axis.text.y        = element_text(size = 8.5, color = "grey25"),
    axis.ticks.y       = element_blank(),
    axis.line.x        = element_line(color = "grey40", linewidth = 0.35),
    axis.line.y        = element_blank(),
    panel.grid.major.x = element_line(color = "grey90", linewidth = 0.35),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.background   = element_rect(fill = "grey98", color = NA),
    panel.spacing      = unit(1.8, "lines"),
    legend.position    = "bottom",
    legend.title       = element_blank(),
    legend.text        = element_text(size = 9.5)
  )

# -------------------------------------------------------------------------
# STEP 3: Side-by-side bar — pooled % of total words, faceted by source
# -------------------------------------------------------------------------

p_comp_pct <- ggplot(pooled_top,
                     aes(x = pct_words, y = term, fill = period)) +
  geom_col(position = position_dodge(width = 0.72),
           width = 0.65, alpha = 0.9) +
  geom_text(aes(label = sprintf("%.3f%%", pct_words)),
            position = position_dodge(width = 0.72),
            hjust = -0.10, size = 2.6, color = "grey25") +
  facet_wrap(~ source, ncol = 2, scales = "free_x") +
  scale_fill_manual(values = period_colors) +
  scale_x_continuous(
    labels = function(x) paste0(sprintf("%.3f", x), "%"),
    expand = expansion(mult = c(0, 0.25))
  ) +
  labs(
    subtitle = paste0(
     # "Top 20 terms — pooled share of total words: spike vs non-spike months\n",
      "(N spike = ", length(spike_dates_localmax), " months,  ",
      "N non-spike = ", length(all_months) - length(spike_dates_localmax), " months)"
    ),
    x       = "Term frequency (% of all words in pooled corpus)",
    caption = paste0(
      "Notes: Frequency = total dictionary hits / total words across all months in each group.\n",
      "Pooling avoids distortion from unequal document counts across months.\n",
      "Terms ranked by pooled spike frequency (summed across sources)."
    )
  ) +
  comp_bar_theme

ggsave("plots/spike_terms/comp_pct_pooled.png", p_comp_pct,
       width = 11, height = 6.5, dpi = 300, bg = "white")
p_comp_pct

# -------------------------------------------------------------------------
# STEP 4: Relative frequency plot — spike pooled % / non-spike pooled %
# -------------------------------------------------------------------------

rel_freq_pooled <- pooled_freq %>%
  filter(term %in% top20_pooled) %>%
  dplyr::select(term, source, period, pct_words) %>%
  pivot_wider(names_from  = period,
              values_from = pct_words,
              values_fill = 0) %>%
  rename(spike_pct    = `Spike months`,
         nonspike_pct = `Non-spike months`) %>%
  mutate(
    rel_freq = spike_pct / pmax(nonspike_pct, 1e-6),
    term     = factor(term, levels = term_order_pooled)
  )

p_rel_freq_pooled <- ggplot(rel_freq_pooled,
                            aes(x = rel_freq, y = term, color = source)) +
  geom_vline(xintercept = 1, color = "grey50", linewidth = 0.4,
             linetype = "dashed") +
  geom_segment(aes(x = 1, xend = rel_freq, y = term, yend = term),
               position  = position_dodge(width = 0.6),
               linewidth = 0.55, alpha = 0.7) +
  geom_point(position = position_dodge(width = 0.6),
             size = 2.5, shape = 19) +
  facet_wrap(~ source, ncol = 2) +
  scale_color_manual(values = source_colors) +
  scale_x_continuous(
    breaks = c(0.5, 1, 1.5, 2, 3, 4, 5),
    labels = c("0.5×", "1×\n(baseline)", "1.5×", "2×", "3×", "4×", "5×"),
    expand = expansion(mult = c(0.05, 0.15))
  ) +
  labs(
   # subtitle = "Relative frequency: pooled spike frequency / pooled non-spike frequency",
    x        = "Relative frequency  (spike % / non-spike %)",
    caption  = paste0(
      "Notes: Relative frequency > 1 = term is proportionally more frequent at spike months.\n",
      "Both numerator and denominator use pooled-corpus frequencies (not averaged rates).\n",
      "Floor of 1e-6 applied to non-spike denominator to avoid division by zero."
    )
  ) +
  comp_bar_theme +
  theme(legend.position = "none")

ggsave("plots/spike_terms/comp_rel_freq_pooled.png", p_rel_freq_pooled,
       width = 11, height = 6.5, dpi = 300, bg = "white")
p_rel_freq_pooled

# -------------------------------------------------------------------------
# STEP 5: Diverging bar — difference in pooled % (spike minus non-spike)
# -------------------------------------------------------------------------

diff_pooled <- pooled_freq %>%
  filter(term %in% top20_pooled) %>%
  dplyr::select(term, source, period, pct_words) %>%
  pivot_wider(names_from  = period,
              values_from = pct_words,
              values_fill = 0) %>%
  rename(spike_pct    = `Spike months`,
         nonspike_pct = `Non-spike months`) %>%
  mutate(
    diff      = spike_pct - nonspike_pct,
    term      = factor(term, levels = term_order_pooled),
    direction = ifelse(diff >= 0, "Higher at spikes", "Lower at spikes")
  )

p_diverging_pooled <- ggplot(diff_pooled,
                             aes(x = diff, y = term, fill = direction)) +
  geom_col(position = position_dodge(width = 0.72),
           width = 0.65, alpha = 0.88) +
  geom_vline(xintercept = 0, color = "grey40", linewidth = 0.35) +
  geom_text(
    aes(label = sprintf("%+.4f%%", diff),
        hjust = ifelse(diff >= 0, -0.10, 1.10)),
    position = position_dodge(width = 0.72),
    size     = 2.6, color = "grey25"
  ) +
  facet_wrap(~ source, ncol = 2, scales = "free_x") +
  scale_fill_manual(values = c("Higher at spikes" = "#c0392b",
                               "Lower at spikes"  = "#2980b9")) +
  scale_x_continuous(
    labels = function(x) paste0(sprintf("%.4f", x), "%"),
    expand = expansion(mult = c(0.18, 0.22))
  ) +
  labs(
    #subtitle = "Absolute difference in pooled term frequency: spike minus non-spike (% of total words)",
    x        = "Difference in pooled frequency (spike − non-spike, % of words)",
    caption  = paste0(
      "Notes: Positive = term is proportionally more frequent in the pooled spike corpus.\n",
      "Both periods use total hits / total words in pooled corpus — not averaged monthly rates."
    )
  ) +
  comp_bar_theme

ggsave("plots/spike_terms/comp_diverging_pooled.png", p_diverging_pooled,
       width = 11, height = 6.5, dpi = 300, bg = "white")
p_diverging_pooled
