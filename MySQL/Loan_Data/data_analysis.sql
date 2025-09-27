-- 1. Loan Default Rate by Grade & Sub-grade (and by state).

SELECT
  grade,
  sub_grade,
  address_state,
  COUNT(*) AS total_loans,
  SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS charged_off_count,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / COUNT(*), 2) AS charged_off_pct
FROM loan_data
GROUP BY grade, sub_grade, address_state
ORDER BY grade, sub_grade, address_state;

-- OUTPUT SAMPLE:

| ----- | --------- | ------------- | ----------- | ----------------- | --------------- |
| grade | sub_grade | address_state | total_loans | charged_off_count | charged_off_pct |
| ----- | --------- | ------------- | ----------- | ----------------- | --------------- |
| A     |        A1 | IL            |           1 |                 0 |            0.00 |
| B     |        B2 | TX            |           1 |                 0 |            0.00 |
| C     |        C4 | GA            |           1 |                 1 |          100.00 |
| C     |        C5 | CA            |           1 |                 1 |          100.00 |
| E     |        E1 | CA            |           1 |                 0 |            0.00 |
| ----- | --------- | ------------- | ----------- | ----------------- | --------------- |


-- 2. Loan Amount by Income Bracket

SELECT
  CASE
    WHEN annual_income < 50000 THEN '<50k'
    WHEN annual_income >= 50000 AND annual_income < 100000 THEN '50k-100k'
    ELSE '100k+'
  END AS income_bracket,
  COUNT(*) AS loans_in_bracket,
  ROUND(AVG(loan_amount),2) AS avg_loan_amount,
  ROUND(MAX(loan_amount),2) AS max_loan_amount,
  ROUND(MIN(loan_amount),2) AS min_loan_amount
FROM loan_data
GROUP BY income_bracket
ORDER BY income_bracket;

-- OUTPUT SAMPLE:

| -------------- | ---------------- | --------------- | --------------- | --------------- |
| income_bracket | loans_in_bracket | avg_loan_amount | max_loan_amount | min_loan_amount |
| -------------- | ---------------- | --------------- | --------------- | --------------- |
| <50k           |                3 |         3500.00 |         4500.00 |         2500.00 |
| 50k-100k       |                2 |         7750.00 |        12000.00 |         3500.00 |
| 100k+          |                0 |            NULL |            NULL |            NULL |
| -------------- | ---------------- | --------------- | --------------- | --------------- |


-- 3. Loan Term vs Default Probability (36 vs 60 months)

SELECT
  TRIM(term) AS term,
  COUNT(*) AS total_loans,
  SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS charged_off_count,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS charged_off_pct,
  ROUND(AVG(installment),2) AS avg_installment,
  ROUND(AVG(total_payment),2) AS avg_total_payment
FROM loan_data
GROUP BY TRIM(term)
ORDER BY term;

-- OUTPUT SAMPLE:

| --------- | ----------- | ----------------- | --------------- | --------------- | ----------------- |
| term      | total_loans | charged_off_count | charged_off_pct | avg_installment | avg_total_payment |
| --------- | ----------- | ----------------- | --------------- | --------------- | ----------------- |
| 36 months |           3 |                 1 |           33.33 |          212.54 |           3765.33 |
| 60 months |           2 |                 1 |           50.00 |           78.45 |           2960.00 |
| --------- | ----------- | ----------------- | --------------- | --------------- | ----------------- |


-- 4. Employment Length & Default Behavior

SELECT
  emp_length,
  COUNT(*) AS total_loans,
  SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS charged_off_count,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS charged_off_pct
FROM loan_data
GROUP BY emp_length
ORDER BY
  -- order typical emp_length categories; fallback alphabetical
  CASE
    WHEN emp_length = '< 1 year' THEN 1
    WHEN emp_length = '1 year' THEN 2
    WHEN emp_length = '2 years' THEN 3
    WHEN emp_length = '3 years' THEN 4
    WHEN emp_length LIKE '%4 years%' THEN 5
    WHEN emp_length LIKE '%5 years%' THEN 6
    WHEN emp_length LIKE '%9 years%' THEN 7
    WHEN emp_length = '10+ years' THEN 8
    ELSE 99
  END;

-- OUTPUT SAMPLE:

