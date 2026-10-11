/* Contenu du CV : modifier ce fichier pour mettre à jour le site.
   Chaque texte existe en deux versions : fr et en. */

const PROFILE = {
  "name": "Baptiste Messant",
  "role": {
    "fr": "Energy Risk Analyst chez IDEX",
    "en": "Energy Risk Analyst at IDEX"
  },
  "pitch": {
    "fr": "Diplômé du Master Economics of Global Risks de la Toulouse School of Economics, je suis Energy Risk Analyst en CDI chez IDEX, où j'ai d'abord effectué mon stage de fin d'études. Je suis les positions et les risques de marché sur le gaz, l'électricité et les garanties d'origine, ainsi que le risque de contrepartie, et je développe les reportings de risque sous Excel, VBA et SQL.",
    "en": "A graduate of the Economics of Global Risks master's at Toulouse School of Economics, I am an Energy Risk Analyst on a permanent contract at IDEX, where I first did my final internship. I monitor market positions and risks on gas, power and guarantees of origin, as well as counterparty risk, and I build risk reports in Excel, VBA and SQL."
  },
  "status": {
    "fr": "En poste : Energy Risk Analyst, CDI",
    "en": "Currently: Energy Risk Analyst, permanent contract"
  },
  "links": [
    {
      "id": "linkedin",
      "label": "LinkedIn",
      "url": "https://www.linkedin.com/in/baptiste-messant/"
    },
    {
      "id": "github",
      "label": "GitHub",
      "url": "https://github.com/baptisteM47"
    }
  ]
};

/* Courbe du parcours en haut de page (année décimale, hauteur relative 0 à 1).
   target = id de l'étape du parcours vers laquelle le point renvoie */
const CAREER = [
  {
    "t": 2021.7,
    "y": 0.1,
    "label": {
      "fr": "Licence d'économie, TSE",
      "en": "Economics degree, TSE"
    },
    "target": "tl-licence"
  },
  {
    "t": 2024.7,
    "y": 0.42,
    "label": {
      "fr": "Master 1, TSE",
      "en": "Master 1, TSE"
    },
    "target": "tl-m1"
  },
  {
    "t": 2025.4,
    "y": 0.52,
    "label": {
      "fr": "Stage Midi2i",
      "en": "Midi2i internship"
    },
    "target": "tl-midi2i"
  },
  {
    "t": 2025.7,
    "y": 0.68,
    "label": {
      "fr": "Master 2 Global Risks",
      "en": "Master 2 Global Risks"
    },
    "target": "tl-m2"
  },
  {
    "t": 2026.3,
    "y": 0.8,
    "label": {
      "fr": "Stage IDEX",
      "en": "IDEX internship"
    },
    "target": "tl-idex-stage"
  },
  {
    "t": 2026.8,
    "y": 0.92,
    "label": {
      "fr": "CDI IDEX, Energy Risk Analyst",
      "en": "IDEX, Energy Risk Analyst"
    },
    "target": "tl-idex",
    "current": true
  }
];

/* Parcours chronologique, du plus récent au plus ancien.
   type : "work" (expérience) ou "edu" (formation).
   projects : projets réalisés pendant l'étape (ids de PROJECTS). */
