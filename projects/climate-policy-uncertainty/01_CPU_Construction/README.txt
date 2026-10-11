================================================================================
  README — CPU Index Construction, Spike Detection & Descriptive Analysis
  (01_cpu_index.R)
================================================================================

WARNING

- The GloVe file loading uses fread to gain some time but it can still be time consuming.

OVERVIEW
--------

This code does six things:

  1. Builds 100-dimensional GloVe document embeddings for monthly campaign
     materials (APP) and legislative texts (BILLS).
  2. Computes four variants of the CPU index (different lag windows).
  3. Detects spike events using two methods (rolling threshold; local maxima).
  4. Produces all CPU time series and event study plots (only on CPU itself, regression on other code).
  5. Runs descriptive text analyses around spike episodes.
  6. Produces per-company VWAP and realized volatility time series with
     CPU spike markers overlaid.

PREFERRED SPECIFICATION: CPU(t:t-2) — 3-month averaging window on campaign
materials — detected with the local maxima method.

--------------------------------------------------------------------------------
INPUTS (must exist before running)
--------------------------------------------------------------------------------
  data/APP_climate.csv             Campaign materials (from 00_data_preparation.R)
  data/legi_climate_dataset.csv    Legislative texts  (from 00_data_preparation.R)
  data/glove.2024.wikigiga.100d.txt  Pre-trained GloVe word vectors (100-dim)
  data/bdd_final.csv               Stock-level dataset (company, sector, date, VWAP)


--------------------------------------------------------------------------------
OUTPUTS
--------------------------------------------------------------------------------
Data files:
  data/CPU_all_indices.csv         All 4 CPU variants (wide format, monthly)
  data/spike_episode_summary.csv   Per-spike: date, CPU level, doc counts

Plots — CPU time series:
  plots/CPU_all_lags.png                     Raw CPU (4 lag variants, 2×2)
  plots/CPU_all_lags_rolling.png             CPU with rolling-threshold spikes
  plots/CPU_all_lags_localmax.png            CPU with local-maxima spikes

Plots — Event studies on CPU itself:
  plots/CPU_event_study_rolling.png          Mean CPU ±2m window (rolling, 2×2)
  plots/CPU_event_study_localmax.png         Mean CPU ±2m window (local max, 2×2)
  plots/CPU_event_study_comparison_cpu2.png  CPU(t:t-2), both methods side-by-side

Plots — Descriptive text analyses (Section 13):
  plots/text_volume_heatmap.png              Word count heatmap around spikes
  plots/climate_intensity_ts.png             Climate dictionary share over time
  plots/spike_terms/top20_raw_YYYY_MM.png    Top-20 terms per spike (raw count)
  plots/spike_terms/top20_norm_YYYY_MM.png   Top-20 terms per spike (per 1000 words)
  plots/spike_terms/top20_agg_raw.png        Aggregated top-20 across all spikes
  plots/spike_terms/top20_agg_norm.png       Aggregated top-20 (normalized)
  plots/spike_terms/comp_pct_pooled.png      Pooled % of words: spike vs non-spike
  plots/spike_terms/comp_rel_freq_pooled.png Relative frequency: spike / non-spike
  plots/spike_terms/comp_diverging_pooled.png Diverging bar: spike minus non-spike

Tables:
  tables/climate_intensity_summary.tex       LaTeX descriptive stats table


--------------------------------------------------------------------------------
SECTION-BY-SECTION GUIDE
--------------------------------------------------------------------------------

SECTION 1 — Load and aggregate text data
  Reads APP_climate.csv and legi_climate_dataset.csv.
  Aggregates both to monthly level by concatenating all texts within each
  month into a single document. Result: one document per month per source
  (APP_m, BILLS_m).

SECTION 2 — Build GloVe document embeddings
  Loads pre-trained GloVe vectors (100 dimensions per word).
  Builds a joint vocabulary across APP and BILLS, excluding stopwords and
  words absent from the GloVe file.
  Represents each monthly document as the unweighted average of its
  constituent word vectors → one 100-dim vector per document-month.
  doc_embedding() handles missing words gracefully (returns zero vector).

