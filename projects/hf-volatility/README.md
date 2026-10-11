# Trading activity and S&P 500 intraday volatility

Financial econometrics, M2, 2026-04. With Victoria Godio, Raphaël Perilhou, Toulouse School of Economics.

**R² 0.22** out of sample for GARCH, the best model

## Question

Do high-frequency data and activity variables (volume, trade count) improve volatility forecasts over a GARCH(1,1)?

## Method

One-minute S&P 500 data. Sampling frequency chosen with a signature plot, realized volatility computed, then GARCH(1,1), HAR-RV and HAR-RV-X (with volume and trades) compared in and out of sample. Robustness: intraday HAR on 30-minute blocks.

## Results

- GARCH(1,1) forecasts better than the HAR models over 66 trading days
- Adding volume and trades does not improve forecasts
- With an intraday HAR (650 observations), components become significant and out-of-sample R² reaches 0.11: the weakness comes mostly from sample size

## Links

- [Project page on the CV](https://baptistem47.github.io/#p-hf-volatility)
- [Report (PDF)](https://baptistem47.github.io/projects/hf-volatility/report.pdf)
- [Code](https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/hf-volatility/Code_HF_Project.R)
- [Data](https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/hf-volatility/data)

## Files

- `Code_HF_Project.R`
- `data/`
  - `SP500_1_min.csv`
- `figures/`
  - `acf_plot.png`
  - `distribution_RV.png`
  - `forecast_comparison.png`
  - `insample_fit.png`
  - `signature_plot.png`
  - `variance_comparison.png`
- `report.pdf`
- `tables/`
  - `table_activity.tex`
  - `table_garch.tex`
  - `table_insample.tex`