const TIMELINE = [
  {
    "id": "tl-idex",
    "type": "work",
    "current": true,
    "period": {
      "fr": "2026 – aujourd'hui",
      "en": "2026 – present"
    },
    "title": {
      "fr": "Energy Risk Analyst",
      "en": "Energy Risk Analyst"
    },
    "org": "IDEX",
    "kind": {
      "fr": "Énergie, CDI",
      "en": "Energy, permanent contract"
    },
    "bullets": {
      "fr": [
        "Analyse quotidienne des positions de marché : exposition et volatilité",
        "Gestion des risques de marché énergie (gaz, électricité, garanties d'origine) et du risque de contrepartie",
        "Reportings de risque de marché quotidiens et hebdomadaires",
        "Développement et automatisation des reportings de risque sous Excel, VBA et SQL",
        "Contrôle quotidien de l'activité de trading et des opérations de marché"
      ],
      "en": [
        "Daily analysis of market positions: exposure and volatility",
        "Energy market risk (gas, power, guarantees of origin) and counterparty risk management",
        "Daily and weekly market risk reporting",
        "Building and automating risk reports in Excel, VBA and SQL",
        "Daily control of trading activity and market operations"
      ]
    },
    "tags": [
      "Excel",
      "VBA",
      "SQL"
    ]
  },
  {
    "id": "tl-idex-stage",
    "type": "work",
    "period": {
      "fr": "2026",
      "en": "2026"
    },
    "title": {
      "fr": "Energy Risk Analyst, stage de fin d'études",
      "en": "Energy Risk Analyst, final internship"
    },
    "org": "IDEX",
    "kind": {
      "fr": "Énergie",
      "en": "Energy"
    },
    "note": {
      "fr": "Stage au sein de l'équipe risques de marché, suivi d'une embauche en CDI sur le même poste.",
      "en": "Internship in the market risk team, followed by a permanent hire in the same role."
    }
  },
  {
    "id": "tl-m2",
    "type": "edu",
    "period": {
      "fr": "2025 – 2026",
      "en": "2025 – 2026"
    },
    "title": {
      "fr": "Master 2 Economics of Global Risks",
      "en": "Master 2 Economics of Global Risks"
    },
    "org": "Toulouse School of Economics",
    "projects": [
      "climate-policy-uncertainty",
      "hf-volatility",
      "credit-scoring",
      "extreme-value-census",
      "econometrics-methods",
      "euro-yield-curve",
      "government-spending-svar",
      "nh1-cost-benefit"
    ],
    "courses": [
      {
        "fr": "Financial Econometrics : séries temporelles appliquées au risque, GARCH, Value at Risk",
        "en": "Financial Econometrics: time series applied to risk, GARCH, Value at Risk"
      },
      {
        "fr": "Extreme Risk Analysis : risque de queue et méthodes d'estimation",
        "en": "Extreme Risk Analysis: tail risk and estimation methods"
      },
      {
        "fr": "Enterprise Risk Management : quantifier et réduire le risque, finance et développement durable",
        "en": "Enterprise Risk Management: measuring and reducing risk, finance and sustainability"
      },
      {
        "fr": "Scoring : analyse de données, régression, arbres de décision",
        "en": "Scoring: data analysis, regression, decision trees"
      },
      {
        "fr": "Time Series : modèles AR, MA, ARMA",
        "en": "Time Series: AR, MA, ARMA models"
      },
      {
        "fr": "Macroeconomics of Risk : réponse des marchés aux chocs d'incertitude",
        "en": "Macroeconomics of Risk: how markets respond to uncertainty shocks"
      },
      {
        "fr": "Long Term Asset Pricing : valorisation d'événements de long terme et taux d'actualisation",
        "en": "Long Term Asset Pricing: valuing long-term events and discount rates"
      },
      {
        "fr": "Cost Benefit Analysis : consentement à payer et méthodes de valorisation",
        "en": "Cost Benefit Analysis: willingness to pay and valuation methods"
      },
      {
        "fr": "Sustainable Finance : critères ESG et taxonomies",
        "en": "Sustainable Finance: ESG criteria and taxonomies"
      },
      {
        "fr": "Python",
        "en": "Python"
      }
    ]
  },
  {
    "id": "tl-midi2i",
    "type": "work",
    "period": {
      "fr": "2025",
      "en": "2025"
    },
    "title": {
      "fr": "Analyste en gestion des risques, stage",
      "en": "Risk management analyst, internship"
    },
    "org": "Midi2i",
    "kind": {
      "fr": "Fonds d'investissement",
      "en": "Investment fund"
    },
    "bullets": {
      "fr": [
        "Découverte de l'ensemble du département financier : gestion de fonds et d'actifs, méthodes de calcul des portefeuilles clients",
        "Contrôles qualité des données réglementaires AMF et maîtrise des risques de diffusion des données",
        "Analyse de données pour fiabiliser la gestion des données et automatiser des tâches financières"
      ],
      "en": [
        "Rotation across the finance department: fund and asset management, client portfolio calculation methods",
        "AMF regulatory data quality checks and control of data dissemination risk",
        "Data analysis to make data management more reliable and automate finance tasks"
      ]
    }
  },
  {
    "id": "tl-m1",
    "type": "edu",
    "period": {
      "fr": "2024 – 2025",
      "en": "2024 – 2025"
    },
    "title": {
      "fr": "Master 1 International Economics",
      "en": "Master 1 International Economics"
    },
    "org": "Toulouse School of Economics",
    "projects": [
      "mental-health-us"
    ],
    "courses": [
      {
        "fr": "Market Finance : principaux instruments financiers",
        "en": "Market Finance: main financial instruments"
      },
      {
        "fr": "Corporate Finance : flux actualisés, évaluation d'investissements, levée de capitaux",
        "en": "Corporate Finance: discounted cash flows, investment valuation, raising capital"
      },
      {
        "fr": "Econometrics : variables instrumentales, logit, maximum de vraisemblance, GMM",
        "en": "Econometrics: instrumental variables, logit, maximum likelihood, GMM"
      },
      {
        "fr": "Data Bases : SQL et Power BI",
        "en": "Data Bases: SQL and Power BI"
      },
      {
        "fr": "Macroeconomics : propagation des chocs",
        "en": "Macroeconomics: shock propagation"
      },
      {
        "fr": "Industrial Organisation : concurrence, fusions, monopoles",
        "en": "Industrial Organisation: competition, mergers, monopolies"
      },
      {
        "fr": "Game Theory : jeux sous incertitude",
        "en": "Game Theory: games under uncertainty"
      }
    ]
  },
  {
    "id": "tl-licence",
    "type": "edu",
    "period": {
      "fr": "2021 – 2024",
      "en": "2021 – 2024"
    },
    "title": {
      "fr": "Licence d'économie",
      "en": "Bachelor's in Economics"
    },
    "org": "Toulouse School of Economics",
    "note": {
      "fr": "Mathématiques, probabilités, statistiques, économétrie, microéconomie, macroéconomie",
      "en": "Mathematics, probability, statistics, econometrics, microeconomics, macroeconomics"
    }
  }
];