| ---------- | ----------- | ----------------- | --------------- |
| emp_length | total_loans | charged_off_count | charged_off_pct |
| ---------- | ----------- | ----------------- | --------------- |
| < 1 year   |           2 |                 1 |           50.00 |
| 4 years    |           1 |                 1 |          100.00 |
| 9 years    |           1 |                 0 |            0.00 |
| 10+ years  |           1 |                 0 |            0.00 |
| ---------- | ----------- | ----------------- | --------------- |


-- 5. Loan Purpose & Risk Profile (default rate, avg loan amount, avg interest)

SELECT
  purpose,
  COUNT(*) AS total_loans,
  SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS charged_off_count,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS charged_off_pct,
  ROUND(AVG(loan_amount),2) AS avg_loan_amount,
  ROUND(AVG(int_rate),6) AS avg_int_rate
FROM loan_data
GROUP BY purpose
ORDER BY charged_off_pct DESC, total_loans DESC;

-- OUTPUT SAMPLE:

| ------- | ----------- | ----------------- | --------------- | --------------- | ------------ |
| purpose | total_loans | charged_off_count | charged_off_pct | avg_loan_amount | avg_int_rate |
| ------- | ----------- | ----------------- | --------------- | --------------- | ------------ |
| car     |           5 |                 2 |           40.00 |         6100.00 |     0.133950 |
| ------- | ----------- | ----------------- | --------------- | --------------- | ------------ |


-- 6. Payment Behavior Trend Over Time (monthly trend of avg interest & default rate)

SELECT
  DATE_FORMAT(STR_TO_DATE(issue_date, '%d-%m-%Y'), '%Y-%m') AS issue_month,
  COUNT(*) AS loans_issued,
  ROUND(AVG(int_rate),6) AS avg_int_rate,
  SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS charged_off_count,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS charged_off_pct
FROM loan_data
GROUP BY issue_month
ORDER BY issue_month;

-- OUTPUT SAMPLE:

| ----------- | ------------ | ------------ | ----------------- | --------------- |
| issue_month | loans_issued | avg_int_rate | charged_off_count | charged_off_pct |
| ----------- | ------------ | ------------ | ----------------- | --------------- |
| 2021-01     |            3 |     0.135433 |                 1 |           33.33 |
| 2021-02     |            2 |     0.119600 |                 1 |           50.00 |
| ----------- | ------------ | ------------ | ----------------- | --------------- |

-- 7. Monthly aggregates + 3-month rolling default rate

