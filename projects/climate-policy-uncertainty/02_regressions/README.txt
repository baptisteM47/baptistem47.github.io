================================================================================
  README — Event Study Regressions & Endogeneity Checks
  (02_regressions.R)
================================================================================

OVERVIEW
--------
This is the third and final script in the project pipeline. It takes the
CPU index (computed in 01_cpu_index.R) and firm-level stock data as inputs,
and produces all regression results, robustness checks, and output tables.

The script is organized in two main parts:

  PART A — Sections 1–16
    Realized volatility regressions with endogeneity analysis of VIX.
    This is the core empirical exercise and includes the Granger causality
    and VAR diagnostics that motivate the VIX(t-3) specification.

  PART B — Blocks 1–6
    Extended regressions across all four outcome variables (realized
    volatility, abnormal trading volume, first-difference log volume,
    arithmetic returns), with a systematic loop that produces all plots
    and tables in a single run.


--------------------------------------------------------------------------------
INPUTS (must exist before running)
--------------------------------------------------------------------------------
  data/CPU_all_indices.csv         CPU index (from 01_cpu_index.R)
  data/bdd_final.csv               Firm-level daily data
                                   (columns: company_name, sector, date,
                                    VWAP, vix, wti)

  Internet connection required for Part B: tq_get() downloads daily
  price and volume data from Yahoo Finance for the 30 Dow Jones tickers.


--------------------------------------------------------------------------------
OUTPUTS
--------------------------------------------------------------------------------
Data files:
  data/master_firm_monthly.csv     Master panel (firm × month, all variables)

Plots — Part A (realized volatility & endogeneity):
  plots/event_study_realvol_comparison.png        Bivariate: rolling vs local maxima
  plots/event_study_rolling_baseline_vs_vix.png   Rolling: baseline vs VIX
  plots/event_study_localmax_baseline_vs_vix.png  Local maxima: baseline vs VIX
  plots/cpu_vix_crosscorrelation.png              CPU–VIX cross-correlation (±6m)
  plots/event_study_rolling_endogeneity.png       Rolling: 3-spec comparison
  plots/event_study_localmax_endogeneity.png      Local maxima: 3-spec comparison

Tables — Part A:
  plots/table_vix_endogeneity_rolling.tex         3-spec table (rolling)
  plots/table_vix_endogeneity_localmax.tex        3-spec table (local maxima)

Plots — Part B (per outcome variable, saved in plots/<variable>/):
  <method>_<spec>.png        Individual coefficient plot (6 per variable)
  <method>_combined.png      3-spec side-by-side plot   (2 per variable)
  → 8 plots × 4 variables = 32 plots total

Tables — Part B (saved in tables/<variable>/):
  <method>_<spec>.tex        Individual regression table (6 per variable)
  <method>_combined.tex      3-spec combined table       (2 per variable)
  → 8 tables × 4 variables = 32 tables total

  Where <method> ∈ {rolling, localmax} and <spec> ∈ {base, vix, vix3}.

  Output folder structure:
    plots/
      realized_vol/
      abnormal_vol/
      fd_log_volume/
      ar_returns/
    tables/
      realized_vol/
      abnormal_vol/
      fd_log_volume/
      ar_returns/


--------------------------------------------------------------------------------
PART A — SECTION-BY-SECTION GUIDE
--------------------------------------------------------------------------------

SECTION 1 — Load data
  Reads bdd_final.csv and CPU_all_indices.csv into memory.
  Event window is defined as window = -2:2 (±2 months around spike).

SECTION 2 — Compute realized volatility
  Daily return = (VWAP_t − VWAP_{t-1}) / VWAP_{t-1}
  Monthly realized volatility = SD(daily returns within month) × √21
  √21 scales to monthly frequency (≈ 21 trading days per month).
  Result: one row per (company_name, month).