const SUMMER_JOBS = [
  {
    "year": "2024",
    "fr": "Préparateur de commandes, Leclerc Drive Brugières",
    "en": "Order picker, Leclerc Drive Brugières"
  },
  {
    "year": "2023",
    "fr": "Plongeur, Les Terrasses de l'Atelier",
    "en": "Dishwasher, Les Terrasses de l'Atelier"
  },
  {
    "year": "2022",
    "fr": "Caissier, Leclerc Saint-Orens",
    "en": "Cashier, Leclerc Saint-Orens"
  },
  {
    "year": "2021",
    "fr": "Caissier et préparateur de commandes, Leclerc Saint-Orens",
    "en": "Cashier and order picker, Leclerc Saint-Orens"
  },
  {
    "year": "2020",
    "fr": "Agent d'entrepôt, Logipharma",
    "en": "Warehouse worker, Logipharma"
  }
];

/* Projets : overview = résumé simple affiché sur le site et dans le PDF */
const THEMES = [
  {
    "id": "risk",
    "fr": "Risque et marchés",
    "en": "Risk and markets"
  },
  {
    "id": "ml",
    "fr": "Machine learning",
    "en": "Machine learning"
  },
  {
    "id": "policy",
    "fr": "Macro et politiques publiques",
    "en": "Macro and public policy"
  }
];