WITH CTE_parsed AS (
  SELECT
    id,
    STR_TO_DATE(issue_date, '%d-%m-%Y') AS issue_dt,
    int_rate,
    loan_status
  FROM loan_data
),
CTE_monthly AS (
  SELECT
    DATE_FORMAT(issue_dt, '%Y-%m') AS issue_month,
    COUNT(*) AS loans_issued,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS charged_off_count,
    AVG(int_rate) AS avg_int_rate
  FROM CTE_parsed
  GROUP BY issue_month
)
SELECT
  issue_month,
  loans_issued,
  charged_off_count,
  ROUND(100.0 * charged_off_count / NULLIF(loans_issued,0), 2) AS charged_off_pct,
  ROUND(avg_int_rate,6) AS avg_int_rate,
  -- 3-month rolling default rate (current month and 2 prior months)
  ROUND(
    100.0 * SUM(charged_off_count) OVER (ORDER BY issue_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
    / NULLIF(SUM(loans_issued) OVER (ORDER BY issue_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),0)
  ,2) AS rolling_3m_charged_off_pct
FROM CTE_monthly
ORDER BY issue_month;

-- OUTPUT SAMPLE:

| ----------- | ------------ | ----------------- | --------------- | ------------ | -------------------------- |
| issue_month | loans_issued | charged_off_count | charged_off_pct | avg_int_rate | rolling_3m_charged_off_pct |
| ----------- | ------------ | ----------------- | --------------- | ------------ | -------------------------- |
| 2021-01     |            3 |                 1 |           33.33 |     0.135433 |                      33.33 |
| 2021-02     |            2 |                 1 |           50.00 |     0.119600 |                      40.00 |
| ----------- | ------------ | ----------------- | --------------- | ------------ | -------------------------- |

-- 8. Rank loans by recovery rate within each grade

WITH CTE_rec AS (
  SELECT
    id,
    grade,
    loan_amount,
    total_payment,
    CASE WHEN loan_amount > 0 THEN total_payment / loan_amount ELSE NULL END AS recovery_rate
  FROM loan_data
)
SELECT
  id,
  grade,
  loan_amount,
  total_payment,
  ROUND(recovery_rate,4) AS recovery_rate,
  RANK() OVER (PARTITION BY grade ORDER BY recovery_rate DESC) AS recovery_rank_in_grade,
  PERCENT_RANK() OVER (PARTITION BY grade ORDER BY recovery_rate) AS recovery_percent_rank_in_grade
FROM CTE_rec
ORDER BY grade, recovery_rank_in_grade;

-- OUTPUT SAMPLE:

| ------- | ----- | ----------- | ------------- | ------------- | ---------------------- | ------------------------------ |
|      id | grade | loan_amount | total_payment | recovery_rate | recovery_rank_in_grade | recovery_percent_rank_in_grade |
| ------- | ----- | ----------- | ------------- | ------------- | ---------------------- | ------------------------------ |
| 1068350 | A     |        3500 |          3835 |        1.0957 |                      1 |                            0.0 |
| 1041756 | B     |        4500 |          4911 |        1.0913 |                      1 |                            0.0 |
| 1072053 | E     |        3000 |          3939 |        1.3130 |                      1 |                            0.0 |
| 1077430 | C     |        2500 |          1009 |        0.4036 |                      1 |                            0.0 |
| 1069243 | C     |       12000 |          3522 |        0.2935 |                      2 |                            1.0 |
| ------- | ----- | ----------- | ------------- | ------------- | ---------------------- | ------------------------------ |

-- 9. For each state, compute previous loan's interest rate

WITH CTE_parsed AS (
  SELECT
    id,
    address_state,
    STR_TO_DATE(issue_date, '%d-%m-%Y') AS issue_dt,
    int_rate
  FROM loan_data
)
SELECT
  id,
  address_state,
  DATE_FORMAT(issue_dt, '%Y-%m-%d') AS issue_date,
  int_rate AS current_int_rate,
  LAG(int_rate) OVER (PARTITION BY address_state ORDER BY issue_dt) AS prev_int_rate_in_state,
  CASE
    WHEN LAG(int_rate) OVER (PARTITION BY address_state ORDER BY issue_dt) IS NULL THEN NULL
    ELSE ROUND(int_rate - LAG(int_rate) OVER (PARTITION BY address_state ORDER BY issue_dt),6)
  END AS int_rate_change_from_prev
FROM CTE_parsed
ORDER BY address_state, issue_dt;

-- OUTPUT SAMPLE:

| ------- | ------------- | ---------- | ---------------- | ---------------------- | ------------------------- |
|      id | address_state | issue_date | current_int_rate | prev_int_rate_in_state | int_rate_change_from_prev |
| ------- | ------------- | ---------- | ---------------- | ---------------------- | ------------------------- |
| 1072053 |            CA | 2021-01-01 |           0.1864 |                   NULL |                      NULL |
| 1069243 |            CA | 2021-01-05 |           0.1596 |                 0.1864 |                 -0.026800 |
| 1077430 |            GA | 2021-02-11 |           0.1527 |                   NULL |                      NULL |
| 1041756 |            TX | 2021-02-25 |           0.1065 |                   NULL |                      NULL |
| 1068350 |            IL | 2021-01-01 |           0.0603 |                   NULL |                      NULL |
| ------- | ------------- | ---------- | ---------------- | ---------------------- | ------------------------- |

-- 10. Cumulative charged-off counts and cumulative default rate by grade

WITH CTE_grade_month AS (
  SELECT
    grade,
    STR_TO_DATE(issue_date, '%d-%m-%Y') AS issue_dt,
    CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END AS is_charged_off
  FROM loan_data
)
SELECT
  grade,
  DATE_FORMAT(issue_dt, '%Y-%m') AS issue_month,
  SUM(is_charged_off) AS charged_off_count_in_month,
  SUM(SUM(is_charged_off)) OVER (PARTITION BY grade ORDER BY DATE_FORMAT(issue_dt, '%Y-%m')) AS cumulative_charged_off,
  COUNT(*) AS loans_in_month,
  SUM(COUNT(*)) OVER (PARTITION BY grade ORDER BY DATE_FORMAT(issue_dt, '%Y-%m')) AS cumulative_loans,
  ROUND(
    100.0 * SUM(SUM(is_charged_off)) OVER (PARTITION BY grade ORDER BY DATE_FORMAT(issue_dt, '%Y-%m'))
    / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY grade ORDER BY DATE_FORMAT(issue_dt, '%Y-%m')),0)
  ,2) AS cumulative_charged_off_pct
FROM CTE_grade_month
GROUP BY grade, issue_month
ORDER BY grade, issue_month;

