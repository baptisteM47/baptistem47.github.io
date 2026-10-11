/* Contenu du CV — modifier ce fichier pour mettre à jour le site.
   Chaque texte existe en deux versions : fr et en. */

const REPO = "https://github.com/baptisteM47/baptistem47.github.io/blob/main/";

const PROFILE = {
  name: "Baptiste Messant",
  role: { fr: "Analyste risque de marché", en: "Market risk analyst" },
  pitch: {
    fr: "Diplômé du Master Economics of Global Risks de la Toulouse School of Economics. Six mois en risque de marché énergie chez IDEX (gaz, électricité, garanties d'origine) : suivi des positions, risque de contrepartie, reportings Excel / VBA / SQL.",
    en: "Graduate of the Economics of Global Risks master's at Toulouse School of Economics. Six months in energy market risk at IDEX (gas, power, guarantees of origin): position monitoring, counterparty risk, Excel / VBA / SQL reporting."
  },
  availability: {
    fr: "Je cherche un poste en risque de marché à partir d'octobre 2026.",
    en: "Looking for a market risk role from October 2026."
  },
  links: [
    { id: "linkedin", label: "LinkedIn", url: "https://www.linkedin.com/in/baptiste-messant/" },
    { id: "github", label: "GitHub", url: "https://github.com/baptisteM47" }
  ]
};

/* Points de la courbe de parcours (année décimale, hauteur relative 0–1) */
const CAREER = [
  { t: 2021.7, y: 0.10, label: { fr: "Licence d'économie, TSE", en: "Economics degree, TSE" }, target: "education" },
  { t: 2024.7, y: 0.42, label: { fr: "Master 1, TSE", en: "Master 1, TSE" }, target: "education" },
  { t: 2025.4, y: 0.52, label: { fr: "Stage Midi2i", en: "Midi2i internship" }, target: "experience" },
  { t: 2025.7, y: 0.68, label: { fr: "Master 2 Global Risks", en: "Master 2 Global Risks" }, target: "education" },
  { t: 2026.3, y: 0.80, label: { fr: "Stage IDEX, risque énergie", en: "IDEX internship, energy risk" }, target: "experience" },
  { t: 2026.8, y: 0.90, label: { fr: "Disponible", en: "Available" }, target: "contact", open: true }
];

const EXPERIENCE = [
  {
    period: "2026",
    company: "IDEX",
    kind: { fr: "Énergie", en: "Energy" },
    title: { fr: "Risk manager (stage)", en: "Risk manager (internship)" },
    bullets: {
      fr: [
        "Analyse quotidienne des positions de marché : exposition et volatilité",
        "Gestion des risques de marché énergie (gaz, électricité, garanties d'origine) et du risque de contrepartie",
        "Développement de reportings de risque sous Excel, VBA et SQL",
        "Reportings de risque de marché quotidiens et hebdomadaires",
        "Contrôle quotidien de l'activité de trading et des opérations de marché"
      ],
      en: [
        "Daily analysis of market positions: exposure and volatility",
        "Energy market risk (gas, power, guarantees of origin) and counterparty risk management",
        "Built risk reports in Excel, VBA and SQL",
        "Daily and weekly market risk reporting",
        "Daily control of trading activity and market operations"
      ]
    },
    skills: ["excel", "vba", "sql", "market-risk", "counterparty"]
  },
  {
    period: "2025",
    company: "Midi2i",
    kind: { fr: "Fonds d'investissement", en: "Investment fund" },
    title: { fr: "Analyste en gestion des risques (stage)", en: "Risk management analyst (internship)" },
    bullets: {
      fr: [
        "Découverte de l'ensemble du département financier : gestion de fonds et d'actifs, méthodes de calcul des portefeuilles clients",
        "Contrôles qualité des données réglementaires AMF et maîtrise des risques de diffusion des données",
        "Analyse de données pour fiabiliser la gestion des données et automatiser des tâches financières"
      ],
      en: [
        "Rotation across the finance department: fund and asset management, client portfolio calculation methods",
        "AMF regulatory data quality checks and control of data dissemination risk",
        "Data analysis to make data management more reliable and automate finance tasks"
      ]
    },
    skills: ["excel", "regulation"]
  }
];

const SUMMER_JOBS = [
  { year: "2024", fr: "Préparateur de commandes, Leclerc Drive Brugières", en: "Order picker, Leclerc Drive Brugières" },
  { year: "2023", fr: "Plongeur, Les Terrasses de l'Atelier", en: "Dishwasher, Les Terrasses de l'Atelier" },
  { year: "2022", fr: "Caissier, Leclerc Saint-Orens", en: "Cashier, Leclerc Saint-Orens" },
  { year: "2021", fr: "Caissier et préparateur de commandes, Leclerc Saint-Orens", en: "Cashier and order picker, Leclerc Saint-Orens" },
  { year: "2020", fr: "Agent d'entrepôt, Logipharma", en: "Warehouse worker, Logipharma" }
];

