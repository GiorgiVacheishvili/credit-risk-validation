## 1. Summary
I validated a credit scoring model on 150,000 customers from the Kaggle "Give Me Some Credit"
dataset. The data had some unrealistic values, so it was cleaned, and risky groups that looked
like errors (such as missing income, very high revolving utilization and the 96/98 codes)
were flagged rather than dropped. Then logistic regression and three versions of LightGBM
were trained on the clean data. Logistic regression (Gini 0.707) performed only slightly
worse than the best LightGBM version (Gini 0.731) and did not overfit, so it is recommended
as the main model, with LightGBM version 2 as the challenger. The stability check showed no
shift between the training data and the Kaggle test file (PSI 0.0001), suggesting they come
from the same source, and the SHAP explanations mostly agreed with the scorecard, with
revolving utilization, late payments and age as the main predictors. The main limitation is
that it is not known how the models would perform on customers from a later period, so the
main recommendation is to validate them on newer data before use.

## 2. Data and preparation
The data comes from the Kaggle "Give Me Some Credit" dataset. The training file
(cs-training.csv) contains 150,000 customers with an overall default rate of 6.68%
(10,026 defaults). I split it into 70% training and 30% test data to build and test the
models. The second file (cs-test.csv, 101,503 customers) has no default labels, so I used
it only for the stability check (section 5).

The main principle of the cleaning: groups that looked like data errors but showed high
default rates were flagged rather than dropped, so the models keep the information they
carry.

| Issue                                                                  | Evidence                                                                                                                             | Treatment                                                                                                                                       |
|------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| Age 0 (1 customer)                                                     | The only customer under 21; not a valid borrower age, likely a placeholder                                                           | Row dropped                                                                                                                                     |
| Missing income (29,731 customers, 19.82%)                              | Default rate 5.61%, compared with 6.95% for customers with income                                                                    | Filled with the median (5,400) and flagged with missing_income                                                                                  |
| Zero income (1,634 customers)                                          | Default rate 4.04%, compared with 8.44% for the first income decile; zero may be a placeholder                                       | Kept as 0 and flagged with zero_income                                                                                                          |
| Extreme incomes (up to 3,008,750)                                      | Plausible for a low-risk group, but extreme values distort the model                                                                 | Capped at 25,000 (the 99th percentile)                                                                                                          |
| Revolving utilization above 1 (3,321 customers, 2.21%; maximum 50,708) | Default rate 39.8% above 1.05 (1,926 customers), compared with 6.25% at or below                                                     | Flagged with high_utilization and capped at 1; Gini rose from 0.648 to 0.707                                                                    |
| 96/98 codes in the late-payment columns (269 customers, 0.18%)         | Same value in all three columns, far above the real maximum (13, 11 and 17); default rate 54.65%, compared with 6.60% for the others | Set to NULL and flagged with late_code_flag; NULLs filled with 0 before modelling                                                               |
| Debt ratio inflated by missing or very low income                      | Median debt ratio of 1,159 for customers with missing income and 930 for those with zero income                                      | Set to NULL when income is missing or below 500 (32,424 customers); filled with the median and flagged with debt_ratio_missing before modelling |
| Missing dependents (3,924 customers, 2.62%)                            | Every customer with missing dependents also has missing income                                                                       | Filled with 0; no separate flag needed, as missing_income already marks them                                                                    |

## 3. Models
I trained two types of models on the cleaned data: logistic regression and gradient boosted
trees (LightGBM).

Logistic regression is the main model (the scorecard). Banks use it because it is easy to
interpret: each feature has one coefficient, which can be turned into an odds ratio showing
how much it raises or lowers the probability of default. Its limitation is that it assumes
each feature has a straight-line effect on the log-odds, so it cannot capture bends (such as
the income pattern in section 5) or combinations of features unless they are built in by
hand. The features were standardised, with the scaler fitted on the training data only.

LightGBM is the challenger model. It builds many small decision trees, so it can find bends
and combinations on its own, but it needs an explainability tool such as SHAP to show why it
makes a prediction. I tested three configurations. Version 1 overfitted: its training AUC
was much higher than its test AUC. Version 2 fixed this with simpler trees (fewer trees,
15 leaves and at least 200 customers per leaf), bringing the training and test AUC close
together. Version 3 kept version 1's settings and only lowered
the learning rate to 0.01; it reached the same test AUC, which suggests the performance has
reached a plateau.

