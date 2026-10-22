-- =====================================================================
-- 02_segments.sql
-- Segment analysis: default rates by age, late payments and income
-- Give Me Some Credit (150,000 customers)
-- =====================================================================


-- ---------------------------------------------------------------------
-- Overall default rate (baseline for every comparison below)
-- ---------------------------------------------------------------------
SELECT SUM(serious_delinquency) AS defaults_total,
       ROUND(AVG(serious_delinquency) * 100.0, 2) AS default_rate,
       COUNT(*) AS customers
FROM credit;


-- ---------------------------------------------------------------------
-- 6. Default rate by age (10-year bands)
-- ---------------------------------------------------------------------
-- Excludes the age-0 record (data quality finding 1)
SELECT FLOOR(age / 10.0) * 10 AS age_band,
       ROUND(AVG(serious_delinquency) * 100.0, 2) AS default_rate,
       COUNT(*) AS customers
FROM credit
WHERE age <> 0
GROUP BY age_band
ORDER BY age_band;


-- ---------------------------------------------------------------------
-- 7. Default rate by number of 90+ day late payments
-- ---------------------------------------------------------------------
-- Excludes the 96/98 codes (data quality finding 4)
SELECT CASE
           WHEN late_90 = 0 THEN '0 times'
           WHEN late_90 = 1 THEN '1 time'
           WHEN late_90 BETWEEN 2 AND 3 THEN '2-3 times'
           ELSE '4+ times'
       END AS late_90_band,
       SUM(serious_delinquency) AS defaults_total,
       ROUND(AVG(serious_delinquency) * 100.0, 2) AS default_rate,
       COUNT(*) AS customers
FROM credit
WHERE late_90 < 96
GROUP BY 1
ORDER BY 1;

-- Largest real values in each late-payment column (codes excluded),
-- used to show the gap between real counts and the 96/98 codes
SELECT MAX(late_90) AS max_late_90,
       MAX(late_60_89) AS max_late_60_89,
       MAX(late_30_59) AS max_late_30_59
FROM credit
WHERE late_90 < 96 AND late_60_89 < 96 AND late_30_59 < 96;


-- ---------------------------------------------------------------------
-- 8. Default rate by income decile
-- ---------------------------------------------------------------------
-- Income range and default rate per decile
WITH banded AS (
    SELECT monthly_income,
           serious_delinquency,
           NTILE(10) OVER (ORDER BY monthly_income) AS income_decile
    FROM credit
    WHERE monthly_income IS NOT NULL
)
SELECT income_decile,
       MIN(monthly_income) AS minimum_income,
       MAX(monthly_income) AS maximum_income,
       ROUND(AVG(serious_delinquency) * 100.0, 2) AS default_rate,
       COUNT(*) AS customers
FROM banded
GROUP BY income_decile
ORDER BY income_decile;

-- Hypothesis test: do zero-income customers lower decile 1's default rate?
-- (a) Number of customers reporting exactly 0 income
SELECT COUNT(*) AS customers
FROM credit
WHERE monthly_income = 0;

-- (b) Default rate of the zero-income customers in decile 1
WITH banded AS (
    SELECT monthly_income,
           serious_delinquency,
           NTILE(10) OVER (ORDER BY monthly_income) AS income_decile
    FROM credit
    WHERE monthly_income IS NOT NULL
)
SELECT ROUND(AVG(serious_delinquency) * 100.0, 2) AS default_rate,
       COUNT(*) AS customers
FROM banded
WHERE income_decile = 1 AND monthly_income = 0;

-- (c) Deciles re-computed without zero incomes
WITH banded AS (
    SELECT monthly_income,
           serious_delinquency,
           NTILE(10) OVER (ORDER BY monthly_income) AS income_decile
    FROM credit
    WHERE monthly_income IS NOT NULL AND monthly_income <> 0
)
SELECT income_decile,
       ROUND(AVG(serious_delinquency) * 100.0, 2) AS default_rate,
       COUNT(*) AS customers
FROM banded
GROUP BY income_decile
ORDER BY income_decile;


-- ---------------------------------------------------------------------
-- 9. Very high incomes
-- ---------------------------------------------------------------------
-- Default rate above vs at or below 100,000 per month
SELECT monthly_income > 100000 AS very_high_income,
       ROUND(AVG(serious_delinquency) * 100.0, 2) AS default_rate,
       COUNT(*) AS customers
FROM credit
WHERE monthly_income IS NOT NULL
GROUP BY very_high_income
ORDER BY very_high_income;