/* Compétences : chaque id est relié aux projets qui l'utilisent */
const SKILL_GROUPS = [
  {
    name: { fr: "Risque et finance", en: "Risk and finance" },
    items: [
      { id: "market-risk", fr: "Risque de marché", en: "Market risk" },
      { id: "var", fr: "Value at Risk et backtesting", en: "Value at Risk and backtesting" },
      { id: "volatility", fr: "Modèles de volatilité (GARCH, HAR)", en: "Volatility models (GARCH, HAR)" },
      { id: "evt", fr: "Théorie des valeurs extrêmes", en: "Extreme value theory" },
      { id: "credit", fr: "Risque de crédit et scoring", en: "Credit risk and scoring" },
      { id: "counterparty", fr: "Risque de contrepartie", en: "Counterparty risk" },
      { id: "rates", fr: "Courbe des taux", en: "Yield curve" },
      { id: "npv", fr: "VAN et simulation Monte Carlo", en: "NPV and Monte Carlo simulation" },
      { id: "regulation", fr: "Données réglementaires (AMF)", en: "Regulatory data (AMF)" }
    ]
  },
  {
    name: { fr: "Économétrie et data", en: "Econometrics and data" },
    items: [
      { id: "timeseries", fr: "Séries temporelles, VAR / SVAR", en: "Time series, VAR / SVAR" },
      { id: "event-study", fr: "Études d'événements", en: "Event studies" },
      { id: "ml", fr: "Machine learning (LASSO, arbres, XGBoost)", en: "Machine learning (LASSO, trees, XGBoost)" },
      { id: "nlp", fr: "Analyse de texte (NLP)", en: "Text analysis (NLP)" },
      { id: "micro-econometrics", fr: "Probit, Heckman, GMM", en: "Probit, Heckman, GMM" }
    ]
  },
  {
    name: { fr: "Outils", en: "Tools" },
    items: [
      { id: "r", fr: "R", en: "R" },
      { id: "python", fr: "Python", en: "Python" },
      { id: "sql", fr: "SQL", en: "SQL" },
      { id: "vba", fr: "VBA", en: "VBA" },
      { id: "excel", fr: "Excel", en: "Excel" },
      { id: "stata", fr: "Stata", en: "Stata" },
      { id: "powerbi", fr: "Power BI", en: "Power BI" },
      { id: "latex", fr: "LaTeX", en: "LaTeX" }
    ]
  },
  {
    name: { fr: "Langues", en: "Languages" },
    items: [
      { id: "lang-fr", fr: "Français, langue maternelle", en: "French, native" },
      { id: "lang-en", fr: "Anglais courant, TOEFL iBT 99/120", en: "English, fluent (TOEFL iBT 99/120)" },
      { id: "lang-es", fr: "Espagnol, notions", en: "Spanish, basic" }
    ]
  }
];

const THEMES = [
  { id: "risk", fr: "Risque et marchés", en: "Risk and markets" },
  { id: "ml", fr: "Machine learning", en: "Machine learning" },
  { id: "policy", fr: "Macro et politiques publiques", en: "Macro and public policy" }
];

