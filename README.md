# Credit Risk Model Validation (in progress)

Independent project validating a credit scoring model on 150,000 consumer-credit
records (Kaggle "Give Me Some Credit"), with data work in PostgreSQL and modelling in Python.

## Progress
- [x] Data quality profile in SQL (five data issues found, sized and checked against default rates)
- [x] Default rates by segment (age bands, late payments, income deciles)
- [x] Clean modelling view in SQL (all fixes applied in one view, verified with reconciliation checks)
- [x] Logistic-regression scorecard in Python (AUC, Gini, KS)
- [x] LightGBM challenger model and side-by-side comparison
- [ ] Stability check (PSI against new applicants)
- [ ] SHAP explanations and agreement with the scorecard
- [ ] Validation report