const PROJECTS = [
  {
    "id": "climate-policy-uncertainty",
    "featured": true,
    "date": "2026-03",
    "themes": [
      "risk"
    ],
    "tools": [
      "R"
    ],
    "title": {
      "fr": "Incertitude de politique climatique et marchés actions",
      "en": "Climate policy uncertainty and stock markets"
    },
    "context": {
      "fr": "Mémoire de Master 2",
      "en": "Master 2 thesis"
    },
    "coauthors": "Victoria Godio, Raphaël Perilhou",
    "overview": {
      "fr": "J'ai construit un indicateur de l'incertitude sur la politique climatique américaine à partir de textes (documents de campagne et projets de loi), puis étudié comment les actions des grandes entreprises américaines réagissent quand cette incertitude augmente.",
      "en": "I built an indicator of U.S. climate policy uncertainty from text (campaign documents and bills), then studied how the shares of large U.S. companies react when this uncertainty rises."
    },
    "links": [
      {
        "kind": "report",
        "href": "projects/climate-policy-uncertainty/report.pdf"
      },
      {
        "kind": "code",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/climate-policy-uncertainty"
      }
    ]
  },
  {
    "id": "hf-volatility",
    "date": "2026-04",
    "themes": [
      "risk"
    ],
    "tools": [
      "R"
    ],
    "title": {
      "fr": "Activité de trading et volatilité intrajournalière du S&P 500",
      "en": "Trading activity and S&P 500 intraday volatility"
    },
    "context": {
      "fr": "Économétrie financière, M2",
      "en": "Financial econometrics, M2"
    },
    "coauthors": "Victoria Godio, Raphaël Perilhou",
    "overview": {
      "fr": "Comparaison de plusieurs modèles pour prévoir la volatilité du S&P 500 à partir de données de marché à la minute, en regardant si l'activité de trading aide à mieux la prévoir.",
      "en": "A comparison of several models that forecast S&P 500 volatility from minute-by-minute market data, looking at whether trading activity helps forecast it better."
    },
    "links": [
      {
        "kind": "report",
        "href": "projects/hf-volatility/report.pdf"
      },
      {
        "kind": "code",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/hf-volatility/Code_HF_Project.R"
      },
      {
        "kind": "data",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/hf-volatility/data"
      }
    ]
  },
  {
    "id": "credit-scoring",
    "date": "2026-02",
    "themes": [
      "ml",
      "risk"
    ],
    "tools": [
      "R"
    ],
    "title": {
      "fr": "Prédire la défaillance des entreprises de l'hôtellerie-restauration",
      "en": "Predicting defaults among hotel and restaurant firms"
    },
    "context": {
      "fr": "Scoring, M2",
      "en": "Scoring, M2"
    },
    "coauthors": "Victoria Godio, Raphaël Perilhou",
    "overview": {
      "fr": "Des modèles de machine learning pour prédire la défaillance d'entreprises françaises de l'hôtellerie-restauration à partir de leurs comptes financiers.",
      "en": "Machine learning models that predict defaults among French hotel and restaurant firms from their financial accounts."
    },
    "links": [
      {
        "kind": "html",
        "href": "projects/credit-scoring/report/"
      },
      {
        "kind": "code",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/credit-scoring/SF_EDA_ANALYSIS.qmd"
      }
    ]
  },
  {
    "id": "extreme-value-census",
    "date": "2026-04",
    "themes": [
      "risk"
    ],
    "tools": [
      "R"
    ],
    "title": {
      "fr": "Valeurs extrêmes : la taille des villes américaines",
      "en": "Extreme values: the size of U.S. cities"
    },
    "context": {
      "fr": "Analyse des risques extrêmes, M2",
      "en": "Extreme risk analysis, M2"
    },
    "coauthors": "Victoria Godio, Raphaël Perilhou",
    "overview": {
      "fr": "La théorie des valeurs extrêmes appliquée à la population des villes américaines, pour comprendre le poids des très grandes villes et projeter leur taille dans le futur.",
      "en": "Extreme value theory applied to the population of U.S. cities, to understand the weight of the largest cities and project their size into the future."
    },
    "links": [
      {
        "kind": "report",
        "href": "projects/extreme-value-census/report.pdf"
      },
      {
        "kind": "data",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/extreme-value-census/census2010.xlsx"
      }
    ]
  },
  {
    "id": "econometrics-methods",
    "date": "2026-01",
    "themes": [
      "risk"
    ],
    "tools": [
      "R"
    ],
    "title": {
      "fr": "Backtesting de VaR, modèle de Heckman et GMM",
      "en": "VaR backtesting, Heckman model and GMM"
    },
    "context": {
      "fr": "Méthodes économétriques, M2",
      "en": "Econometric methods, M2"
    },
    "coauthors": "Victoria Godio",
    "overview": {
      "fr": "Trois exercices d'économétrie appliquée : tester des modèles de Value at Risk, corriger un biais de sélection et estimer un modèle d'offre et de demande.",
      "en": "Three applied econometrics exercises: testing Value at Risk models, correcting a selection bias and estimating a supply and demand model."
    },
    "links": [
      {
        "kind": "report",
        "href": "projects/econometrics-methods/report.pdf"
      },
      {
        "kind": "code",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/econometrics-methods"
      }
    ]
  },
  {
    "id": "euro-yield-curve",
    "date": "2025-12",
    "themes": [
      "risk",
      "policy"
    ],
    "tools": [
      "Python"
    ],
    "title": {
      "fr": "Chocs macroéconomiques et courbe des taux de la zone euro",
      "en": "Macro shocks and the euro area yield curve"
    },
    "context": {
      "fr": "Projet Python, M2",
      "en": "Python project, M2"
    },
    "coauthors": "Victoria Godio",
    "overview": {
      "fr": "Une analyse en Python de l'effet des chocs macroéconomiques (politique monétaire, inflation, croissance) sur la courbe des taux de la zone euro, du court au long terme.",
      "en": "A Python analysis of how macroeconomic shocks (monetary policy, inflation, growth) affect the euro area yield curve, from short to long maturities."
    },
    "links": [
      {
        "kind": "html",
        "href": "projects/euro-yield-curve/"
      },
      {
        "kind": "code",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/euro-yield-curve/python_project.qmd"
      },
      {
        "kind": "data",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/euro-yield-curve/data.csv"
      }
    ]
  },
  {
    "id": "government-spending-svar",
    "date": "2026-01",
    "themes": [
      "policy"
    ],
    "tools": [
      "R"
    ],
    "title": {
      "fr": "Dépenses publiques et activité : une analyse SVAR",
      "en": "Government spending and activity: a SVAR analysis"
    },
    "context": {
      "fr": "Macroéconomie du risque, M2",
      "en": "Macroeconomics of risk, M2"
    },
    "coauthors": "Victoria Godio, Raphaël Perilhou",
    "overview": {
      "fr": "Une étude de l'effet des dépenses publiques sur l'activité économique et l'incertitude aux États-Unis, à l'aide d'un modèle VAR structurel.",
      "en": "A study of how government spending affects economic activity and uncertainty in the United States, using a structural VAR model."
    },
    "links": [
      {
        "kind": "report",
        "href": "projects/government-spending-svar/report.pdf"
      },
      {
        "kind": "code",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/government-spending-svar/macrorisksVBR.qmd"
      },
      {
        "kind": "data",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/government-spending-svar/data"
      }
    ]
  },
  {
    "id": "nh1-cost-benefit",
    "date": "2025-11",
    "themes": [
      "policy"
    ],
    "tools": [],
    "title": {
      "fr": "Analyse coûts-bénéfices de la ferme hydrolienne NH1",
      "en": "Cost-benefit analysis of the NH1 tidal farm"
    },
    "context": {
      "fr": "Analyse coûts-bénéfices, M2",
      "en": "Cost-benefit analysis, M2"
    },
    "coauthors": "Victoria Godio, Raphaël Perilhou",
    "overview": {
      "fr": "Une analyse coûts-bénéfices du premier parc hydrolien pilote français, pour évaluer s'il est rentable pour la collectivité sur toute sa durée de vie.",
      "en": "A cost-benefit analysis of France's first pilot tidal farm, assessing whether it pays off for society over its lifetime."
    },
    "links": [
      {
        "kind": "report",
        "href": "projects/nh1-cost-benefit/report.pdf"
      }
    ]
  },
  {
    "id": "mental-health-us",
    "date": "2025-03",
    "themes": [
      "policy"
    ],
    "tools": [
      "Stata"
    ],
    "title": {
      "fr": "Anxiété, dépression et facteurs socio-économiques aux États-Unis",
      "en": "Anxiety, depression and socio-economic factors in the U.S."
    },
    "context": {
      "fr": "Projet empirique, M1",
      "en": "Empirical project, M1"
    },
    "coauthors": "Victoria Godio, Maëlle Tchoukriel-Eyraud",
    "overview": {
      "fr": "Une étude des facteurs démographiques et socio-économiques liés à l'anxiété et à la dépression aux États-Unis, à partir d'une grande base de données de santé publique.",
      "en": "A study of the demographic and socio-economic factors linked to anxiety and depression in the United States, using a large public health dataset."
    },
    "links": [
      {
        "kind": "report",
        "href": "projects/mental-health-us/report.pdf"
      },
      {
        "kind": "code",
        "href": "https://github.com/baptisteM47/baptistem47.github.io/blob/main/projects/mental-health-us/analysis.do"
      }
    ]
  }
];