const PROJECTS = [
  {
    id: "climate-policy-uncertainty",
    featured: true,
    date: "2026-03",
    themes: ["risk"],
    skills: ["r", "nlp", "event-study", "volatility", "market-risk", "latex"],
    title: {
      fr: "Incertitude de politique climatique et marchés actions",
      en: "Climate policy uncertainty and stock markets"
    },
    context: { fr: "Mémoire de Master 2", en: "Master 2 thesis" },
    coauthors: "Victoria Godio, Raphaël Perilhou",
    question: {
      fr: "Quand l'écart entre promesses de campagne et textes de loi sur le climat se creuse, comment réagissent les rendements, la volatilité et les volumes des actions ?",
      en: "When the gap between climate campaign pledges and legislation widens, how do stock returns, volatility and trading volumes react?"
    },
    metric: { value: "30", label: { fr: "valeurs du Dow Jones, 2017 à 2025", en: "Dow Jones stocks, 2017 to 2025" } },
    method: {
      fr: "Construction d'un indice original d'incertitude (CPU) par analyse de texte : distance sémantique (embeddings GloVe) entre documents de campagne américains et projets de loi du Congrès. Détection des pics, puis étude d'événements empilée sur les 30 valeurs du Dow Jones, avec tests d'endogénéité du VIX (Granger, VAR).",
      en: "Built an original uncertainty index (CPU) from text: semantic distance (GloVe embeddings) between U.S. campaign documents and Congressional bills. Detected spikes, then ran a stacked event study on the 30 Dow Jones stocks, with VIX endogeneity checks (Granger, VAR)."
    },
    results: {
      fr: [
        "La prime de rendement augmente le mois précédant un pic, puis recule à la date du pic",
        "La volatilité réalisée baisse nettement et durablement après un pic, ce qui est cohérent avec un comportement d'attente",
        "Le volume échangé augmente autour du pic, tandis que le volume anormal diminue ensuite"
      ],
      en: [
        "The return premium rises in the month before a spike, then falls at the spike date",
        "Realized volatility drops significantly and persistently after a spike, consistent with wait-and-see behaviour",
        "Trading volume rises around the spike, while abnormal volume falls afterwards"
      ]
    },
    figure: { src: "projects/climate-policy-uncertainty/01_CPU_Construction/plots/CPU_all_lags_localmax.png", alt: { fr: "Indice CPU mensuel 2017–2025 et pics détectés", en: "Monthly CPU index 2017–2025 with detected spikes" } },
    links: [
      { kind: "report", href: "projects/climate-policy-uncertainty/report.pdf" },
      { kind: "slides", href: "projects/climate-policy-uncertainty/slides.pdf" },
      { kind: "code", href: REPO + "projects/climate-policy-uncertainty" }
    ]
  },
  {
    id: "hf-volatility",
    date: "2026-04",
    themes: ["risk"],
    skills: ["r", "volatility", "timeseries", "market-risk"],
    title: {
      fr: "Activité de trading et volatilité intrajournalière du S&P 500",
      en: "Trading activity and S&P 500 intraday volatility"
    },
    context: { fr: "Économétrie financière, M2", en: "Financial econometrics, M2" },
    coauthors: "Victoria Godio, Raphaël Perilhou",
    question: {
      fr: "Les données haute fréquence et les variables d'activité (volume, nombre de transactions) améliorent-elles la prévision de volatilité par rapport à un GARCH(1,1) ?",
      en: "Do high-frequency data and activity variables (volume, trade count) improve volatility forecasts over a GARCH(1,1)?"
    },
    metric: { value: "R² 0,22", valueEn: "R² 0.22", label: { fr: "hors échantillon pour le GARCH, meilleur modèle", en: "out of sample for GARCH, the best model" } },
    method: {
      fr: "Données S&P 500 à la minute. Choix de la fréquence par signature plot, calcul de la volatilité réalisée, puis comparaison GARCH(1,1), HAR-RV et HAR-RV-X (avec volume et transactions), en échantillon et hors échantillon. Robustesse : HAR intrajournalier sur blocs de 30 minutes.",
      en: "One-minute S&P 500 data. Sampling frequency chosen with a signature plot, realized volatility computed, then GARCH(1,1), HAR-RV and HAR-RV-X (with volume and trades) compared in and out of sample. Robustness: intraday HAR on 30-minute blocks."
    },
    results: {
      fr: [
        "Le GARCH(1,1) prévoit mieux que les modèles HAR sur 66 jours de bourse",
        "Ajouter volume et transactions n'améliore pas la prévision",
        "En HAR intrajournalier (650 observations), les composantes deviennent significatives et le R² hors échantillon atteint 0,11 : la faiblesse vient surtout de la taille de l'échantillon"
      ],
      en: [
        "GARCH(1,1) forecasts better than the HAR models over 66 trading days",
        "Adding volume and trades does not improve forecasts",
        "With an intraday HAR (650 observations), components become significant and out-of-sample R² reaches 0.11: the weakness comes mostly from sample size"
      ]
    },
    figure: { src: "projects/hf-volatility/figures/forecast_comparison.png", alt: { fr: "Prévisions hors échantillon : volatilité réalisée contre GARCH et HAR", en: "Out-of-sample forecasts: realized volatility versus GARCH and HAR" } },
    links: [
      { kind: "report", href: "projects/hf-volatility/report.pdf" },
      { kind: "code", href: REPO + "projects/hf-volatility/Code_HF_Project.R" },
      { kind: "data", href: REPO + "projects/hf-volatility/data" }
    ]
  },
  {
    id: "credit-scoring",
    date: "2026-02",
    themes: ["ml", "risk"],
    skills: ["r", "ml", "credit"],
    title: {
      fr: "Prédire la défaillance des entreprises de l'hôtellerie-restauration",
      en: "Predicting defaults among hotel and restaurant firms"
    },
    context: { fr: "Scoring, M2", en: "Scoring, M2" },
    coauthors: "Victoria Godio, Raphaël Perilhou",
    question: {
      fr: "Peut-on prédire la défaillance des entreprises françaises de l'hébergement et de la restauration (2017–2021), secteur très touché par la crise sanitaire, à partir de leurs données financières ?",
      en: "Can we predict defaults among French accommodation and food service firms (2017–2021), a sector hit hard by the pandemic, from their financial statements?"
    },
    metric: { value: "AUC 0,95", valueEn: "AUC 0.95", label: { fr: "pour XGBoost sur l'échantillon de test", en: "for XGBoost on the test set" } },
    method: {
      fr: "Croisement de trois bases (BODACC pour les défaillances, INPI pour les comptes, NAF pour le secteur). Traitement des valeurs manquantes et winsorisation, ACP et analyse discriminante, puis LASSO, arbres de décision et XGBoost (540 combinaisons d'hyperparamètres) avec découpage apprentissage / validation / test.",
      en: "Merged three databases (BODACC for defaults, INPI for accounts, NAF for sector). Missing values and winsorisation, PCA and discriminant analysis, then LASSO, decision trees and XGBoost (540 hyperparameter combinations) with a train / validation / test split."
    },
    results: {
      fr: [
        "XGBoost domine : AUC de 0,95, contre 0,88 pour l'arbre de décision et 0,86 pour le LASSO",
        "Un chiffre d'affaires élevé est associé à moins de défauts, un délai client long à davantage",
        "Limite identifiée : avec des classes très déséquilibrées, l'AUC seule peut surestimer l'utilité pratique du modèle"
      ],
      en: [
        "XGBoost leads with an AUC of 0.95, against 0.88 for the decision tree and 0.86 for LASSO",
        "Higher turnover goes with fewer defaults, longer customer payment terms with more",
        "Known limit: with highly imbalanced classes, AUC alone can overstate the model's practical value"
      ]
    },
    figure: { src: "projects/credit-scoring/report/SF_EDA_ANALYSIS_files/figure-html/unnamed-chunk-43-1.png", alt: { fr: "Courbes ROC des cinq modèles sur l'échantillon de test", en: "ROC curves of the five models on the test set" } },
    links: [
      { kind: "html", href: "projects/credit-scoring/report/" },
      { kind: "code", href: REPO + "projects/credit-scoring/SF_EDA_ANALYSIS.qmd" }
    ]
  },
  {
    id: "extreme-value-census",
    date: "2026-04",
    themes: ["risk"],
    skills: ["r", "evt"],
    title: {
      fr: "Valeurs extrêmes : la taille des villes américaines",
      en: "Extreme values: the size of U.S. cities"
    },
    context: { fr: "Analyse des risques extrêmes, M2", en: "Extreme risk analysis, M2" },
    coauthors: "Victoria Godio, Raphaël Perilhou",
    question: {
      fr: "La population des villes américaines suit-elle une loi à queue épaisse, cette queue est-elle stable dans le temps et selon les régions, et que prévoir pour 2040 ?",
      en: "Does U.S. city population follow a heavy-tailed law, is the tail stable over time and across regions, and what can we expect for 2040?"
    },
    metric: { value: "γ ≈ 0,74", valueEn: "γ ≈ 0.74", label: { fr: "indice de queue, 788 villes", en: "tail index, 788 cities" } },
    method: {
      fr: "Données du recensement 2010–2019. Estimateurs de Hill et Hill à biais réduit, QQ-plots de diagnostic, quantiles extrêmes de Weissman par région, et projection des tailles de villes à 2040.",
      en: "Census data 2010–2019. Hill and bias-reduced Hill estimators, diagnostic QQ-plots, Weissman extreme quantiles by region, and projection of city sizes to 2040."
    },
    results: {
      fr: [
        "L'indice de queue reste très stable de 2010 à 2019 : la queue épaisse est persistante",
        "Toutes les régions ont une queue épaisse, mais avec une forte hétérogénéité (le Nord-Est est faussé par New York)",
        "La théorie des valeurs extrêmes estime mieux les quantiles extrêmes que le quantile empirique"
      ],
      en: [
        "The tail index is very stable from 2010 to 2019: the heavy tail persists",
        "Every region is heavy-tailed, but with strong heterogeneity (New York distorts the Northeast)",
        "Extreme value theory estimates extreme quantiles better than the empirical quantile"
      ]
    },
    links: [
      { kind: "report", href: "projects/extreme-value-census/report.pdf" },
      { kind: "data", href: REPO + "projects/extreme-value-census/census2010.xlsx" }
    ]
  },
  {
    id: "econometrics-methods",
    date: "2026-01",
    themes: ["risk"],
    skills: ["r", "var", "micro-econometrics", "evt"],
    title: {
      fr: "Backtesting de VaR, modèle de Heckman et GMM",
      en: "VaR backtesting, Heckman model and GMM"
    },
    context: { fr: "Méthodes économétriques, M2", en: "Econometric methods, M2" },
    coauthors: "Victoria Godio",
    question: {
      fr: "Trois exercices appliqués : corriger un biais de sélection, comparer des modèles de Value at Risk, estimer offre et demande par GMM.",
      en: "Three applied exercises: correct a selection bias, compare Value at Risk models, estimate supply and demand by GMM."
    },
    metric: { value: "5", label: { fr: "méthodes de VaR backtestées", en: "VaR methods backtested" } },
    method: {
      fr: "Modèle censuré et correction de Heckman avec tests de robustesse. VaR historique, gaussienne, Student standardisée, valeurs extrêmes et historique sur rendements, puis tests de couverture. Estimation GMM d'un système offre-demande avec instruments.",
      en: "Censored model and Heckman correction with robustness checks. Historical, Gaussian, standardized Student, extreme value and historical-on-returns VaR, then coverage tests. GMM estimation of a supply and demand system with instruments."
    },
    results: {
      fr: [
        "Cinq approches de VaR comparées sur leurs dépassements et leurs tests de couverture",
        "Biais de sélection testé sur plusieurs spécifications : significatif dans certaines, pas dans d'autres",
        "Identification des coefficients d'offre et de demande par variables instrumentales"
      ],
      en: [
        "Five VaR approaches compared on exceedances and coverage tests",
        "Selection bias tested across several specifications: significant in some, not in others",
        "Supply and demand coefficients identified with instrumental variables"
      ]
    },
    links: [
      { kind: "report", href: "projects/econometrics-methods/report.pdf" },
      { kind: "code", href: REPO + "projects/econometrics-methods" }
    ]
  },
  {
    id: "euro-yield-curve",
    date: "2025-12",
    themes: ["risk", "policy"],
    skills: ["python", "rates", "timeseries"],
    title: {
      fr: "Chocs macroéconomiques et courbe des taux de la zone euro",
      en: "Macro shocks and the euro area yield curve"
    },
    context: { fr: "Projet Python, M2", en: "Python project, M2" },
    coauthors: "Victoria Godio",
    question: {
      fr: "Comment la politique monétaire, le PIB, la consommation, l'investissement et l'inflation déplacent-ils la courbe zéro-coupon de la zone euro, maturité par maturité ?",
      en: "How do monetary policy, GDP, consumption, investment and inflation move the euro area zero-coupon curve, maturity by maturity?"
    },
    metric: { value: "6 732", valueEn: "6,732", label: { fr: "observations journalières, 14 sources BCE et Eurostat", en: "daily observations, 14 ECB and Eurostat sources" } },
    method: {
      fr: "Fusion de 14 bases de fréquences différentes (1997–2025). Exploration des courbes et des crises, extraction des facteurs niveau, pente et courbure (Diebold et Li), puis régressions MCO avec un mois de décalage.",
      en: "Merged 14 datasets with different frequencies (1997–2025). Explored curves and crises, extracted level, slope and curvature factors (Diebold and Li), then OLS regressions with a one-month lag."
    },
    results: {
      fr: [
        "Le taux de dépôt de la BCE agit surtout sur la pente et la courbure, pas sur les taux longs",
        "L'inflation (IPCH) influence le niveau de la courbe, au seuil de 10 %",
        "Courbe inversée observée à l'été 2024, avec un taux de dépôt autour de 4 %"
      ],
      en: [
        "The ECB deposit rate mainly moves slope and curvature, not long rates",
        "Inflation (HICP) affects the level of the curve, at the 10% level",
        "Inverted curve observed in summer 2024, with a deposit rate around 4%"
      ]
    },
    figure: { src: "projects/euro-yield-curve/python_project_files/figure-html/cell-8-output-1.png", alt: { fr: "Courbe des taux de la zone euro au 4 novembre 2025", en: "Euro area yield curve on 4 November 2025" } },
    links: [
      { kind: "html", href: "projects/euro-yield-curve/" },
      { kind: "code", href: REPO + "projects/euro-yield-curve/python_project.qmd" },
      { kind: "data", href: REPO + "projects/euro-yield-curve/data.csv" }
    ]
  },
  {
    id: "government-spending-svar",
    date: "2026-01",
    themes: ["policy"],
    skills: ["r", "timeseries"],
    title: {
      fr: "Dépenses publiques et activité : une analyse SVAR",
      en: "Government spending and activity: a SVAR analysis"
    },
    context: { fr: "Macroéconomie du risque, M2", en: "Macroeconomics of risk, M2" },
    coauthors: "Victoria Godio, Raphaël Perilhou",
    question: {
      fr: "Comment un choc de dépenses publiques se transmet-il au PIB, à la consommation et à l'incertitude de politique économique aux États-Unis ?",
      en: "How does a government spending shock pass through to GDP, consumption and economic policy uncertainty in the United States?"
    },
    metric: { value: "1947–2015", label: { fr: "données trimestrielles américaines", en: "quarterly U.S. data" } },
    method: {
      fr: "Tests de racine unitaire et de cointégration (Johansen), détrendage à la Blanchard et Perotti, SVAR à quatre variables identifié par Cholesky, fonctions de réponse et décomposition de variance sur six ans.",
      en: "Unit root and cointegration tests (Johansen), Blanchard and Perotti detrending, four-variable SVAR identified by Cholesky, impulse responses and variance decomposition over six years."
    },
    results: {
      fr: [
        "Le PIB réagit positivement à court terme, puis négativement à plus long horizon",
        "La consommation répond faiblement et négativement",
        "L'incertitude de politique économique réagit de façon contracyclique, mais modestement"
      ],
      en: [
        "GDP responds positively in the short run, then negatively at longer horizons",
        "Consumption responds weakly and negatively",
        "Economic policy uncertainty responds countercyclically, but only slightly"
      ]
    },
    links: [
      { kind: "report", href: "projects/government-spending-svar/report.pdf" },
      { kind: "code", href: REPO + "projects/government-spending-svar/macrorisksVBR.qmd" },
      { kind: "data", href: REPO + "projects/government-spending-svar/data" }
    ]
  },
  {
    id: "nh1-cost-benefit",
    date: "2025-11",
    themes: ["policy"],
    skills: ["npv"],
    title: {
      fr: "Analyse coûts-bénéfices de la ferme hydrolienne NH1",
      en: "Cost-benefit analysis of the NH1 tidal farm"
    },
    context: { fr: "Analyse coûts-bénéfices, M2", en: "Cost-benefit analysis, M2" },
    coauthors: "Victoria Godio, Raphaël Perilhou",
    question: {
      fr: "Le premier parc hydrolien pilote français (Raz Blanchard, 90 M€ d'investissement) est-il socialement rentable sur 25 ans ?",
      en: "Is France's first pilot tidal farm (Raz Blanchard, €90M investment) socially efficient over 25 years?"
    },
    metric: { value: "77 %", valueEn: "77%", label: { fr: "de probabilité de VAN négative (scénario réaliste)", en: "probability of a negative NPV (realistic scenario)" } },
    method: {
      fr: "Bénéfices : ventes d'électricité et émissions de CO₂ évitées, emploi via un salaire fictif. Coûts : CAPEX et OPEX. Actualisation à 2,75 %, simulation Monte Carlo sur le prix de l'électricité et trois scénarios d'émissions.",
      en: "Benefits: electricity sales and avoided CO₂ emissions, jobs through a shadow wage. Costs: CAPEX and OPEX. 2.75% discount rate, Monte Carlo simulation on the electricity price and three emissions scenarios."
    },
    results: {
      fr: [
        "Probabilité de VAN négative de 70 % à 84 % selon le scénario",
        "La VAN est très sensible au prix de revente de l'électricité",
        "Les gains d'apprentissage et de baisse des coûts futurs restent hors de l'horizon de 25 ans"
      ],
      en: [
        "Probability of a negative NPV between 70% and 84% depending on the scenario",
        "NPV is highly sensitive to the electricity resale price",
        "Learning gains and future cost reductions fall outside the 25-year horizon"
      ]
    },
    links: [
      { kind: "report", href: "projects/nh1-cost-benefit/report.pdf" }
    ]
  },
  {
    id: "mental-health-us",
    date: "2025-03",
    themes: ["policy"],
    skills: ["stata", "micro-econometrics"],
    title: {
      fr: "Anxiété, dépression et facteurs socio-économiques aux États-Unis",
      en: "Anxiety, depression and socio-economic factors in the U.S."
    },
    context: { fr: "Projet empirique, M1", en: "Empirical project, M1" },
    coauthors: "Victoria Godio, Maëlle Tchoukriel-Eyraud",
    question: {
      fr: "Quels facteurs démographiques et socio-économiques expliquent la prévalence de l'anxiété et de la dépression aux États-Unis ?",
      en: "Which demographic and socio-economic factors explain the prevalence of anxiety and depression in the United States?"
    },
    metric: { value: "15,6 M", valueEn: "15.6M", label: { fr: "observations (MH-CLD, 2018–2022)", en: "observations (MH-CLD, 2018–2022)" } },
    method: {
      fr: "Base MH-CLD de la SAMHSA, modèles probit avec erreurs standard robustes.",
      en: "SAMHSA's MH-CLD dataset, probit models with robust standard errors."
    },
    results: {
      fr: [
        "Contrairement à l'idée reçue, les personnes plus diplômées et aux emplois plus exigeants sont davantage touchées",
        "L'étude souligne les coûts cachés du stress au travail et de la pression scolaire"
      ],
      en: [
        "Contrary to common belief, more educated people in more demanding jobs are more affected",
        "The study highlights the hidden costs of work stress and academic pressure"
      ]
    },
    links: [
      { kind: "report", href: "projects/mental-health-us/report.pdf" },
      { kind: "code", href: REPO + "projects/mental-health-us/analysis.do" }
    ]
  }
];

