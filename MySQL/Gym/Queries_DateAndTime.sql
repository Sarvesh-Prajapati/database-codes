# ------------ DATEDIFF, TIMESTAMPDIFF, and INTERVAL examples ---------------


-- ==============================
-- MySQL DATEDIFF() Examples
-- ==============================

-- Basic DATEDIFF
SELECT DATEDIFF('2025-05-10', '2025-05-01') AS diff_days; -- 9

-- Negative result
SELECT DATEDIFF('2025-05-01', '2025-05-10') AS result;  --  -9

-- Find overdue invoices
SELECT invoice_id, due_date,
       DATEDIFF(CURDATE(), due_date) AS days_overdue
FROM invoices
WHERE DATEDIFF(CURDATE(), due_date) > 0;

-- Filter records older than 30 days
SELECT * FROM orders WHERE DATEDIFF(CURDATE(), order_date) > 30;

-- Join tables using date difference
SELECT u.user_id, u.name, l.login_date, u.registration_date
FROM users u
JOIN logins l ON u.user_id = l.user_id
WHERE DATEDIFF(l.login_date, u.registration_date) <= 7;

-- Compare two date columns
SELECT task_id, start_date, end_date,
       DATEDIFF(end_date, start_date) AS duration
FROM tasks;


-- ==============================
-- MySQL TIMESTAMPDIFF() Examples
-- ==============================

-- Difference in years
SELECT TIMESTAMPDIFF(YEAR, '2010-06-01', '2025-05-01') AS diff_years;  -- 14

-- Difference in months
SELECT TIMESTAMPDIFF(MONTH, '2023-01-15', '2025-05-01') AS diff_months;  -- 27

-- Membership expiry warning (less than 3 months left)
SELECT member_id, 
       membership_end, 
       TIMESTAMPDIFF(MONTH, CURDATE(), membership_end) AS months_left
FROM some_members_table
WHERE TIMESTAMPDIFF(MONTH, CURDATE(), membership_end) < 3;


-- ==============================
-- MySQL INTERVAL Examples
-- ==============================

-- Add days to a date
SELECT DATE_ADD('2025-05-01', INTERVAL 10 DAY) AS new_date; -- 2025-05-11

-- Subtract months
SELECT DATE_SUB('2025-05-01', INTERVAL 2 MONTH) AS result_date; -- 2025-03-01

-- Add years to a date
SELECT DATE_ADD('2020-02-29', INTERVAL 5 YEAR) AS future_date; -- 2025-02-28

-- Get previous week's date
SELECT CURDATE() AS today, CURDATE() - INTERVAL 7 DAY AS last_week;
-- Output:
-- today:      2025-05-03
-- last_week:  2025-04-26

-- Filter records created in the last 30 days
SELECT record_created_at FROM some_table WHERE record_created_at >= CURDATE() - INTERVAL 30 DAY;

-- Find end of next month from a date (note the LAST_DAY() function here; very imp)
SELECT LAST_DAY(DATE_ADD('2025-02-01', INTERVAL 1 MONTH)) AS end_of_next_month;   -- 2025-03-31
SELECT LAST_DAY(DATE_SUB('2025-02-01', INTERVAL 3 MONTH)) AS end_of_month;  -- 2024-11-30
SELECT LAST_DAY('2024-02-01') AS end_of_month;  -- 2024-02-29  (accounts for leap year)


-- ==========================================
-- MySQL Composite INTERVAL Units Examples
-- ==========================================

-- Add 1 day and 1 hour using composite unit 
-- DAY_HOUR
SELECT DATE_ADD('2025-05-01 10:30:00', INTERVAL 1 DAY_HOUR) AS new_time; -- 2025-05-02 11:30:00
SELECT DATE_ADD('2025-05-01 10:30:00', INTERVAL '1 5' DAY_HOUR) AS result; -- 2025-05-02 15:30:00

-- YEAR_MONTH
SELECT DATE_ADD('2023-01-01', INTERVAL '2-3' YEAR_MONTH) AS result; -- 2025-04-01

-- DAY_MINUTE
SELECT DATE_ADD('2025-05-01 08:00:00', INTERVAL '2 04:30' DAY_MINUTE) AS result; -- 2025-05-03 12:30:00

-- DAY_SECOND
SELECT DATE_ADD('2025-05-01 06:00:00', INTERVAL '1 12:30:15' DAY_SECOND) AS result; -- 2025-05-02 18:30:15

-- HOUR_MINUTE
SELECT DATE_ADD('2025-05-01 00:00:00', INTERVAL '10:45' HOUR_MINUTE) AS result;  -- 2025-05-01 10:45:00

-- HOUR_SECOND
SELECT DATE_ADD('2025-05-01 01:00:00', INTERVAL '02:15:30' HOUR_SECOND) AS result;  -- 2025-05-01 03:15:30

-- MINUTE_SECOND
SELECT DATE_ADD('2025-05-01 00:00:00', INTERVAL '15:45' MINUTE_SECOND) AS result; -- 2025-05-01 00:15:45

-- SECOND_MICROSECOND
SELECT DATE_ADD('2025-05-01 00:00:00.000000', INTERVAL '10.123456' SECOND_MICROSECOND) AS result;  -- 2025-05-01 00:00:10.123456

-- MINUTE_MICROSECOND
SELECT DATE_ADD('2025-05-01 00:00:00.000000', INTERVAL '10:15.654321' MINUTE_MICROSECOND) AS result; -- 2025-05-01 00:10:15.654321

-- HOUR_MICROSECOND
SELECT DATE_ADD('2025-05-01 00:00:00.000000', INTERVAL '01:02:03.987654' HOUR_MICROSECOND) AS result;  -- 2025-05-01 01:02:03.987654

-- DAY_MICROSECOND
SELECT DATE_ADD('2025-05-01 00:00:00.000000', INTERVAL '1 01:02:03.456789' DAY_MICROSECOND) AS result; -- 2025-05-02 01:02:03.456789












