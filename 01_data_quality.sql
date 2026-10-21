-- =====================================================================
-- 01_data_quality.sql
-- Data quality checks: Give Me Some Credit (150,000 customers)
-- =====================================================================


-- ---------------------------------------------------------------------
-- 0. Overview
-- ---------------------------------------------------------------------

-- Number of defaults (1) vs non-defaults (0)
SELECT serious_delinquency, COUNT(*) AS customers
FROM credit
GROUP BY serious_delinquency;

-- Age range
SELECT COUNT(*), MIN(age), MAX(age), AVG(age)
FROM credit;


-- ---------------------------------------------------------------------
-- 1. Age
-- ---------------------------------------------------------------------

-- Customers younger than 21
SELECT COUNT(*) AS customers
FROM credit
WHERE age < 21;

-- Their actual age
SELECT customer_id, age
FROM credit
WHERE age < 21;


-- ---------------------------------------------------------------------
-- 2. Missing income
-- ---------------------------------------------------------------------

-- Customers with missing income
SELECT COUNT(*) AS customers
FROM credit
WHERE monthly_income IS NULL;

-- Defaults vs non-defaults, income missing vs present
SELECT monthly_income IS NULL AS income_missing,
       serious_delinquency,
       COUNT(*) AS customers
FROM credit
GROUP BY monthly_income IS NULL, serious_delinquency
ORDER BY income_missing, serious_delinquency;


-- ---------------------------------------------------------------------
-- 3. Revolving utilization
-- ---------------------------------------------------------------------

-- Range (should be roughly between 0 and 1)
SELECT MIN(revolving_utilization) AS lowest,
       MAX(revolving_utilization) AS highest
FROM credit;

-- Customers above 1
SELECT COUNT(*) AS customers
FROM credit
WHERE revolving_utilization > 1;

-- Customers above 1.05 (allowing for slight over-limit)
SELECT COUNT(*) AS customers
FROM credit
WHERE revolving_utilization > 1.05;

-- Defaults vs non-defaults, above vs at or below 1.05
SELECT revolving_utilization > 1.05 AS "higher_than_1.05",
       serious_delinquency,
       COUNT(*) AS customers
FROM credit
GROUP BY revolving_utilization > 1.05, serious_delinquency
ORDER BY "higher_than_1.05", serious_delinquency;


-- ---------------------------------------------------------------------
-- 4. Late-payment codes (96 and 98)
-- ---------------------------------------------------------------------

-- Distribution of late_90 (look for impossible values)
SELECT late_90, COUNT(*) AS customers
FROM credit
GROUP BY late_90
ORDER BY late_90;

-- Codes in each late-payment column
SELECT late_30_59, COUNT(*) AS customers
FROM credit
WHERE late_30_59 > 95
GROUP BY late_30_59;

SELECT late_60_89, COUNT(*) AS customers
FROM credit
WHERE late_60_89 > 95
GROUP BY late_60_89;

SELECT late_90, COUNT(*) AS customers
FROM credit
WHERE late_90 > 95
GROUP BY late_90;

-- Same customers in all three columns?
SELECT late_30_59, late_60_89, late_90, COUNT(*) AS customers
FROM credit
WHERE late_30_59 > 95 AND late_60_89 > 95 AND late_90 > 95
GROUP BY late_30_59, late_60_89, late_90;

-- Code in any column (equals 269, so the codes always appear together)
SELECT COUNT(*)
FROM credit
WHERE late_30_59 > 95 OR late_60_89 > 95 OR late_90 > 95;

-- Default rate, coded vs not coded
SELECT late_90 > 95 AS coded,
       COUNT(*) AS customers,
       SUM(serious_delinquency) AS defaults,
       ROUND(100.0 * AVG(serious_delinquency), 2) AS default_rate_pct
FROM credit
GROUP BY late_90 > 95
ORDER BY coded;


-- ---------------------------------------------------------------------
-- 5. Missing dependents
-- ---------------------------------------------------------------------

-- Customers with missing dependents
SELECT COUNT(*) - COUNT(dependents) AS missing_dependents
FROM credit;

-- Is missing dependents always together with missing income?
SELECT monthly_income IS NULL AS income_missing,
       dependents IS NULL AS dependents_missing,
       COUNT(*) AS customers
FROM credit
GROUP BY monthly_income IS NULL, dependents IS NULL
ORDER BY income_missing, dependents_missing;