/* Indice CPU mensuel (série CPU_0 du mémoire, nov. 2016 à déc. 2025) et pics retenus
   par la méthode des maxima locaux (moyenne + 1,5 écart-type, écart minimal de 5 mois) */
const CPU_SERIES = {
  start: "2016-11",
  values: [0.0559,0.0488,0.0494,0.0439,0.0503,0.0423,0.0732,0.0569,0.0808,0.0480,0.0813,0.0572,0.0629,0.0460,0.0576,0.0532,0.0446,0.0501,0.0621,0.0899,0.0584,0.0728,0.0665,0.0356,0.0525,0.0267,0.0792,0.0401,0.0392,0.0498,0.0530,0.0543,0.0569,0.0310,0.0570,0.0446,0.0376,0.0610,0.0352,0.0398,0.0495,0.0356,0.0425,0.0650,0.0450,0.0434,0.0506,0.0463,0.0635,0.0667,0.0238,0.0378,0.0540,0.0423,0.0399,0.0485,0.0608,0.0601,0.0568,0.0440,0.0402,0.0309,0.0375,0.0570,0.0511,0.0426,0.0406,0.0462,0.0656,0.0577,0.0318,0.0289,0.0269,0.0802,0.0341,0.0289,0.0370,0.0302,0.0362,0.0662,0.0694,0.0323,0.0357,0.0287,0.0408,0.0459,0.0464,0.0529,0.0703,0.0232,0.0625,0.0564,0.0847,0.0430,0.0460,0.0395,0.0497,0.0823,0.0245,0.0357,0.0625,0.0294,0.0391,0.0501,0.0710,0.0570,0.0572,0.0362,0.0313,0.0467],
  spikes: ["2017-05", "2018-06", "2019-01", "2022-12", "2024-07", "2024-12"]
};

