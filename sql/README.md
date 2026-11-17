# SQL

Data quality checks, segment analysis and data cleaning in PostgreSQL.
Run the files in order. The Kaggle CSV files are not included (Kaggle's terms don't allow
redistribution); download them from the "Give Me Some Credit" competition.

| File | What it does |
|---|---|
| 01_data_quality.sql | Checks for missing values, impossible ages, extreme utilization and the 96/98 late-payment codes (findings 1–5) |
| 02_segments.sql | Default rates by age band, late_90 band and income decile; zero and extreme incomes (findings 6–9) |
| 03_clean_view.sql | Debt-ratio checks by income group, income percentiles and the credit_clean view used for modelling (findings 10–11) |
| 06_test_view.sql | Loads cs-test.csv into credit_test and creates credit_test_clean with the same cleaning rules, using the training values (finding 14) |

Tables and views:
- credit: the raw training data (150,000 customers)
- credit_clean: the cleaned training data (149,999 customers)
- credit_test: the raw Kaggle test data (101,503 customers, no default labels)
- credit_test_clean: the cleaned test data, used only for the stability check