-- OUTPUT SAMPLE:

| ----- | ----------- | -------------------------- | ---------------------- | -------------- | ---------------- | -------------------------- |
| grade | issue_month | charged_off_count_in_month | cumulative_charged_off | loans_in_month | cumulative_loans | cumulative_charged_off_pct |
| ----- | ----------- | -------------------------- | ---------------------- | -------------- | ---------------- | -------------------------- |
| A     |     2021-01 |                          0 |                      0 |              1 |                1 |                       0.00 |
| B     |     2021-02 |                          0 |                      0 |              1 |                1 |                       0.00 |
| C     |     2021-02 |                          1 |                      1 |              1 |                1 |                     100.00 |
| C     |     2021-01 |                          1 |                      2 |              2 |                2 |                     100.00 |
| E     |     2021-01 |                          0 |                      0 |              1 |                1 |                       0.00 |
| ----- | ----------- | -------------------------- | ---------------------- | -------------- | ---------------- | -------------------------- |


-- 11. Standardize interest rate (z-score) within grade
-- [Compute mean and population stddev of `int_rate` for each `grade`. Then standardize (`z = (x - mean)/stddev`) to identify loans priced unusually high/low relative to their grade cohort.]

SELECT
  id,
  grade,
  int_rate,
  ROUND(AVG(int_rate) OVER (PARTITION BY grade),6) AS mean_int_rate_in_grade,
  ROUND(STDDEV_POP(int_rate) OVER (PARTITION BY grade),6) AS stddev_int_rate_in_grade,
  CASE
    WHEN STDDEV_POP(int_rate) OVER (PARTITION BY grade) = 0 THEN NULL
    ELSE ROUND( (int_rate - AVG(int_rate) OVER (PARTITION BY grade)) / STDDEV_POP(int_rate) OVER (PARTITION BY grade), 4)
  END AS int_rate_zscore_in_grade
FROM loan_data
ORDER BY grade, id;

-- OUTPUT SAMPLE:

| ------- | ----- | -------- | ---------------------- | ------------------------ | ------------------------ |
|      id | grade | int_rate | mean_int_rate_in_grade | stddev_int_rate_in_grade | int_rate_zscore_in_grade |
| ------- | ----- | -------- | ---------------------- | ------------------------ | ------------------------ |
| 1068350 | A     |   0.0603 |               0.060300 |                 0.000000 |                     NULL |
| 1041756 | B     |   0.1065 |               0.106500 |                 0.000000 |                     NULL |
| 1077430 | C     |   0.1527 |               0.156150 |                 0.003450 |                  -1.0000 |
| 1069243 | C     |   0.1596 |               0.156150 |                 0.003450 |                   1.0000 |
| 1072053 | E     |   0.1864 |               0.186400 |                 0.000000 |                     NULL |
| ------- | ----- | -------- | ---------------------- | ------------------------ | ------------------------ |

-- 12. Create quartile buckets (NTILE) on `annual_income` and show default density per bucket
-- [NTILE(4) breaks loans into 4 roughly-equal buckets by `annual_income`. Then compute charged-off density per quartile to check whether defaults concentrate in lower-income buckets.]

WITH CTE_incomes AS (
  SELECT
    id,
    annual_income,
    loan_status,
    NTILE(4) OVER (ORDER BY annual_income) AS income_quartile
  FROM loan_data
)
SELECT
  income_quartile,
  COUNT(*) AS loans_in_quartile,
  SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS charged_off_count,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),2) AS charged_off_pct,
  ROUND(AVG(annual_income),2) AS avg_annual_income
FROM CTE_incomes
GROUP BY income_quartile
ORDER BY income_quartile;

-- OUTPUT SAMPLE: (Quartile 1 contains the two smallest incomes: 30000 & 48000 average = 39000). With larger data, quartiles will be more balanced.)

| --------------- | ----------------- | ----------------- | --------------- | ----------------- |
| income_quartile | loans_in_quartile | charged_off_count | charged_off_pct | avg_annual_income |
| --------------- | ----------------- | ----------------- | --------------- | ----------------- |
|               1 |                 2 |                 1 |           50.00 |          39000.00 |
|               2 |                 1 |                 1 |          100.00 |          42000.00 |
|               3 |                 1 |                 0 |            0.00 |          50000.00 |
|               4 |                 1 |                 0 |            0.00 |          83000.00 |
| --------------- | ----------------- | ----------------- | --------------- | ----------------- |


