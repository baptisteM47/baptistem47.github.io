# Baptiste Messant, interactive CV

Source of [baptistem47.github.io](https://baptistem47.github.io): a bilingual (French / English) interactive CV, with every research project carried out at Toulouse School of Economics, including reports, code and data.

## Structure

| Path | Content |
|---|---|
| `index.html` | The single page of the CV |
| `assets/data.js` | **All the CV content** (profile, experience, projects, skills, education) in French and English. Edit this file to update the site. |
| `assets/app.js` | Interactions: language switch, project filters, skill filters, project details, light / dark theme |
| `assets/style.css` | Styles, including the print layout used by the "Download as PDF" button |
| `projects/` | One folder per project, each with its own README, report, code and data |
| `fr/`, `en/`, `Scoring_project/`, `Python_project/` | Redirects that keep the old links working |

## Projects

| Folder | Project |
|---|---|
| [`climate-policy-uncertainty`](projects/climate-policy-uncertainty) | Climate policy uncertainty and stock markets (Master 2 thesis) |
| [`hf-volatility`](projects/hf-volatility) | Trading activity and S&P 500 intraday volatility |
| [`credit-scoring`](projects/credit-scoring) | Predicting defaults among hotel and restaurant firms |
| [`extreme-value-census`](projects/extreme-value-census) | Extreme values: the size of U.S. cities |
| [`econometrics-methods`](projects/econometrics-methods) | VaR backtesting, Heckman model and GMM |
| [`euro-yield-curve`](projects/euro-yield-curve) | Macro shocks and the euro area yield curve |
| [`government-spending-svar`](projects/government-spending-svar) | Government spending and activity: a SVAR analysis |
| [`nh1-cost-benefit`](projects/nh1-cost-benefit) | Cost-benefit analysis of the NH1 tidal farm |
| [`mental-health-us`](projects/mental-health-us) | Anxiety, depression and socio-economic factors in the U.S. |

Two large intermediate datasets of the thesis (`APP_climate.csv`, 51 MB, and `bdd_final.csv`, 9 MB) are not included; the scripts that produce them are.

## Updating the site

1. Edit the text in `assets/data.js` (each entry has an `fr` and an `en` version).
2. To add a project, create a folder in `projects/` and add an entry to `PROJECTS` in `assets/data.js`.
3. Commit and push: GitHub Pages republishes the site within a minute.

To preview locally: `python3 -m http.server` in this folder, then open http://localhost:8000.