Version 2 performed slightly better than logistic regression (section 4), but the gain is
small compared with the loss of interpretability. Therefore logistic regression is used as
the main model, and LightGBM version 2 as the challenger to check that the scorecard is not
missing important patterns.

## 4. Performance
| Model               | Train AUC   | Test AUC   | Test Gini   | Train–test gap   |
|---------------------|-------------|------------|-------------|------------------|
| Logistic regression | 0.851       | 0.854      | 0.707       | -0.003           |
| LightGBM v1         | 0.922       | 0.862      | 0.725       | 0.060            |
| LightGBM v2         | 0.882       | 0.866      | 0.731       | 0.016            |
| LightGBM v3         | 0.883       | 0.866      | 0.731       | 0.017            |

LightGBM version 1 has the highest training AUC (0.922), but its gap of 0.060 between
training and test AUC shows that it overfitted. Versions 2 and 3 fixed this in two different
ways: version 2 simplified the trees (fewer trees, fewer leaves and at least 200 customers per
leaf), while version 3 kept version 1's settings and only lowered the learning rate. Both
reduced the gap (0.016 and 0.017) and reached the same higher test AUC (0.866) and Gini
(0.731). Since they perform the same, version 2 is chosen as the challenger because it is the
simpler model. Reaching the same test AUC by two different routes also suggests that 0.866 is
close to the ceiling for this data with these features.

Logistic regression is not far behind, with a Gini only 0.024 lower than version 2 and no
overfitting (gap -0.003). For this reason, its interpretability is worth more than the
small performance gain from LightGBM.

## 5. Stability and explainability
To check stability, I retrained the logistic regression and compared its scores on the
training data with its scores on the Kaggle test file (cs-test.csv) using the population
stability index (PSI). Simple checks already showed that the two populations are very
similar (for example, missing income: 19.82% vs 19.81%). The PSI was 0.0001 for the score and between 0.0001 and 0.0003 for
the main features, far below the 0.10 threshold for a stable population, and the mean PD was
almost identical (6.685% vs 6.681%). This suggests that both files are a random split of the
same population and time period. It confirms that the data is consistent, but it cannot test
whether the model stays stable over time (section 6).

To explain the challenger, I used SHAP on LightGBM version 2. The main driver of the default
probability is revolving_utilization, followed by late_30_59, age and late_90: older
customers have lower risk, younger customers higher risk, and late payments push the risk up,
with late_90 having an even bigger effect than revolving_utilization for some customers.
These are the same core features as in the logistic regression, so the two models largely
agree. The main difference is income: SHAP shows that the risk first rises with income,
peaking at around 2,000-3,500, and then falls. LightGBM can capture this bend but logistic
regression cannot, which explains part of its small performance gain. SHAP also explains
individual predictions: for the highest-risk customer (PD 0.844), the main drivers were
four 90-day late payments, a fully used credit limit and two 60-89-day late payments.

## 6. Limitations and recommendations

Limitations:
- No test over time: the data has no dates, and the test file comes from the same population
  and period as the training data. The stability check confirms the data is consistent, but it
  cannot show whether the model would still perform well on future customers.
- Unknown data definitions: the data is public, so the country, the time period and the exact
  meaning of fields such as income or the 96/98 codes are not documented. These had to be
  inferred from the data itself.
- Untested assumptions: the reason some customers report zero income remains untested, and the
  cleaning choices (median fill for missing income, capping at the 99th percentile) were
  reasonable but not compared with alternatives.
- Overlapping features: missing_income and debt_ratio_missing overlap almost completely, so
  their individual coefficients in the logistic regression cannot be interpreted on their own.
- One train/test split: all results come from a single split (random_state 42), so it is not
  known how much the performance numbers would vary with a different split.
- Age as a feature: age is one of the strongest predictors, but its use in lending decisions
  can be restricted by regulation.

Recommendations:
- Use logistic regression as the main model and LightGBM version 2 as the challenger. The
  scorecard is easier to interpret and performs only slightly worse (0.024 Gini), while the
  challenger checks that it is not missing important patterns.
- Before use, validate the model on newer data (an out-of-time test) to confirm it performs
  well on later customers.
- Once in use, monitor the PSI of the score and the main features regularly (for example
  quarterly), and review the model if the PSI rises above 0.10.
- Confirm the meaning of the 96/98 codes and the zero incomes with the data owners, and check
  the use of age with the compliance team.
- Repeat the performance tests with cross-validation to measure how stable the results are.
