USE db_sales;

SELECT * FROM db_sales.leads;
SELECT * FROM db_sales.sales;
SELECT * FROM db_sales.targets;

ALTER TABLE targets MODIFY COLUMN target DECIMAL(10, 2);  -- changing 'target' column's dtype to DECIMAL type
ALTER TABLE targets RENAME COLUMN target TO target_amt;   -- renaming col name to be different from table name
ALTER TABLE leads DROP postal_code;  -- dropping redundant column

SELECT *
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'db_sales'
AND TABLE_NAME = 'sales';

-- Get info on table's columns
DESCRIBE leads;
DESCRIBE sales;

ALTER TABLE sales DROP cust_id;  -- dropped 'cust_id' col as it was not an ID, rather just a SL. No.

-- Since 'sales' table doesn't have 'cust_id' col in it now, and we need an ID for each
-- customer, create a new table 'new_sales' as follows:
CREATE TABLE new_sales AS
SELECT
    L.cust_id
    , S.cust_name
    , S.sp_assigned
    , S.category
    , S.order_date
    , S.sales_amt 
FROM leads L JOIN sales S ON L.cust_name = S.cust_name; -- joining on 'cust_name' as all 'cust_name' vals in tbl 'leads' are unique

DROP TABLE sales;  -- Drop the current 'sales' table
ALTER TABLE new_sales RENAME sales;  -- Rename the 'new_sales' table to 'sales' table

-- Now 'sales' table has correct 'cust_id' column that matches 'cust_name' correctly with that in 'leads' table

-- 1. Calculate the sales by state in each region and leads' conversion count by state in each region 
-- with rollup applied (i.e. summary rows included).
SELECT
    L.region
    , L.state
    , SUM(S.sales_amt) AS state_sales
    , COUNT(S.cust_id) AS state_conversion_count
FROM leads L JOIN sales S ON L.cust_id = S.cust_id
GROUP BY region, state
ORDER BY region, state 
WITH ROLLUP ;   -- ROLLUP

-- More elegant query (NULLs of above query's output replaced by ALL STATES/ALL REGIONS)
SELECT
    IF(GROUPING(L.region), "ALL REGIONS", L.region) AS REGIONS   -- GROUPING fn
    , IF(GROUPING(L.state), "ALL STATES", L.state) AS STATES
    , SUM(S.sales_amt) AS state_sales
    , COUNT(S.cust_id) AS state_conversion_count
FROM leads L JOIN sales S ON L.cust_id = S.cust_id
GROUP BY L.region, L.state
WITH ROLLUP;


-- 2. Write a query to generate a sales report which must contain following info (grouped by first two columns of the report 'sales year' and 'sales month' extracted from the lead_date column of leads table):

-- ----- 1. Sales year
-- ----- 2. Sales month
-- ----- 3. Number of leads
-- ----- 4. Percent growth in no. of leads
-- ----- 5. Minimum sales amount
-- ----- 6. Maximum sales amount
-- ----- 7. Salesperson ( 'sp_assigned' column of leads table) who made maximum sales
-- ----- 8. Salesperson who made minimum sales
-- ----- 9. Category of maximum sales
-- ----- 10. City with highest average sales
-- ----- 11. State with highest average sales
-- ----- 12. Region with highest average sales

WITH CTE_lead_base AS (
    SELECT 
        cust_id,
        sp_assigned,
        city,
        state,
        region,
        lead_date,
        YEAR(lead_date) AS sales_year,
        MONTH(lead_date) AS sales_month
    FROM leads
),
CTE_lead_counts AS (
    SELECT 
        sales_year,
        sales_month,
        COUNT(cust_id) AS num_leads
    FROM CTE_lead_base
    GROUP BY sales_year, sales_month
    ORDER BY sales_year, sales_month
),
CTE_lead_growth AS (
    SELECT 
        sales_year,
        sales_month,
        num_leads,
        ROUND(COALESCE((num_leads - LAG(num_leads) OVER()) / LAG(num_leads) OVER() * 100, 0), 2) AS pct_lead_growth
    FROM CTE_lead_counts
),
CTE_sales_joined AS (
    SELECT 
        lb.sales_year,
        lb.sales_month,
        lb.city,
        lb.state,
        lb.region,
        s.sp_assigned,
        s.category,
        s.sales_amt
    FROM CTE_lead_base lb
    JOIN sales s ON lb.cust_id = s.cust_id
),
CTE_aggregates AS (
    SELECT 
        sales_year,
        sales_month,
        MIN(sales_amt) AS min_sales_amt,
        MAX(sales_amt) AS max_sales_amt
    FROM CTE_sales_joined
    GROUP BY sales_year, sales_month
),
CTE_sales_by_person AS (
    SELECT 
        sales_year,
        sales_month,
        sp_assigned,
        SUM(sales_amt) AS total_sales
    FROM CTE_sales_joined
    GROUP BY sales_year, sales_month, sp_assigned
),
CTE_sales_by_category AS (
    SELECT 
        sales_year,
        sales_month,
        category,
        SUM(sales_amt) AS total_sales
    FROM CTE_sales_joined
    GROUP BY sales_year, sales_month, category
),
CTE_city_avg_sales AS (
    SELECT 
        sales_year,
        sales_month,
        city,
        AVG(sales_amt) AS avg_sales
    FROM CTE_sales_joined
    GROUP BY sales_year, sales_month, city
),
CTE_state_avg_sales AS (
    SELECT 
        sales_year,
        sales_month,
        state,
        AVG(sales_amt) AS avg_sales
    FROM CTE_sales_joined
    GROUP BY sales_year, sales_month, state
),
CTE_region_avg_sales AS (
    SELECT 
        sales_year,
        sales_month,
        region,
        AVG(sales_amt) AS avg_sales
    FROM CTE_sales_joined
    GROUP BY sales_year, sales_month, region
),
CTE_max_min_sp AS (
    SELECT 
        sales_year,
        sales_month,
        MAX(total_sales) AS max_sp_sales,
        MIN(total_sales) AS min_sp_sales
    FROM CTE_sales_by_person
    GROUP BY sales_year, sales_month
),
CTE_sp_with_extreme_sales AS (
    SELECT 
        sbp.sales_year,
        sbp.sales_month,
        MAX(CASE WHEN sbp.total_sales = mm.max_sp_sales THEN sbp.sp_assigned END) AS max_sales_sp,
        MAX(CASE WHEN sbp.total_sales = mm.min_sp_sales THEN sbp.sp_assigned END) AS min_sales_sp
    FROM CTE_sales_by_person sbp
    JOIN CTE_max_min_sp mm 
        ON sbp.sales_year = mm.sales_year AND sbp.sales_month = mm.sales_month
    GROUP BY sbp.sales_year, sbp.sales_month
),
CTE_max_category AS (
    SELECT 
        sales_year,
        sales_month,
        category
    FROM (
        SELECT 
            sales_year,
            sales_month,
            category,
            RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY total_sales DESC) AS rnk
        FROM CTE_sales_by_category
    ) ranked
    WHERE rnk = 1
),
CTE_city_with_highest_avg AS (
    SELECT 
        sales_year,
        sales_month,
        city
    FROM (
        SELECT 
            sales_year,
            sales_month,
            city,
            RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY avg_sales DESC) AS rnk
        FROM CTE_city_avg_sales
    ) ranked
    WHERE rnk = 1
),
CTE_state_with_highest_avg AS (
    SELECT 
        sales_year,
        sales_month,
        state
    FROM (
        SELECT 
            sales_year,
            sales_month,
            state,
            RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY avg_sales DESC) AS rnk
        FROM CTE_state_avg_sales
    ) ranked
    WHERE rnk = 1
),
CTE_region_with_highest_avg AS (
    SELECT 
        sales_year,
        sales_month,
        region
    FROM (
        SELECT 
            sales_year,
            sales_month,
            region,
            RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY avg_sales DESC) AS rnk
        FROM CTE_region_avg_sales
    ) ranked
    WHERE rnk = 1
)