/* Indicateur d'incertitude du mémoire (série mensuelle) et pics étudiés, pour le petit graphique */
const CPU_SERIES = {
  start: "2016-11",
  values: [0.0559,0.0488,0.0494,0.0439,0.0503,0.0423,0.0732,0.0569,0.0808,0.048,0.0813,0.0572,0.0629,0.046,0.0576,0.0532,0.0446,0.0501,0.0621,0.0899,0.0584,0.0728,0.0665,0.0356,0.0525,0.0267,0.0792,0.0401,0.0392,0.0498,0.053,0.0543,0.0569,0.031,0.057,0.0446,0.0376,0.061,0.0352,0.0398,0.0495,0.0356,0.0425,0.065,0.045,0.0434,0.0506,0.0463,0.0635,0.0667,0.0238,0.0378,0.054,0.0423,0.0399,0.0485,0.0608,0.0601,0.0568,0.044,0.0402,0.0309,0.0375,0.057,0.0511,0.0426,0.0406,0.0462,0.0656,0.0577,0.0318,0.0289,0.0269,0.0802,0.0341,0.0289,0.037,0.0302,0.0362,0.0662,0.0694,0.0323,0.0357,0.0287,0.0408,0.0459,0.0464,0.0529,0.0703,0.0232,0.0625,0.0564,0.0847,0.043,0.046,0.0395,0.0497,0.0823,0.0245,0.0357,0.0625,0.0294,0.0391,0.0501,0.071,0.057,0.0572,0.0362,0.0313,0.0467],
  spikes: ["2017-05","2018-06","2019-01","2022-12","2024-07","2024-12"]
};

