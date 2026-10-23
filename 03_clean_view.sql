-- =====================================================================
-- 03_clean_view.sql
-- Debt-ratio investigation, values for the clean view, and the
-- credit_clean modelling view with its checks
-- Give Me Some Credit (150,000 customers)
-- =====================================================================


-- ---------------------------------------------------------------------
-- 10. Debt ratios
-- ---------------------------------------------------------------------

-- Top 3 debt ratios per age band, with each customer's income compared
-- to their band's average income (window functions)
WITH bands AS (
    SELECT customer_id,
           age,
           monthly_income,
           debt_ratio,
           FLOOR(age / 10.0) * 10 AS age_band,
           ROUND(AVG(monthly_income) OVER (PARTITION BY FLOOR(age / 10.0) * 10), 0) AS band_avg_income,
           RANK() OVER (PARTITION BY FLOOR(age / 10.0) * 10 ORDER BY debt_ratio DESC) AS debt_rank
    FROM credit
    WHERE monthly_income IS NOT NULL AND age <> 0
)
SELECT age_band,
       debt_rank,
       customer_id,
       age,
       debt_ratio,
       monthly_income,
       band_avg_income,
       monthly_income - band_avg_income AS income_vs_band
FROM bands
WHERE debt_rank <= 3
ORDER BY age_band, debt_rank;

-- Median debt ratio and default rate by income band:
-- shows where debt_ratio stops being a realistic ratio
SELECT CASE
           WHEN monthly_income IS NULL THEN '0: missing'
           WHEN monthly_income = 0 THEN '1: zero'
           WHEN monthly_income < 10 THEN '2: under 10'
           WHEN monthly_income < 100 THEN '3: 10-99'
           WHEN monthly_income < 500 THEN '4: 100-499'
           WHEN monthly_income < 1000 THEN '5: 500-999'
           ELSE '6: 1000+'
       END AS income_band,
       COUNT(*) AS customers,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY debt_ratio)::numeric, 2) AS median_debt_ratio,
       ROUND(AVG(serious_delinquency) * 100.0, 2) AS default_rate
FROM credit
GROUP BY 1
ORDER BY 1;


-- ---------------------------------------------------------------------
-- 9. Values used in the clean view
-- ---------------------------------------------------------------------

-- Median (fill value) and 99th percentile (cap) of monthly_income.
-- PERCENTILE_CONT skips NULLs; COUNT(monthly_income) shows how many
-- values were used (120,269)
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_income) AS median,
       PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY monthly_income) AS p99,
       COUNT(monthly_income) AS customers_with_income
FROM credit;


-- ---------------------------------------------------------------------
-- 11. Clean modelling view
-- ---------------------------------------------------------------------

DROP VIEW IF EXISTS credit_clean;

CREATE VIEW credit_clean AS
SELECT customer_id,
       serious_delinquency,
       age,
       revolving_utilization,
       open_credit_lines,
       real_estate_loans,

       -- flags (findings 2 and 9)
       CASE WHEN monthly_income IS NULL THEN 1 ELSE 0 END AS missing_income,
       CASE WHEN monthly_income = 0 THEN 1 ELSE 0 END AS zero_income,

       -- fill missing income with the median, cap at the 99th percentile (findings 2 and 9)
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

FROM credit
WHERE age <> 0;   -- exclude the age-0 record (finding 1)


-- ---------------------------------------------------------------------
-- Checks on the view
-- ---------------------------------------------------------------------
-- Expected: 149,999 rows; max late_90 = 17; max income = 25,000;
-- 32,424 NULL debt ratios (= 29,731 + 1,634 + 617 + 26 + 416, finding 10)
SELECT COUNT(*) AS customers,
       MAX(late_90) AS max_late_90,
       MAX(monthly_income) AS max_monthly_income,
       COUNT(*) - COUNT(debt_ratio) AS null_debt_ratios
FROM credit_clean;