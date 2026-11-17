# Credit Risk Model Validation

Independent project validating a credit scoring model on 150,000 consumer-credit records
(Kaggle "Give Me Some Credit"), with data work in PostgreSQL and modelling in Python.

## Key results
- Data quality: groups that looked like data errors but carried high default rates (for
  example the 96/98 late-payment codes, with a 54.65% default rate) were flagged rather than
  dropped.
- Scorecard (logistic regression): test AUC 0.854, Gini 0.707, no overfitting.
  Capping revolving utilization at 1 raised the Gini from 0.648 to 0.707.
- Challenger (LightGBM version 2): test AUC 0.866, Gini 0.731, after fixing the first
  version's overfitting.
- Stability: PSI of 0.0001 for the score between the training data and the Kaggle test file.
- Explainability: SHAP shows that both models rely on the same core features
  (revolving utilization, late payments and age).
- Recommendation: logistic regression as the main model, with LightGBM version 2 as the
  challenger.

The full write-up is in [report/validation_report.md](report/validation_report.md).

## Project structure
| Folder | Contents |
|---|---|
| [sql/](sql/) | Data quality checks, segment analysis and the cleaned views in PostgreSQL |
| [notebooks/](notebooks/) | Logistic regression, LightGBM, PSI stability check and SHAP explanations |
| [report/](report/) | The validation report and the detailed working notes (findings 1–15) |

## Progress
- [x] Data quality checks
- [x] Segment analysis
- [x] Clean modelling view
- [x] Logistic regression scorecard
- [x] LightGBM challenger
- [x] Stability check (PSI)
- [x] SHAP explanations
- [x] Validation report

## Tools
PostgreSQL (pgAdmin), Python (pandas, scikit-learn, LightGBM, SHAP, SQLAlchemy), Jupyter.

## Data
The data comes from the Kaggle competition "Give Me Some Credit". The CSV files are not
included in this repository, as Kaggle's terms don't allow redistribution. To reproduce the
project, download cs-training.csv and cs-test.csv from Kaggle and load them with the
SQL files in order.
