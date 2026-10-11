# Macro shocks and the euro area yield curve

Python project, M2, 2025-12. With Victoria Godio, Toulouse School of Economics.

**6,732** daily observations, 14 ECB and Eurostat sources

## Question

How do monetary policy, GDP, consumption, investment and inflation move the euro area zero-coupon curve, maturity by maturity?

## Method

Merged 14 datasets with different frequencies (1997–2025). Explored curves and crises, extracted level, slope and curvature factors (Diebold and Li), then OLS regressions with a one-month lag.

## Results

- The ECB deposit rate mainly moves slope and curvature, not long rates
- Inflation (HICP) affects the level of the curve, at the 10% level
- Inverted curve observed in summer 2024, with a deposit rate around 4%

## Links

- [Project page on the CV](https://baptistem47.github.io/#p-euro-yield-curve)
- [Interactive report](https://baptistem47.github.io/projects/euro-yield-curve/)
- [Code](https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/euro-yield-curve/python_project.qmd)
- [Data](https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/euro-yield-curve/data.csv)

## Files

- `data.csv`
- `index.html`
- `python_project.qmd`
- `python_project_files/`
  - `figure-html/`
  - `libs/`
- `references.bib`
