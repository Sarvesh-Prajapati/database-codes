USE db_sales;

SELECT * FROM db_sales.leads;
SELECT * FROM db_sales.sales;
SELECT * FROM db_sales.targets;

-- ALTER TABLE leads DROP postal_code;

SELECT *
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'db_sales'
AND TABLE_NAME = 'sales';

-- Get info on table's columns
DESCRIBE leads;
DESCRIBE sales;

-- ALTER TABLE sales DROP cust_id;  -- dropped 'cust_id' col as it was not an ID, rather just a SL. No.

-- Since 'sales' table doesn't have 'cust_id' col in it now, and we need an ID for each
-- customer, create a new table 'new_sales' as follows:
CREATE TABLE new_sales AS
SELECT
	L.cust_id
    , S.cust_name
    , S.sp_assigned
    , S.category
    , S.order_date
    , S.sales 
FROM leads L JOIN sales S ON L.cust_name = S.cust_name; -- joining on 'cust_name' as all 'cust_name' vals in tbl 'leads' are unique

DROP TABLE sales;  -- Drop the current 'sales' table
ALTER TABLE new_sales RENAME sales;  -- Rename the 'new_sales' table to 'sales' table

-- Now 'sales' table has correct 'cust_id' column that matches 'cust_name' correctly with that in 'leads' table

-- 1. Calculate the sales by state in each region and leads' conversion count by state in each region.
SELECT
	L.region
    , L.state
    , SUM(S.sales) AS state_sales
    , COUNT(S.cust_id) AS state_conversion_count
FROM leads L JOIN sales S ON L.cust_id = S.cust_id
GROUP BY region, state
ORDER BY region, state;

-- 2. 