-- 13. Compare each loan's interest rate to the average interest rate for the same state + purpose
  
SELECT
  ld1.id,
  ld1.address_state,
  ld1.purpose,
  ROUND(ld1.int_rate,6) AS int_rate,
  ROUND(
    (SELECT AVG(ld2.int_rate)
     FROM loan_data ld2
     WHERE ld2.address_state = ld1.address_state
       AND ld2.purpose = ld1.purpose
    ), 6
  ) AS avg_int_rate_state_purpose,
  ROUND(ld1.int_rate - (
    (SELECT AVG(ld2.int_rate)
     FROM loan_data ld2
     WHERE ld2.address_state = ld1.address_state
       AND ld2.purpose = ld1.purpose
    )
  ), 6) AS int_rate_diff,
  CASE
    WHEN ld1.int_rate > (SELECT AVG(ld2.int_rate) FROM loan_data ld2
                        WHERE ld2.address_state = ld1.address_state
                          AND ld2.purpose = ld1.purpose)
      THEN 'ABOVE'
    WHEN ld1.int_rate < (SELECT AVG(ld2.int_rate) FROM loan_data ld2
                        WHERE ld2.address_state = ld1.address_state
                          AND ld2.purpose = ld1.purpose)
      THEN 'BELOW'
    ELSE 'EQUAL'
  END AS cmp_to_state_purpose_avg
FROM loan_data ld1
ORDER BY ld1.address_state, ld1.id;

-- OUTPUT SAMPLE:

| ------- | ------------- | ------- | -------- | -------------------------- | ------------- | ------------------------ |
|      id | address_state | purpose | int_rate | avg_int_rate_state_purpose | int_rate_diff | cmp_to_state_purpose_avg |
| ------- | ------------- | ------- | -------- | -------------------------- | ------------- | ------------------------ |
| 1068350 |            IL | car     | 0.060300 |                   0.060300 |      0.000000 | EQUAL                    |
| 1072053 |            CA | car     | 0.186400 |                   0.173000 |      0.013400 | ABOVE                    |
| 1069243 |            CA | car     | 0.159600 |                   0.173000 |     -0.013400 | BELOW                    |
| 1077430 |            GA | car     | 0.152700 |                   0.152700 |      0.000000 | EQUAL                    |
| 1041756 |            TX | car     | 0.106500 |                   0.106500 |      0.000000 | EQUAL                    |
| ------- | ------------- | ------- | -------- | -------------------------- | ------------- | ------------------------ |


-- 14. Find loans whose recovery rate (total_payment / loan_amount) is below the average recovery rate of their grade

SELECT
  ld1.id,
  ld1.grade,
  ld1.loan_amount,
  ld1.total_payment,
  ROUND(CASE WHEN ld1.loan_amount <> 0 THEN ld1.total_payment / ld1.loan_amount ELSE NULL END, 6) AS recovery_rate,
  ROUND(
    (SELECT AVG(ld2.total_payment / NULLIF(ld2.loan_amount,0))
     FROM loan_data ld2
     WHERE ld2.grade = ld1.grade
    ), 6
  ) AS avg_recovery_rate_in_grade,
  ROUND(
    CASE WHEN ld1.loan_amount <> 0 THEN ld1.total_payment / ld1.loan_amount ELSE NULL END
    - (SELECT AVG(ld2.total_payment / NULLIF(ld2.loan_amount,0))
       FROM loan_data ld2
       WHERE ld2.grade = ld1.grade), 6
  ) AS recovery_diff_from_grade_avg
FROM loan_data ld1
WHERE
  ld1.loan_amount IS NOT NULL
  AND (ld1.total_payment / NULLIF(ld1.loan_amount,0)) < (
    SELECT AVG(ld2.total_payment / NULLIF(ld2.loan_amount,0))
    FROM loan_data ld2
    WHERE ld2.grade = ld1.grade
  )
ORDER BY ld1.grade, ld1.id;

-- OUTPUT SAMPLE:

| ------- | ----- | ----------- | ------------- | ------------- | -------------------------- | ---------------------------- |
|      id | grade | loan_amount | total_payment | recovery_rate | avg_recovery_rate_in_grade | recovery_diff_from_grade_avg |
| ------- | ----- | ----------- | ------------- | ------------- | -------------------------- | ---------------------------- |
| 1069243 |     C |       12000 |          3522 |      0.293500 |                   0.348550 |                    -0.055050 |
| ------- | ----- | ----------- | ------------- | ------------- | -------------------------- | ---------------------------- |