const SKILL_GROUPS = [
  {
    "name": {
      "fr": "Risque et finance",
      "en": "Risk and finance"
    },
    "items": [
      {
        "id": "market-risk",
        "fr": "Risque de marché",
        "en": "Market risk"
      },
      {
        "id": "var",
        "fr": "Value at Risk et backtesting",
        "en": "Value at Risk and backtesting"
      },
      {
        "id": "volatility",
        "fr": "Modèles de volatilité (GARCH, HAR)",
        "en": "Volatility models (GARCH, HAR)"
      },
      {
        "id": "evt",
        "fr": "Théorie des valeurs extrêmes",
        "en": "Extreme value theory"
      },
      {
        "id": "credit",
        "fr": "Risque de crédit et scoring",
        "en": "Credit risk and scoring"
      },
      {
        "id": "counterparty",
        "fr": "Risque de contrepartie",
        "en": "Counterparty risk"
      },
      {
        "id": "rates",
        "fr": "Courbe des taux",
        "en": "Yield curve"
      },
      {
        "id": "npv",
        "fr": "VAN et simulation Monte Carlo",
        "en": "NPV and Monte Carlo simulation"
      },
      {
        "id": "regulation",
        "fr": "Données réglementaires (AMF)",
        "en": "Regulatory data (AMF)"
      }
    ]
  },
  {
    "name": {
      "fr": "Économétrie et data",
      "en": "Econometrics and data"
    },
    "items": [
      {
        "id": "timeseries",
        "fr": "Séries temporelles, VAR / SVAR",
        "en": "Time series, VAR / SVAR"
      },
      {
        "id": "event-study",
        "fr": "Études d'événements",
        "en": "Event studies"
      },
      {
        "id": "ml",
        "fr": "Machine learning (LASSO, arbres, XGBoost)",
        "en": "Machine learning (LASSO, trees, XGBoost)"
      },
      {
        "id": "nlp",
        "fr": "Analyse de texte (NLP)",
        "en": "Text analysis (NLP)"
      },
      {
        "id": "micro-econometrics",
        "fr": "Probit, Heckman, GMM",
        "en": "Probit, Heckman, GMM"
      }
    ]
  },
  {
    "name": {
      "fr": "Outils",
      "en": "Tools"
    },
    "items": [
      {
        "id": "r",
        "fr": "R",
        "en": "R"
      },
      {
        "id": "python",
        "fr": "Python",
        "en": "Python"
      },
      {
        "id": "sql",
        "fr": "SQL",
        "en": "SQL"
      },
      {
        "id": "vba",
        "fr": "VBA",
        "en": "VBA"
      },
      {
        "id": "excel",
        "fr": "Excel",
        "en": "Excel"
      },
      {
        "id": "stata",
        "fr": "Stata",
        "en": "Stata"
      },
      {
        "id": "powerbi",
        "fr": "Power BI",
        "en": "Power BI"
      },
      {
        "id": "latex",
        "fr": "LaTeX",
        "en": "LaTeX"
      }
    ]
  },
  {
    "name": {
      "fr": "Langues",
      "en": "Languages"
    },
    "items": [
      {
        "id": "lang-fr",
        "fr": "Français, langue maternelle",
        "en": "French, native"
      },
      {
        "id": "lang-en",
        "fr": "Anglais courant, TOEFL iBT 99/120",
        "en": "English, fluent (TOEFL iBT 99/120)"
      },
      {
        "id": "lang-es",
        "fr": "Espagnol, notions",
        "en": "Spanish, basic"
      }
    ]
  }
];