SECTION 3 — Prepare CPU index & detect spikes
  Reloads CPU(t:t-2) from CPU_all_indices.csv (same specification as
  01_cpu_index.R, Section 9). Spike detection is re-run here so this
  script can be executed independently without File 1 in memory.

  Method 1 — Rolling threshold: CPU(t) > roll_mean(12m) + 1.5 × roll_SD(12m)
  Method 2 — Local maxima (preferred): strict local peak above
             global mean + 1.5 × global SD, minimum 5-month gap enforced.

  Produces: spike_dates_rolling, spike_dates_localmax.

SECTION 4 — Build event panels
  Creates one observation per (company × spike × relative time τ).
  Reference period is τ = −2 (two months before spike).
  CPU and realized vol are merged in by (company_name, month).

  Two panels:
    event_panel    — rolling threshold spikes
    event_panel_lm — local maxima spikes (preferred)

SECTION 5 — Bivariate regressions (no controls)
  MODEL: realized_vol_it = Σ β_τ × 1[rel_time = τ] + α_i + ε_it
    - τ ∈ {-1, 0, +1, +2}, reference τ = -2
    - α_i: company fixed effects (absorbed by feols)
    - Standard errors clustered by company
  Run separately for both detection methods.
  Coefficients show whether realized volatility is elevated or depressed
  relative to the pre-spike baseline at each point in the event window.

SECTION 6 — Plot: bivariate comparison (both methods)
  Side-by-side coefficient plots (Panel A = rolling, Panel B = local maxima).
  extract_coefs() appends a zero row at τ = −2 (the omitted reference)
  so the baseline is visible on the chart.
  Saved as: plots/event_study_realvol_comparison.png

SECTION 7 — Add VIX control
  VIX is averaged from daily to monthly (mean of daily observations within
  each calendar month). Merged into both event panels.
  Note on why VIX is problematic: VIX is measured contemporaneously with
  CPU in the same month. If CPU spikes coincide with market-wide stress
  episodes that also drive VIX up, controlling for VIX absorbs part of
  the CPU effect — this is the "bad control" problem. Sections 10–14
  address this formally.

SECTION 8 — Regressions with contemporaneous VIX
  MODEL: realized_vol ~ rel_time + vix | company_name
  This specification is included for comparability with the literature
  but is flagged as potentially biased due to VIX endogeneity.

SECTION 9 — Plot: baseline vs VIX (both methods)
  Compares the bivariate and VIX-controlled coefficient paths side by side,
  separately for each detection method.
  Saved as:
    plots/event_study_rolling_baseline_vs_vix.png
    plots/event_study_localmax_baseline_vs_vix.png

SECTION 10 — Build monthly CPU–VIX time series
  Merges CPU_index and vix_monthly on date/month for the Granger tests.
  Filters to rows where both series are non-missing.

SECTION 11 — Granger causality tests
  Tests two directions using grangertest() with 3 lags:
    H0: CPU does NOT Granger-cause VIX  → reject = CPU predicts future VIX
    H0: VIX does NOT Granger-cause CPU  → reject = VIX predicts future CPU

  If CPU Granger-causes VIX but VIX does not Granger-cause CPU, this
  supports treating contemporaneous VIX as a bad control (it is partially
  caused by CPU, so conditioning on it opens a collider bias).

SECTION 12 — VAR-based Granger causality
  Estimates a bivariate VAR(p) with lag order p selected by AIC (up to 6).
  causality(var_model, cause = "CPU") performs a joint F-test of the null
  that all CPU lags in the VIX equation are zero.

SECTION 13 — Cross-correlation plot
  ccf() computes the sample cross-correlation between CPU and VIX at lags
  −6 to +6. Positive lag k = CPU leads VIX by k months.
  95% confidence bands = ±1.96 / √T under white-noise null.
  Saved as: plots/cpu_vix_crosscorrelation.png

SECTION 14 — Truly predetermined VIX(t-3)
  Given that CPU(t:t-2) averages campaign embeddings over months t, t-1,
  and t-2, the earliest VIX value with NO overlap with CPU's inputs is
  VIX(t-3). This is the first lag that is fully predetermined with respect
  to the CPU construction window.
  VIX(t-3) is computed as lag(vix, 3) within each company's calendar series
  (NOT within the event panel, to avoid within-panel lag contamination).

