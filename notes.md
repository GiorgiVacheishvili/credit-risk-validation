# Data quality findings

## 1. Age
Only one customer is younger than 21, with an age of 0.
Age 0 is not a valid borrower age. The cause is unknown (possibly an entry error, or a placeholder
for "not provided").
Suggested solution: as it is a single record, drop this row.

## 2. Missing income
29,731 customers have missing income, which is 19.82% of the customers.
Of these, 1,669 defaulted, so the default rate for customers with missing income is 5.6%.
The overall default rate is 6.68% (10,026 customers).

Customers with missing income: default rate 5.6%  (out of customers with missing income)
Customers with income:         default rate 6.95% (out of customers with income)

Customers with missing income default less often, so missingness carries information.
Suggested solution: replace the missing incomes with the median income of the other customers
and add a missing_income flag.

## 3. Revolving utilization
The lowest revolving utilization is 0, while the highest is 50,708.
3,321 customers have a revolving utilization above 1 (2.21% of customers).
Even though revolving utilization can be slightly higher than 1, values like 50,708 are not realistic.
If we allow for this and count only values higher than 1.05, there are 1,926 customers (1.28%),
which is a more realistic number.

Customers with revolving utilization >  1.05: default rate 39.8%
Customers with revolving utilization <= 1.05: default rate 6.25%

Since customers with revolving utilization above 1.05 show a much higher default rate,
dropping them is risky.
Suggested solution: keep and flag them.

## 4. Late-payment codes (96 and 98)
In the columns for being late 30–59, 60–89 and 90+ days, 5 customers are recorded as being
late 96 times and 264 customers as being late 98 times.
Confirmed that these are the same 269 customers in all three columns.

These values are not plausible counts:
- 96 and 98 are far beyond the number of times a customer can realistically be late;
- the values are identical in all three columns (late_30_59, late_60_89 and late_90);
- the largest values below 96 are 13, 11 and 17 for late_30_59, late_60_89 and late_90
  respectively, which leaves a large gap.
Together, these indicate that 96 and 98 are codes for something other than the number of
times a customer was late, such as unfilled or unknown data.

Customers with late_90 >  95: default rate 54.65%
Customers with late_90 <= 95: default rate 6.60%

Since the difference is large, the suggested solution is to set the 96/98 values to NULL in all
three late-payment columns and add a late_code_flag column (1 = coded customer), so the model
keeps the signal without treating the codes as counts and learns that this group is high-risk.

## 5. Missing dependents
3,924 customers have missing information about dependents (2.62% of customers).
There is no customer with missing dependents but present income: 25,807 customers are missing
only income, and 3,924 are missing both.
Suggested solution: fill the missing dependents with 0 and flag only missing_income,
since that flag also covers the customers with missing dependents.


# Segment analysis

## 6. Default rate by age
I grouped the customers into 10-year age bands (e.g. a 26-year-old customer belongs to the
20s band, a 45-year-old to the 40s band). The default rate peaks in the 20s band at 11.73%,
possibly reflecting financial instability early in a career (hypothesis, not tested), then
declines steadily to 1.93% in the 90s band.
The 100+ band shows 7.69%, but it contains only 13 customers: 7.69% is a single default out
of 13. With a sample this small, one default skews the result, so no conclusion can be drawn.
Note: the age-0 record was excluded (see finding 1).

## 7. Default rate by late_90
I grouped the customers by how many times they were 90 or more days late: 0 times, 1 time,
2–3 times and 4+ times. The default rates are 4.63%, 33.66%, 52.25% and 66.06% respectively,
so the default rate rises with every additional serious late payment.
The biggest jump is from 0 to 1 time: about a 7-fold increase after a single episode. This
makes late_90 likely one of the strongest predictors of default.
The 4+ band is much smaller than the others (604 customers), but with 399 defaults it is
large enough to learn from.
Note: customers with the codes 96 and 98 (269 customers, see finding 4) were excluded.

