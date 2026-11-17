-- =====================================================================
-- 06_test_view.sql
-- New applicants (cs-test.csv): loading, quick comparison with the
-- training data, and the credit_test_clean view for the stability check
-- =====================================================================


-- ---------------------------------------------------------------------
-- Loading cs-test.csv
-- ---------------------------------------------------------------------
-- Same structure as the training table
CREATE TABLE credit_test (LIKE credit INCLUDING ALL);

-- The outcome column is empty in cs-test.csv (new applicants' defaults are
-- unknown). Load it as text first, then convert empty values to NULL.
ALTER TABLE credit_test ALTER COLUMN serious_delinquency TYPE text;

-- Run in the PSQL Tool (\copy is a psql command, not SQL):
-- \copy credit_test FROM '.../GiveMeSomeCredit/cs-test.csv' WITH (FORMAT csv, HEADER, NULL 'NA')

ALTER TABLE credit_test ALTER COLUMN serious_delinquency TYPE integer
USING NULLIF(serious_delinquency, '')::integer;


-- ---------------------------------------------------------------------
-- Quick comparison with the training data
-- ---------------------------------------------------------------------
-- Rows and known outcomes (expected: 101,503 rows, 0 with an outcome)
SELECT COUNT(*) AS customers,
       COUNT(serious_delinquency) AS with_outcome
FROM credit_test;

-- Missing income (result: 19.81%; training data: 19.82%)
SELECT COUNT(*) AS customers,
       COUNT(*) - COUNT(monthly_income) AS income_missing,
       ROUND(100.0 * (COUNT(*) - COUNT(monthly_income)) / COUNT(*), 2) AS share_income_missing
FROM credit_test;

-- 96/98 codes in late_90 (result: 214, i.e. 0.21%; training data: 269, i.e. 0.18%)
SELECT COUNT(*) AS coded_customers
FROM credit_test
WHERE late_90 IN (96, 98);


-- ---------------------------------------------------------------------
-- Clean view for new applicants
-- ---------------------------------------------------------------------
-- Same rules as credit_clean (03_clean_view.sql). The fill value (5,400)
-- and cap (25,000) are the TRAINING values, deliberately not recomputed
-- on the new applicants.

DROP VIEW IF EXISTS credit_test_clean;

CREATE VIEW credit_test_clean AS
SELECT customer_id,
       serious_delinquency,
       age,
       revolving_utilization,
       open_credit_lines,
       real_estate_loans,

       -- flags (findings 2 and 9)
       CASE WHEN monthly_income IS NULL THEN 1 ELSE 0 END AS missing_income,
       CASE WHEN monthly_income = 0 THEN 1 ELSE 0 END AS zero_income,

       -- fill missing income with the training median, cap at the training 99th percentile (findings 2 and 9)
       CASE WHEN monthly_income IS NULL THEN 5400
            WHEN monthly_income > 25000 THEN 25000
            ELSE monthly_income
       END AS monthly_income,

       -- debt_ratio only valid when income is recorded and at least 500 (finding 10)
       CASE WHEN monthly_income IS NULL OR monthly_income < 500 THEN NULL
            ELSE debt_ratio
       END AS debt_ratio,

       -- flag high utilisation, keep the value (finding 3)
       CASE WHEN revolving_utilization > 1.05 THEN 1 ELSE 0 END AS high_utilization,

       -- flag the 96/98 codes and set them to NULL (finding 4)
       CASE WHEN late_90 > 95 THEN 1 ELSE 0 END AS late_code_flag,
       CASE WHEN late_30_59 > 95 THEN NULL ELSE late_30_59 END AS late_30_59,
       CASE WHEN late_60_89 > 95 THEN NULL ELSE late_60_89 END AS late_60_89,
       CASE WHEN late_90 > 95 THEN NULL ELSE late_90 END AS late_90,

       -- fill missing dependents with 0 (finding 5)
       CASE WHEN dependents IS NULL THEN 0 ELSE dependents END AS dependents

FROM credit_test
WHERE age <> 0;   -- exclude age-0 records (finding 1); none among new applicants


-- ---------------------------------------------------------------------
-- Check
-- ---------------------------------------------------------------------
-- Expected: 101,503 (no age-0 applicants, so no rows removed)
SELECT COUNT(*) AS customers FROM credit_test_clean;