const EDUCATION = [
  {
    period: "2025 – 2026",
    degree: { fr: "Master 2 Economics of Global Risks", en: "Master 2 Economics of Global Risks" },
    school: "Toulouse School of Economics",
    courses: [
      { fr: "Financial Econometrics : séries temporelles appliquées au risque, GARCH, Value at Risk", en: "Financial Econometrics: time series applied to risk, GARCH, Value at Risk" },
      { fr: "Extreme Risk Analysis : risque de queue et méthodes d'estimation", en: "Extreme Risk Analysis: tail risk and estimation methods" },
      { fr: "Enterprise Risk Management : quantifier et réduire le risque, finance et développement durable", en: "Enterprise Risk Management: measuring and reducing risk, finance and sustainability" },
      { fr: "Scoring : analyse de données, régression, arbres de décision", en: "Scoring: data analysis, regression, decision trees" },
      { fr: "Time Series : modèles AR, MA, ARMA", en: "Time Series: AR, MA, ARMA models" },
      { fr: "Macroeconomics of Risk : réponse des marchés aux chocs d'incertitude", en: "Macroeconomics of Risk: how markets respond to uncertainty shocks" },
      { fr: "Long Term Asset Pricing : valorisation d'événements de long terme et taux d'actualisation", en: "Long Term Asset Pricing: valuing long-term events and discount rates" },
      { fr: "Cost Benefit Analysis : consentement à payer et méthodes de valorisation", en: "Cost Benefit Analysis: willingness to pay and valuation methods" },
      { fr: "Sustainable Finance : critères ESG et taxonomies", en: "Sustainable Finance: ESG criteria and taxonomies" },
      { fr: "Python", en: "Python" }
    ]
  },
  {
    period: "2024 – 2025",
    degree: { fr: "Master 1 International Economics", en: "Master 1 International Economics" },
    school: "Toulouse School of Economics",
    courses: [
      { fr: "Market Finance : principaux instruments financiers", en: "Market Finance: main financial instruments" },
      { fr: "Corporate Finance : flux actualisés, évaluation d'investissements, levée de capitaux", en: "Corporate Finance: discounted cash flows, investment valuation, raising capital" },
      { fr: "Econometrics : variables instrumentales, logit, maximum de vraisemblance, GMM", en: "Econometrics: instrumental variables, logit, maximum likelihood, GMM" },
      { fr: "Data Bases : SQL et Power BI", en: "Data Bases: SQL and Power BI" },
      { fr: "Macroeconomics : propagation des chocs", en: "Macroeconomics: shock propagation" },
      { fr: "Industrial Organisation : concurrence, fusions, monopoles", en: "Industrial Organisation: competition, mergers, monopolies" },
      { fr: "Game Theory : jeux sous incertitude", en: "Game Theory: games under uncertainty" }
    ]
  },
  {
    period: "2021 – 2024",
    degree: { fr: "Licence d'économie", en: "Bachelor's in Economics" },
    school: "Toulouse School of Economics",
    courses: [
      { fr: "Mathématiques, probabilités, statistiques, économétrie, microéconomie, macroéconomie", en: "Mathematics, probability, statistics, econometrics, microeconomics, macroeconomics" }
    ]
  }
];

