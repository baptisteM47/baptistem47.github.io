================================================================================
  README —  Descriptive Statistics
  (00bis_descriptive_financial.R)
 
================================================================================

OVERVIEW
--------

This script does four things:

  1. Loads and cleans the 30-company panel from a local Excel file and
     merges in VIX and WTI price data.
  2. Downloads supplementary daily price and volume data from Yahoo Finance
     via tidyquant and constructs additional variables (realized volatility,
     abnormal trading volume).
  3. Produces descriptive statistics tables (LaTeX via xtable).
  4. Produces per-company distribution and time series plots for all
     three main outcome variables: VWAP returns, abnormal volume, and
     realized volatility.


--------------------------------------------------------------------------------
INPUTS
--------------------------------------------------------------------------------
  data/DATA_company.xlsx     Main panel — 30 Excel sheets, one per company.
                             Each sheet contains daily VWAP, employees, R&D,
                             capital expenditure, total assets, historical
                             volatility, debt/equity, CO2 emissions, and
                             green revenue share.
  data/VIXCLS.xlsx           CBOE VIX daily index.
  data/WTI.xlsx              WTI crude oil daily price (5 header rows skipped).

  Internet connection required: tq_get() downloads supplementary daily
  price and volume data from Yahoo Finance for all 30 tickers.


--------------------------------------------------------------------------------
OUTPUTS
--------------------------------------------------------------------------------
Console / LaTeX:
  Descriptive statistics table printed via xtable() for three variables:
  VWAP returns, realized volatility, abnormal volume.
  Label: tab:desc_company

Plots — VWAP returns:
  plots/vwap_return_plots/VWAP_Return_<company>.png
    Distribution: histogram + KDE + normal fit + mean/median lines
    One plot per company (30 total)

  plots/vwap_logreturn_timeseries_monthly/VWAP_Return_Monthly_<company>.png
    Monthly bar chart of summed daily VWAP returns, coloured by sign
    One plot per company (30 total)

Plots — Abnormal trading volume:
  plots/volume_plots/Volume_<company>.png
    Distribution: histogram + KDE + normal fit + mean/median lines
    One plot per company (30 total)

  plots/volume_timeseries_monthly/Volume_Monthly_<company>.png
    Monthly bar chart of summed daily abnormal volume, bars above/below mean
    One plot per company (30 total)

Plots — Realized volatility:
  plots/realized_vol_plots/RealizedVol_<company>.png
    Distribution: histogram + KDE + normal fit + mean/median lines
    One plot per company (30 total)

  plots/realized_vol_timeseries_monthly/RealizedVol_Monthly_<company>.png
    Monthly bar chart of mean daily realized vol, bars above/below mean
    One plot per company (30 total)

  Total: 180 PNG files across 6 subdirectories.

In-memory object passed to downstream scripts:
  bdd_final_clean    Master firm-level daily dataset (all variables merged)