## 8. Default rate by income decile
I grouped the customers into 10 income deciles and calculated the default rate for each.
The highest default rate is 9.68%, in the second decile (income 2,005–3,000). Interestingly,
the first decile (income 0–2,005) has a lower default rate of 8.44%. After the second decile
the default rate falls steadily, reaching 4.47% in the tenth decile (income 11,666–3,008,750).
Income is therefore a good predictor of default, since the default rate falls as income rises,
apart from the lowest decile. The relationship is not monotonic at the bottom.

Hypothesis: the first decile contains customers who report an income of 0, possibly because
they have informal income, and they may lower the decile's default rate.
Test: 1,634 of the 12,027 customers in the first decile report an income of 0, and their default
rate is 4.04%, about half of the decile's 8.44%. Re-computing the deciles without the zero
incomes gives 9.09% for the first decile and 9.87% for the second, closer than the previous
8.44% and 9.68%.
The hypothesis is partly supported: removing the zero-income customers narrows the gap, but the
first decile still has a slightly lower default rate than the second. The reason customers
report zero income remains untested.

Very high incomes: customers with a monthly income above 100,000 have a default rate of 4.29%
(70 customers, i.e. 3 defaults, a small sample), compared with 6.95% for the other customers
with income.

## 9. Zero and extreme incomes
1,634 customers report exactly 0 income (4.04% default rate vs 8.44% for decile 1). Zero may be
a placeholder rather than the real income.
Suggested solution: add a zero_income flag.
Very high incomes (up to 3,008,750) are plausible for a low-risk group but extreme in value.
Suggested solution: cap income at the 99th percentile before modelling.

Values used: the median and 99th percentile of monthly_income are calculated from the 120,269
customers with a recorded income (missing values are skipped). The median is 5,400 and the
99th percentile is 25,000. In the clean view, missing incomes are filled with 5,400 and incomes
are capped at 25,000, so the extreme values (up to 3,008,750) don't distort the model while the
customers stay in the data.

## 10. Debt ratios
Ranking customers by debt_ratio within each age band showed that the highest debt ratios belong
to customers with zero or very small incomes. Since debt_ratio is monthly debt payments divided by
monthly income, a zero or very small income makes the ratio meaningless.

To find where debt_ratio stops being realistic, I calculated the median debt_ratio for groups of
customers with different incomes:

Income missing: 29,731 customers, median debt ratio 1,159
Income 0:        1,634 customers, median debt ratio 930
Income 1–9:        617 customers, median debt ratio 561
Income 10–99:       26 customers, median debt ratio 23.48
Income 100–499:    416 customers, median debt ratio 1.36
Income 500–999:  1,735 customers, median debt ratio 0.46

- 10–99: even though these are only 26 customers, a typical debt ratio of 23.48 is impossible.
  These incomes were possibly used as placeholders (hypothesis).
- 100–499: 1.36 is possible for some individuals, but a person cannot pay 36% more than their
  income in debt for long, so it cannot be typical of a group of 416 customers.
- 500–999: the median returns to a normal value (below 1).
- Missing income: there is no income to divide the debt by, yet these customers still have a
  debt_ratio, so the values probably show the raw debt amount rather than a ratio (hypothesis).

Suggested solution: debt_ratio is reliable from an income of 500 upwards. Set debt_ratio to NULL
when income is missing or below 500 (which includes zero). The missing_income and zero_income
flags already mark most of these customers.


# Clean modelling view

## 11. Clean modelling view (credit_clean)
The view applies findings 1–10 in one query:
- customers whose monthly_income is not recorded are flagged with missing_income (finding 2)
- customers whose monthly_income is 0 are flagged with zero_income (finding 9)
- if monthly_income is not recorded it is set to 5,400 (the median), and monthly_income is capped at 25,000
  (the 99th percentile) (findings 2 and 9)
- if monthly_income is not recorded or is less than 500, debt_ratio is set to NULL (finding 10)
- customers with a revolving_utilization higher than 1.05 are flagged with high_utilization (finding 3)
- customers with a value above 95 (codes 96/98) in late_90 are flagged with late_code_flag (finding 4)
- values above 95 in late_30_59, late_60_89 and late_90 are set to NULL (finding 4)
- if dependents is not recorded, the value is set to 0 (finding 5)
- the age-0 record is excluded (finding 1)

