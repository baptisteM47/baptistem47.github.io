================================================================================
  README — Empirical Project 
================================================================================

OVERVIEW
--------
This project constructs a Climate Policy Uncertainty (CPU) index based on
the semantic distance between U.S. campaign materials and legislative texts,
and studies its effect on firm-level stock market outcomes using an event
study design.

In this folder you will find 4 subfolders, each corresponding to one stage
of the empirical pipeline. Each subfolder contains its own README.txt with
full documentation, as well as all scripts, data, plots, and tables relevant
to that stage.

The cleaned data files are provided in each subfolder, so any step can be run independently without executing the prior ones. However, each script must be opened and run from within its own subfolder  (R sets the working directory relative to the open file's location). If a script from a later step (e.g., 02_regressions) is opened while a script from an earlier step (e.g., 01_CPU_construction) is still active in the same R session, the working directory will point to the wrong folder and the data files will not be found. To avoid this, always close the current script and restart the R session before opening a script from a different subfolder.

--------------------------------------------------------------------------------
FOLDER STRUCTURE
--------------------------------------------------------------------------------

  00_XML_cleaning/
    Parses raw XML files from the U.S. Congress bill repository and the
    American Presidency Project. Applies a climate dictionary to filter
    documents to climate-relevant texts only. Outputs the two core text
    datasets used to build the CPU index:
      - legi_climate_dataset.csv   (legislative texts)
      - APP_climate.csv            (campaign / policy intent documents)

  00bis_Descriptive/
    Loads and cleans the firm-level stock panel (30 Dow Jones companies).
    Downloads supplementary price and volume data from Yahoo Finance.
    Constructs the main outcome variables (VWAP returns, realized
    volatility, abnormal trading volume). Produces all descriptive
    statistics tables and per-company distribution and time series plots.

  01_CPU_construction/
    Builds GloVe document embeddings from the climate text datasets and
    computes the CPU index as the monthly cosine distance between campaign
    and legislative embeddings. Detects spike events using two methods
    (rolling threshold and local maxima). Produces all CPU time series
    plots, event study diagnostics on the CPU itself, and descriptive
    text analyses around spike episodes.

  02_regressions/
    Runs all event study regressions of firm-level outcomes on CPU spike
    indicators. Includes endogeneity checks (Granger causality, VAR, cross-
    correlation) to assess whether VIX is a valid control. Produces all
    regression coefficient plots and LaTeX tables across four outcome
    variables and three specifications.


See the README.txt inside each subfolder for detailed instructions.

================================================================================