# Climate policy uncertainty and stock markets

Master 2 thesis, 2026-03. With Victoria Godio, Raphaël Perilhou, Toulouse School of Economics.

**30** Dow Jones stocks, 2017 to 2025

## Question

When the gap between climate campaign pledges and legislation widens, how do stock returns, volatility and trading volumes react?

## Method

Built an original uncertainty index (CPU) from text: semantic distance (GloVe embeddings) between U.S. campaign documents and Congressional bills. Detected spikes, then ran a stacked event study on the 30 Dow Jones stocks, with VIX endogeneity checks (Granger, VAR).

## Results

- The return premium rises in the month before a spike, then falls at the spike date
- Realized volatility drops significantly and persistently after a spike, consistent with wait-and-see behaviour
- Trading volume rises around the spike, while abnormal volume falls afterwards

## Links

- [Project page on the CV](https://baptistem47.github.io/#p-climate-policy-uncertainty)
- [Report (PDF)](https://baptistem47.github.io/projects/climate-policy-uncertainty/report.pdf)
- [Slides (PDF)](https://baptistem47.github.io/projects/climate-policy-uncertainty/slides.pdf)
- [Code](https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/climate-policy-uncertainty)

## Files

- `00_XML_Cleaning/`
  - `00_XML_cleaning.R`
  - `Images/`
  - `README.txt`
- `00_descriptive_financial/`
  - `00bis_descriptive.R`
  - `README.txt`
  - `data/`
  - `plots/`
- `01_CPU_Construction/`
  - `01_CPU_construction.R`
  - `README.txt`
  - `data/`
  - `plots/`
  - `tables/`
- `02_regressions/`
  - `02_regressions.R`
  - `README.txt`
  - `data/`
  - `plots/`
  - `tables/`
- `README.txt`
- `report.pdf`
- `slides.pdf`
