# Predicting defaults among hotel and restaurant firms

Scoring, M2, 2026-02. With Victoria Godio, Raphaël Perilhou, Toulouse School of Economics.

**AUC 0.95** for XGBoost on the test set

## Question

Can we predict defaults among French accommodation and food service firms (2017–2021), a sector hit hard by the pandemic, from their financial statements?

## Method

Merged three databases (BODACC for defaults, INPI for accounts, NAF for sector). Missing values and winsorisation, PCA and discriminant analysis, then LASSO, decision trees and XGBoost (540 hyperparameter combinations) with a train / validation / test split.

## Results

- XGBoost leads with an AUC of 0.95, against 0.88 for the decision tree and 0.86 for LASSO
- Higher turnover goes with fewer defaults, longer customer payment terms with more
- Known limit: with highly imbalanced classes, AUC alone can overstate the model's practical value

## Links

- [Project page on the CV](https://baptistem47.github.io/#p-credit-scoring)
- [Interactive report](https://baptistem47.github.io/projects/credit-scoring/report/)
- [Code](https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/credit-scoring/SF_EDA_ANALYSIS.qmd)

## Files

- `SF_EDA_ANALYSIS.qmd`
- `references_scoring.bib`
- `report/`
  - `SF_EDA_ANALYSIS_files/`
  - `index.html`