const UI = {
  "fr": {
    "nav": {
      "path": "Parcours",
      "projects": "Projets",
      "skills": "Compétences"
    },
    "print": "CV en PDF",
    "langSwitch": "English",
    "langSwitchLabel": "Switch to English",
    "themeLabel": "Changer de thème",
    "ctaProjects": "Voir mes 9 projets",
    "ctaPath": "Mon parcours",
    "curveCaption": "Cliquez sur une étape pour l'ouvrir dans le parcours.",
    "pathTitle": "Parcours",
    "pathIntro": "Expériences et formation dans l'ordre chronologique, avec les projets réalisés à chaque étape.",
    "legendWork": "Expérience",
    "legendEdu": "Formation",
    "now": "Poste actuel",
    "projectsDone": "Projets réalisés",
    "summerJobs": "Jobs d'été (2020 à 2024)",
    "projectsTitle": "Projets",
    "projectsIntro": "Neuf projets réalisés pendant mes études à la Toulouse School of Economics. Chaque fiche renvoie au rapport complet et au code.",
    "all": "Tous",
    "featured": "Mémoire de fin d'études",
    "with": "Avec",
    "linkKinds": {
      "report": "Rapport",
      "code": "Code",
      "data": "Données",
      "html": "Rapport"
    },
    "skillsTitle": "Compétences",
    "showCourses": "Voir les cours",
    "hideCourses": "Masquer les cours",
    "footer": "Site mis à jour en octobre 2026.",
    "sparkCaption": "L'indicateur d'incertitude construit dans le mémoire, de 2016 à 2025.",
    "noProjects": "Aucun projet dans cette catégorie. Choisissez « Tous » pour tout afficher."
  },
  "en": {
    "nav": {
      "path": "Background",
      "projects": "Projects",
      "skills": "Skills"
    },
    "print": "PDF résumé",
    "langSwitch": "Français",
    "langSwitchLabel": "Passer en français",
    "themeLabel": "Toggle theme",
    "ctaProjects": "See my 9 projects",
    "ctaPath": "My background",
    "curveCaption": "Click a step to open it in the timeline.",
    "pathTitle": "Background",
    "pathIntro": "Experience and education in chronological order, with the projects completed at each step.",
    "legendWork": "Experience",
    "legendEdu": "Education",
    "now": "Current role",
    "projectsDone": "Projects completed",
    "summerJobs": "Summer jobs (2020 to 2024)",
    "projectsTitle": "Projects",
    "projectsIntro": "Nine projects completed during my studies at Toulouse School of Economics. Each card links to the full report and the code.",
    "all": "All",
    "featured": "Master's thesis",
    "with": "With",
    "linkKinds": {
      "report": "Report",
      "code": "Code",
      "data": "Data",
      "html": "Report"
    },
    "skillsTitle": "Skills",
    "showCourses": "Show courses",
    "hideCourses": "Hide courses",
    "footer": "Site updated October 2026.",
    "sparkCaption": "The uncertainty indicator built in the thesis, 2016 to 2025.",
    "noProjects": "No project in this category. Choose “All” to see every project."
  }
};