Checks that have been done:
- number of customers is 149,999 (150,000 minus the age-0 record)
- maximum late_90 is 17 (codes removed)
- maximum monthly_income is 25,000 (cap applied)
- NULL debt_ratio values: 32,424 = 29,731 missing + 1,634 zero + 617 (1–9) + 26 (10–99) + 416 (100–499),
  matching finding 10 exactly

# Modelling

## 12. Logistic regression: which information predicts default
Reading the clean view into Python gives 149,999 rows (customers) and 16 columns.
Of these customers, 32,424 have debt_ratio set to NULL, and 269 have late_30_59, late_60_89 and
late_90 set to NULL.

Preparation:
- I filled the missing values in late_30_59, late_60_89 and late_90 with 0, since these customers
  are already flagged with late_code_flag.
- I added a debt_ratio_missing flag and filled the missing debt_ratio values with the median
  debt_ratio, so the model doesn't skip these customers while learning.
- I split the data into training and test parts with a test size of 0.3, stratified by default so
  both parts keep the 6.7% default rate, with random_state set to 42.
- StandardScaler standardises each feature to mean 0 and standard deviation 1. It is fitted on the
  training data only, before the logistic regression.

First model: AUC 0.824, Gini 0.648, KS 0.505.

Looking at the coefficients and odds ratios, late_90 is the strongest risk factor, with late_30_59
and missing_income second and third.
Customers with missing income defaulted less in finding 2, so the positive sign of missing_income
contradicts that finding. The reason is that it overlaps almost completely with debt_ratio_missing
(-0.39); together their effect is about -0.06, slightly lower risk. Individual coefficients of
overlapping features can't be read on their own (multicollinearity). zero_income has almost no
effect for the same reason.
debt_ratio_missing, age and monthly_income are the features that lower risk.

revolving_utilization had almost no effect on the prediction, even though realistically it should
be a strong predictor, and it ranked several places below the high_utilization flag I introduced.
The likely reason is its extreme values and very large range: because of them, values like 0.9 or 1
looked small to the model.
After this discovery, I capped revolving_utilization at 1, so the model can see values like 0.9 or 1
as high.

Model after capping: AUC 0.854, Gini 0.707, KS 0.549, a clear improvement.
revolving_utilization is now the strongest risk factor in the model.

## 13. LightGBM challenger compared with logistic regression
The training/test split is the same as for the scorecard: test size 0.3, stratified by default,
random_state 42. This time I used a LightGBM classifier with the following parameters:
- n_estimators = 500
- learning_rate = 0.05
- num_leaves = 31
- random_state = 42
- verbose = -1

This model gives AUC 0.862, Gini 0.725 and KS 0.578. Gini, the measure I use to compare the models,
is higher than the logistic regression's 0.707. The slight increase is expected, because logistic
regression can't capture how a feature affects default when the relationship isn't a straight line.
For example, LightGBM was possibly able to capture finding 8, where the default rate first increases
from the first to the second income decile and then decreases (not verified). This is possible
because trees can capture non-linear patterns.

However, comparing the AUC on the training data (0.922) with the test data (0.862) shows a difference
of 0.06. This is too big: the high training AUC implies that the model overfit and learned the
training data too well. For comparison, the scorecard's gap is -0.003, so it doesn't overfit.
Therefore I tried two modified versions of the model.

Version 2 (learning_rate kept at 0.05):
- decreased n_estimators to 300
- decreased num_leaves to 15
- added min_child_samples = 200
This version decreased the AUC difference to 0.016 (train 0.882, test 0.866), with Gini 0.731,
still higher than the logistic regression.

Version 3:
- decreased learning_rate to 0.01
This version also decreased the AUC difference, to 0.017 (train 0.883, test 0.866), with Gini 0.731
again.

Conclusion:
LightGBM is better than logistic regression by a slight margin (+0.024 Gini), but because logistic
regression has better interpretability, I would choose logistic regression as the main model and
use LightGBM as a benchmark.
Between versions 2 and 3, neither of which overfits, I would choose version 2, as it is the more
constrained model: fewer trees, fewer leaves and more customers per leaf.
Also, since versions 2 and 3 reach exactly the same test AUC of 0.866 by two different routes, it is
reasonable to conclude that this is close to the ceiling for this data with these features.