const UI = {
  fr: {
    nav: { experience: "Expérience", projects: "Projets", skills: "Compétences", education: "Formation" },
    print: "Télécharger en PDF",
    langSwitch: "English",
    langSwitchLabel: "Switch to English",
    themeLabel: "Changer de thème",
    curveCaption: "Parcours, de la licence au premier poste",
    expTitle: "Expérience",
    summerJobs: "Jobs d'été",
    projectsTitle: "Projets",
    projectsIntro: "Neuf études réalisées à la TSE, avec rapports, code et données. Filtrez par thème ou cliquez sur une compétence plus bas pour voir les projets qui la mobilisent.",
    all: "Tous",
    featured: "Mémoire",
    sparkCaption: "Indice d'incertitude construit dans le mémoire, 2016 à 2025. Les points marquent les pics étudiés.",
    details: "Voir le détail",
    question: "Question",
    method: "Méthode",
    results: "Résultats",
    with: "Avec",
    close: "Fermer",
    linkKinds: { report: "Rapport (PDF)", slides: "Présentation (PDF)", code: "Code", data: "Données", html: "Rapport interactif" },
    skillsTitle: "Compétences",
    skillsHint: "Cliquez sur une compétence pour filtrer les projets.",
    usedIn: (n) => n === 0 ? "" : (n === 1 ? "1 projet" : n + " projets"),
    filterBy: "Filtre",
    clearFilter: "Retirer le filtre",
    eduTitle: "Formation",
    showCourses: "Voir les cours",
    hideCourses: "Masquer les cours",
    footer: "Site mis à jour en octobre 2026.",
    noProjects: "Aucun projet ne correspond. Retirez le filtre pour tout afficher."
  },
  en: {
    nav: { experience: "Experience", projects: "Projects", skills: "Skills", education: "Education" },
    print: "Download as PDF",
    langSwitch: "Français",
    langSwitchLabel: "Passer en français",
    themeLabel: "Toggle theme",
    curveCaption: "Path from degree to first role",
    expTitle: "Experience",
    summerJobs: "Summer jobs",
    projectsTitle: "Projects",
    projectsIntro: "Nine studies carried out at TSE, with reports, code and data. Filter by theme, or click a skill further down to see the projects that use it.",
    all: "All",
    featured: "Thesis",
    sparkCaption: "Uncertainty index built in the thesis, 2016 to 2025. Dots mark the spikes studied.",
    details: "See details",
    question: "Question",
    method: "Method",
    results: "Results",
    with: "With",
    close: "Close",
    linkKinds: { report: "Report (PDF)", slides: "Slides (PDF)", code: "Code", data: "Data", html: "Interactive report" },
    skillsTitle: "Skills",
    skillsHint: "Click a skill to filter the projects.",
    usedIn: (n) => n === 0 ? "" : (n === 1 ? "1 project" : n + " projects"),
    filterBy: "Filter",
    clearFilter: "Clear filter",
    eduTitle: "Education",
    showCourses: "Show courses",
    hideCourses: "Hide courses",
    footer: "Site updated October 2026.",
    noProjects: "No project matches. Clear the filter to see them all."
  }
};
