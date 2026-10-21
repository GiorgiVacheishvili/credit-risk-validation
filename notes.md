# Data quality findings

## 1. Age
Only one customer is younger than 21.
The age of that customer is 0, which is impossible and indicates a data entry error.
Suggested solution: drop this row.

## 2. Missing income
29,731 customers have missing income, which is 19.82% of the customers.
Of these, 1,669 defaulted, so the default rate for customers with missing income is 5.6%.
The overall default rate is 6.68% (10,026 customers).

Customers with missing income: default rate 5.6% (out of customers with missing income)
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
This is impossible, because the columns count how many times a customer was late within two years.
Even being late 96 times for 30–59 days is impossible: two years have 730 days, not 96 × 30.

Customers with late_90 > 95:   default rate 54.65%
Customers with late_90 <= 95:  default rate 6.60%

Since the difference is large, the suggested solution is to set the 96/98 values to NA in all
three late-payment columns and add a late_code_flag column (1 = coded customer), so the model
keeps the signal without treating the codes as counts and learns that this group is high-risk.

## 5. Missing dependents
3,924 customers have missing information about dependents (2.62% of customers).
There is no customer with missing dependents but present income: 25,807 customers are missing
only income, and 3,924 are missing both.
Suggested solution: fill the missing dependents with 0 and flag only missing_income,
since that flag also covers the customers with missing dependents.