SELECT 
    lg.sales_year,
    lg.sales_month,
    lg.num_leads,
    lg.pct_lead_growth,
    ag.min_sales_amt,
    ag.max_sales_amt,
    spx.max_sales_sp,
    spx.min_sales_sp,
    mc.category AS max_sales_category,
    ca.city AS highest_avg_city,
    sa.state AS highest_avg_state,
    ra.region AS highest_avg_region
FROM CTE_lead_growth lg
LEFT JOIN CTE_aggregates ag ON lg.sales_year = ag.sales_year AND lg.sales_month = ag.sales_month
LEFT JOIN CTE_sp_with_extreme_sales spx ON lg.sales_year = spx.sales_year AND lg.sales_month = spx.sales_month
LEFT JOIN CTE_max_category mc ON lg.sales_year = mc.sales_year AND lg.sales_month = mc.sales_month
LEFT JOIN CTE_city_with_highest_avg ca ON lg.sales_year = ca.sales_year AND lg.sales_month = ca.sales_month
LEFT JOIN CTE_state_with_highest_avg sa ON lg.sales_year = sa.sales_year AND lg.sales_month = sa.sales_month
LEFT JOIN CTE_region_with_highest_avg ra ON lg.sales_year = ra.sales_year AND lg.sales_month = ra.sales_month
ORDER BY lg.sales_year, lg.sales_month;

+------------+-------------+-----------+-----------------+---------------+---------------+--------------+--------------+--------------------+------------------+-------------------+--------------------+
| sales_year | sales_month | num_leads | pct_lead_growth | min_sales_amt | max_sales_amt | max_sales_sp | min_sales_sp | max_sales_category | highest_avg_city | highest_avg_state | highest_avg_region |
+------------+-------------+-----------+-----------------+---------------+---------------+--------------+--------------+--------------------+------------------+-------------------+--------------------+
|       2022 |           1 |       134 |           0.00  |        414.75 |       1797.06 | Toby         | Kelly        | Copy Paper         | San Antonio      | Delaware          | East               |
|       2022 |           2 |       120 |         -10.45  |        400.00 |       3743.46 | Michael      | Meredith     | Copy Paper         | Columbia         | Tennessee         | South              |
|       2022 |           3 |       123 |           2.50  |        400.00 |       7040.73 | Michael      | Angela       | Copy Paper         | San Francisco    | Michigan          | West               |
|       2022 |           4 |       126 |           2.44  |        403.00 |       1511.35 | Pam          | Michael      | Copy Paper         | Oceanside        | Massachusetts     | South              |
|       2022 |           5 |       157 |          24.60  |        402.00 |       3782.78 | Ryan         | Andy         | Copy Paper         | Dublin           | Louisiana         | East               |
|       2022 |           6 |       136 |         -13.38  |        408.02 |       8403.96 | Toby         | Andy         | Copy Paper         | Louisville       | Kentucky          | South              |
+------------+-------------+-----------+-----------------+---------------+---------------+--------------+--------------+--------------------+------------------+-------------------+--------------------+





