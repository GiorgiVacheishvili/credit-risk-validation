# Notebooks

Modelling, stability and explainability in Python (pandas, scikit-learn, LightGBM, SHAP).
Each notebook reads the cleaned data from PostgreSQL through SQLAlchemy. The database password
is entered with getpass and is not stored in the files.

| Notebook | What it does |
|---|---|
| 04_scorecard.ipynb | Logistic regression scorecard: preparation, AUC, Gini, KS, coefficients and odds ratios (finding 12) |
| 05_challenger.ipynb | LightGBM challenger in three versions, compared with the scorecard and checked for overfitting (finding 13) |
| 06_stability.ipynb | Population stability index (PSI) for the score and the main features, training data vs the Kaggle test file (finding 14) |
| 07_explanations.ipynb | SHAP explanations for LightGBM version 2: global importance, beeswarm, one customer's waterfall and the income pattern (finding 15) |

All notebooks use the same preparation and split: test size 0.3, stratified by default,
random_state 42.