SECTION 3 — Compute CPU index variants
  CPU(t) = 1 − cosine_similarity(APP_embedding, BILLS_embedding)
  High CPU = campaign rhetoric diverges from legislative language.
  Low CPU  = campaign promises align with what is being legislated.

  Four lag variants are computed, averaging the APP embedding over:
    CPU(t)      — current month only              [no smoothing]
    CPU(t:t-1)  — current + 1 prior month         [2-month window]
    CPU(t:t-2)  — current + 2 prior months        [3-month window, PREFERRED]
    CPU(t:t-3)  — current + 3 prior months        [4-month window]

  All variants start from 2017-01-01 (enough history for the longest lag).

SECTION 4 — Summary statistics
  For each variant: mean, median, SD, min, max printed as LaTeX tables
  via stargazer(). A standardized z-score column (CPU_z) is also added.

SECTION 5 — Raw CPU time series plot
  2×2 faceted ggplot showing all four variants over time (no spikes).
  Saved as CPU_all_lags.png.

SECTION 6 — Save CPU indices to disk
  Merges all four variants into CPU_all_indices.csv (wide format).
  Column naming convention:
    CPU_0 / CPU_z0    → CPU(t)      (no lag)
    CPU_1 / CPU_z_1   → CPU(t:t-1)
    CPU_2 / CPU_z_2   → CPU(t:t-2)  ← used in all downstream analyses
    CPU_3 / CPU_z_3   → CPU(t:t-3)
  This file is read by the regression scripts so embeddings need not be
  recomputed each time.

SECTION 7 — Spike detection: Method 1 (Rolling threshold)
  A month is a candidate spike if:
    CPU(t) > rolling_mean(12 months) + 1.5 × rolling_SD(12 months)
  Rolling window is right-aligned (only past data used → no look-ahead).
  Consecutive candidate months are clustered; only the peak within each
  cluster is retained. A minimum 5-month gap between retained spikes is
  enforced to prevent overlapping event windows.
  Implemented in get_spikes_rolling().

SECTION 8 — Spike detection: Method 2 (Local maxima) [PREFERRED]
  A month is a candidate spike if:
    (a) CPU(t) > CPU(t-1) AND CPU(t) > CPU(t+1)  [strict local maximum]
    (b) CPU(t) > global mean + 1.5 × global SD    [above global threshold]
  If two candidates are within the 5-month minimum gap, the higher one is
  kept unless the later one is more than 20% higher (then it replaces).
  Implemented in detect_spikes_localmax() / get_spikes_localmax().

  Preferred over rolling threshold because:
    - Identifies genuine peaks, not high-but-flat regimes
    - Not sensitive to the rolling window length parameter
    - More intuitive: a spike is a visible peak in the series

SECTION 9 — Apply detection to CPU(t:t-2)
  Reloads CPU_all_indices.csv (so this section can be run independently).
  Applies both detection methods to the preferred CPU(t:t-2) series.
  Results stored as:
    spike_dates_rolling   — Method 1 dates
    spike_dates_localmax  — Method 2 dates (used in all downstream sections)

SECTIONS 10–11 — CPU plots with spike markers
  2×2 faceted plots for all four lag variants showing detected spike
  episodes as red dots and dashed vertical lines.

SECTION 12 — Event study on CPU itself
  Before examining any outcome variable, we verify that the detected spikes
  exhibit the expected inverted-V pattern in the CPU series itself.
  stack_event_window() pools all spike episodes and computes mean CPU ±
  standard error at each relative time τ ∈ {−2, −1, 0, +1, +2}.
  Three output figures:
    12a. Rolling method — 2×2 across all lag variants
    12b. Local maxima   — 2×2 across all lag variants
    12c. CPU(t:t-2) only — both methods side by side (main paper figure)