SECTION 15 — Summary tables: all three VIX specifications
  etable() produces side-by-side LaTeX tables showing:
    Column 1: Baseline (no VIX)
    Column 2: Raw VIX (bad control)
    Column 3: VIX(t-3) (predetermined)
  The key finding: if the rel_time coefficients are stable across columns
  1 and 3, the CPU effect is not driven by common market stress.
  Saved as:
    plots/table_vix_endogeneity_rolling.tex
    plots/table_vix_endogeneity_localmax.tex

SECTION 16 — Three-panel endogeneity plots
  Coefficient plots with three panels side by side (Baseline / Raw VIX /
  VIX(t-3)), separately for each detection method.
  Saved as:
    plots/event_study_rolling_endogeneity.png
    plots/event_study_localmax_endogeneity.png


--------------------------------------------------------------------------------
PART B — BLOCK-BY-BLOCK GUIDE
--------------------------------------------------------------------------------

BLOCK 1 — Build all variables from raw sources

  1a. Ticker map
      A hand-coded 30-ticker Dow Jones panel with company names that match
      the identifiers in bdd_final.csv (ticker_map tibble).

  1b. Download from Yahoo Finance
      tq_get() downloads daily open/high/low/close/volume from Yahoo Finance
      starting November 2015 (14 months before the analysis window) so that
      the 12-month rolling mean for abnormal volume is fully populated by
      January 2017.

  1c. Daily returns & realized volatility (from VWAP)
      Uses bdd_final.csv VWAP for consistency with Part A. Produces:
        realized_vol_m   — monthly SD of daily VWAP returns × √21
        ar_returns_m     — (last VWAP − first VWAP) / first VWAP per month

  1d. Volume variables (from Yahoo Finance)
      For each ticker and month:
        log_volume    = log(mean daily volume + 1)
        vol_roll_mean = 12-month right-aligned rolling mean of log_volume
        abnormal_vol  = log_volume − lag(vol_roll_mean)
                        [deviation of current log volume from past year average]
        fd_log_volume = log_volume − lag(log_volume)
                        [month-on-month log change in volume]

      IMPORTANT: the rolling mean uses the extended download (from Nov 2015)
      so that abnormal_vol has no NAs from January 2017 onward. A coverage
      check is printed to the console to confirm this.

BLOCK 2 — Merge into master dataframe & save
  full_join across all variable sources ensures no observations are
  silently dropped. A company coverage check compares companies in
  bdd_final.csv against companies in master_df and prints any mismatches.
  Filtered to month >= 2017-01-01 before saving.
  Saved as: data/master_firm_monthly.csv

BLOCK 3 — Build event panels
  VIX(t-3) is computed on the calendar-level vix_monthly series (lag(vix, 3))
  before merging into the event panel. This is critical: computing lag()
  inside the event panel would use within-panel row ordering (which is not
  the calendar sequence) and would produce incorrect lags.
  build_event_panel() is a reusable function that constructs the full
  event panel for any set of spike dates and merges all outcomes, CPU,
  VIX, and VIX(t-3) in one step.

BLOCK 4 — All regressions
  Three specifications × two detection methods × four outcome variables
  = 24 regressions, stored in a nested list regs[[var]][[method]][[spec]].
  All regressions use company fixed effects (feols) with standard errors
  clustered by company. The three specifications are:
    base: y ~ rel_time | company_name
    vix:  y ~ rel_time + vix | company_name
    vix3: y ~ rel_time + vix_lag3 | company_name

BLOCK 5 — Plots
  Two plot types per variable × detection method:
    single_coef_plot()    — one model, with 95% CI ribbon + error bars
    combined_coef_plot()  — three specs faceted side by side (3 panels)
  Saved into plots/<variable>/ with filenames <method>_<spec>.png and
  <method>_combined.png.