SECTION 13a — Text volume heatmap
  For each spike episode, counts total words in APP and BILLS at each
  relative month τ ∈ {−2, …, +2}. Displayed as a heatmap (rows = spike
  episodes, columns = relative time, fill = word count). Checks whether
  text production volume is itself unusual around spikes.

SECTION 13b — Climate dictionary intensity
  Counts occurrences of all terms from the Gavriilidis (2023) climate
  dictionary in each monthly corpus and normalizes by total word count
  (share of words). Produces:
    - Descriptive stats table (LaTeX, via kableExtra)
    - Time series of climate intensity with spike markers overlaid
  This complements the CPU index: CPU measures divergence between corpora;
  dictionary intensity measures raw salience of climate topics within them.

SECTION 13c — Top-20 terms at each spike month
  For each spike month, counts individual dictionary term occurrences in
  APP and BILLS separately. Produces per-spike horizontal bar charts
  showing the top-20 terms by both raw count and per-1000-word rate.
  Also produces aggregated versions averaging across all spike months.
  Saved to plots/spike_terms/.

SECTION 13d — Spike vs non-spike pooled frequency comparison
  Rather than averaging monthly rates (which is sensitive to unequal document
  volume across months), pools all text within spike months and all text within
  non-spike months separately, then computes term frequency on the pooled corpus.
  Three comparison plots:
    - Side-by-side bars: pooled % of words at spike vs non-spike months
    - Relative frequency: spike % / non-spike %  (ratio > 1 = more at spikes)
    - Diverging bars: spike − non-spike difference in pooled %

VWAP section — Per-company stock price time series
  Reads data/bdd_final.csv. Aggregates daily VWAP to monthly mean.
  Plots each company's VWAP over time with:
    - Mean ± 1 SD reference lines
    - CPU spike dates as vertical red dashed lines
    - Date labels at spike positions
    - Stats annotation box (n, mean, SD, spike count)
  Saves one PNG per company to plots/vwap_monthly/.

Realized Volatility section — Per-company volatility time series
  Computes monthly realized volatility as:
    RV(month) = SD(daily VWAP simple returns within month) × √21
  Produces the same layout as the VWAP plots (green color scheme) with
  CPU spike markers overlaid. Saves to plots/rv_monthly/.


--------------------------------------------------------------------------------
KEY DESIGN DECISIONS
--------------------------------------------------------------------------------
Embedding strategy
  Simple unweighted average of word vectors (no TF-IDF weighting). This
  is intentional: we want to capture the average semantic direction of the
  discourse, not to upweight rare technical terms. 

Preferred lag window (CPU t:t-2)
  The 3-month averaging window smooths month-to-month noise in campaign
  materials (press releases, speeches) while remaining responsive enough
  to detect meaningful shifts in discourse. Robustness checks with t, t:t-1,
  and t:t-3 are retained throughout the script.

Minimum spike gap (5 months)
  Ensures that the ±2 month event windows around adjacent spikes do not
  overlap, which would bias the event study averages.

Pooled vs averaged frequency (Section 13d)
  Averaging monthly per-1000-word rates gives equal weight to all months
  regardless of document volume. Pooling instead weights each month by its
  word count, which is more appropriate when some months contain far more
  text than others (e.g., months with major legislative activity).

Realized volatility annualization
  ×√21 assumes approximately 21 trading days per month. The result is a
  monthly realized volatility expressed at a monthly frequency (not
  annualized to avoid confusion in the plots).


--------------------------------------------------------------------------------
DEPENDENCIES
--------------------------------------------------------------------------------
R packages required:
  text2vec, tidyverse, lubridate, data.table, stopwords,
  stargazer, ggplot2, zoo, stringi, kableExtra

Install missing packages with:
  install.packages(c("text2vec", "tidyverse", "lubridate", "data.table",
                     "stopwords", "stargazer", "ggplot2", "zoo",
                     "stringi", "kableExtra"))

External data:
  GloVe vectors: glove.2024.wikigiga.100d.txt must be placed in data/.
  The file has no header; column 1 = word, columns 2–101 = vector dimensions.



================================================================================