BLOCK 6 — Tables
  etable() (fixest) produces LaTeX regression tables for each model and
  each combined 3-spec comparison. Saved into tables/<variable>/.


--------------------------------------------------------------------------------
REGRESSION DESIGN DECISIONS
--------------------------------------------------------------------------------

Reference period (τ = −2)
  The event window runs from τ = −2 to τ = +2. Using τ = −2 as the
  omitted reference (rather than τ = −1 or an average of the pre-period)
  allows the full pre-spike trend to be visible in the coefficient plot.
  A flat pre-spike path (β_{-1} ≈ 0 relative to β_{-2} = 0) supports the
  parallel-trends assumption analogous to difference-in-differences.

Company fixed effects only
  Month fixed effects are deliberately excluded. Including them would absorb
  all cross-sectional variation at each point in the event window, leaving
  only within-firm variation — which is conceptually different from the
  event study question (how does the average firm respond to CPU spikes?).
  The VIX control absorbs aggregate market conditions as a time-varying
  control instead.

Clustering by company
  Residuals within a firm are likely serially correlated across spike
  episodes. Clustering by company accounts for this without requiring
  assumptions about the error structure across time.

VIX(t-3) as the predetermined lag
  CPU(t:t-2) uses information from months t, t-1, and t-2. The first VIX
  observation with zero information overlap is VIX(t-3). Using VIX(t-1)
  or VIX(t-2) would still be partially endogenous because those months
  are inputs to CPU's construction. VIX(t-3) eliminates this overlap
  entirely by construction.

Abnormal volume baseline
  The rolling mean uses a 12-month right-aligned window, meaning it is
  estimated from the prior 12 months only (no look-ahead). The 14-month
  download pre-period ensures this mean is fully estimated at the start
  of the analysis window (January 2017) without any NAs.

Arithmetic returns (not log returns)
  Monthly price moves in this panel are large enough that log and arithmetic
  returns diverge meaningfully. Arithmetic returns are used because they
  are directly interpretable as percentage gains and losses, and because
  the event study regression coefficients then have a natural percentage-
  point interpretation.


--------------------------------------------------------------------------------
DEPENDENCIES
--------------------------------------------------------------------------------
R packages required:
  tidyverse, lubridate, zoo, fixest, lmtest, vars, tidyquant, broom

Install missing packages with:
  install.packages(c("tidyverse", "lubridate", "zoo", "fixest",
                     "lmtest", "vars", "tidyquant", "broom"))

Note: tidyquant requires an internet connection at runtime for tq_get().
If running offline, replace tq_get() with a local CSV of daily price/volume
data and comment out Block 1b.


--------------------------------------------------------------------------------
EXECUTION ORDER
--------------------------------------------------------------------------------
  Step 1: 00_data_preparation.R  -->  APP_climate.csv, legi_climate_dataset.csv
  Step 2: 01_cpu_index.R         -->  CPU_all_indices.csv, spike detection
  Step 3: 02_regressions.R       --> all regression outputs (this script)

Sections 1–3 of this script re-run spike detection from scratch so that
Part A can be executed without File 1 in memory (only CPU_all_indices.csv
and bdd_final.csv are required on disk).


--------------------------------------------------------------------------------
RUNTIME NOTES
--------------------------------------------------------------------------------
- tq_get() in Block 1b downloads data for 30 tickers and may take 1–3
  minutes depending on connection speed. Yahoo Finance rate limits
  occasional requests; retry if the download fails.

- The regression loop in Block 4 runs 24 feols() calls. This is fast
  (typically < 30 seconds total) since feols uses the Frisch-Waugh-
  Lovell theorem internally for FE absorption.

- The plot and table loops in Blocks 5–6 each write 32 files to disk.
  On slow storage this may take a minute or two.

- If bdd_final.csv uses different company_name values than the ticker_map
  in Block 1a, the volume variables will have NAs for unmatched companies.
  The coverage check at the end of Block 2 will print any mismatches.

================================================================================
