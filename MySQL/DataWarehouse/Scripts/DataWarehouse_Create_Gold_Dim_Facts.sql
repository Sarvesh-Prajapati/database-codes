
-- ################################################## CREATING VIEW FOR DIM 'customers' ############################################################

-- Extracting columns of tbl 'silver_crm_cust_info' as list to be pasted in subsequent SELECT of MAIN QUERY :
SELECT
	GROUP_CONCAT(CONCAT('ci.', COLUMN_NAME) ORDER BY ORDINAL_POSITION SEPARATOR '\n , ') AS col_list    -- 'ORDER BY ORDINAL_POSITION' returns col in order of their order in table
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'silver_crm_cust_info';

-- Listing the column names in order of their ordinal positions in the table :
-- SELECT COLUMN_NAME AS col_list FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_NAME = 'silver_crm_cust_info' ORDER BY ORDINAL_POSITION;      --   <-- Note this

-- MAIN QUERY (updated below)
SELECT
	ci.cust_id
	, ci.cust_key
	, ci.cust_firstname
	, ci.cust_lastname
	, ci.cust_marital_status
	, ci.cust_gender       -- not same gender as ca.gen below (as per o/p)
	, ci.cust_create_date
	, ci.dwh_create_date   -- not needed in gold layer (end-user needn't know this col)
	, ca.bdate
	, ca.gen               -- not same gender as ci.cust_gender above (as per o/p); has to be decided which value to keep as gender
	, la.cntry
FROM silver_crm_cust_info ci
LEFT JOIN silver_erp_cust_az12 ca ON ci.cust_key = ca.cid
LEFT JOIN silver_erp_loc_a101 la ON ci.cust_key = la.cid ;

-- Since CRM data is the master data in this project, take CRM vals for gender as correct vals for 'ci.cust_gender' v/s 'NA'
SELECT
	ci.cust_gender
	, ca.gen
	, CASE
		WHEN ci.cust_gender <> 'NA' THEN ci.cust_gender
		ELSE COALESCE(ca.gen, 'NA')
	END AS new_gen
FROM silver_crm_cust_info ci
LEFT JOIN silver_erp_cust_az12 ca ON ci.cust_key = ca.cid
LEFT JOIN silver_erp_loc_a101 la ON ci.cust_key = la.cid 
ORDER BY 1, 2 ;

-- Using CASE stmt from above query in MAIN QUERY, add friendly col aliases, shift columns around for better viewing, add primary key ('surrogate key' at this stage):
SELECT
	ROW_NUMBER() OVER(ORDER BY ci.cust_id) AS customer_key
	, ci.cust_id AS customer_id
	, ci.cust_key AS customer_number
	, ci.cust_firstname AS first_name
	, ci.cust_lastname AS last_name
	, la.cntry AS country
	, ci.cust_marital_status AS marital_status
	, CASE
		WHEN ci.cust_gender <> 'NA' THEN ci.cust_gender
		ELSE COALESCE(ca.gen, 'NA')
	END AS gender
	, ca.bdate AS birthdate
	, ci.cust_create_date AS create_date
FROM silver_crm_cust_info ci
LEFT JOIN silver_erp_cust_az12 ca ON ci.cust_key = ca.cid
LEFT JOIN silver_erp_loc_a101 la ON ci.cust_key = la.cid ;

-- Wrapping the above query in a VIEW (because at gold layer, views, not tables, are presented to end users)

DROP VIEW IF EXISTS gold_dim_customers;
CREATE VIEW gold_dim_customers AS
SELECT
	ROW_NUMBER() OVER(ORDER BY ci.cust_id) AS customer_key
	, ci.cust_id AS customer_id
	, ci.cust_key AS customer_number
	, ci.cust_firstname AS first_name
	, ci.cust_lastname AS last_name
	, la.cntry AS country
	, ci.cust_marital_status AS marital_status
	, CASE
		WHEN ci.cust_gender <> 'NA' THEN ci.cust_gender
		ELSE COALESCE(ca.gen, 'NA')
	END AS gender
	, ca.bdate AS birthdate
	, ci.cust_create_date AS create_date
FROM silver_crm_cust_info ci
LEFT JOIN silver_erp_cust_az12 ca ON ci.cust_key = ca.cid
LEFT JOIN silver_erp_loc_a101 la ON ci.cust_key = la.cid ;


-- ################################################### CREATING VIEW FOR DIM 'products' ############################################################

SELECT * FROM datawarehouse.silver_crm_prd_info;

SELECT
	GROUP_CONCAT(CONCAT('pn.', COLUMN_NAME) ORDER BY ORDINAL_POSITION SEPARATOR '\n , ') AS col_list    -- 'ORDER BY ORDINAL_POSITION' returns col in order of their order in table
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'silver_crm_prd_info';

-- Copying and pasting the col list generate by above query into the query below (will later evolve to MAIN QUERY) : 
-- SELECT
-- 	pn.prd_id
-- 	, pn.cat_id
-- 	, pn.prd_key
-- 	, pn.prd_nm
-- 	, pn.prd_cost
-- 	, pn.prd_line
-- 	, pn.prd_start_dt
-- 	, pn.prd_end_dt
-- 	, pn.dwh_create_date     -- this isn't needed in gold layer as end users needn't see it
-- FROM datawarehouse.silver_crm_prd_info pn ;

-- Updating the above query (into MAIN QUERY):
SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key   -- creating primary key (i.e. 'surrogate key' in gold layer)
	, pn.prd_id AS product_id
	, pn.prd_key AS product_number
	, pn.prd_nm AS product_name
	, pn.cat_id AS category_id
	, pc.cat AS category
	, pc.subcat AS subcategory
	, pc.maintenance
	, pn.prd_cost AS cost
	, pn.prd_line AS product_line
	, pn.prd_start_dt AS start_date
	-- , pn.prd_end_dt      -- all NULLs, so col not needed
FROM datawarehouse.silver_crm_prd_info pn
LEFT JOIN silver_erp_px_cat_g1v2 pc ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL;   -- we want the latest product info (i.e. info that hasn't expired)

-- Wrapping above query in a view : 
DROP VIEW IF EXISTS gold_dim_products;
CREATE VIEW gold_dim_products AS
SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key
	, pn.prd_id AS product_id
	, pn.prd_key AS product_number
	, pn.prd_nm AS product_name
	, pn.cat_id AS category_id
	, pc.cat AS category
	, pc.subcat AS subcategory
	, pc.maintenance
	, pn.prd_cost AS cost
	, pn.prd_line AS product_line
	, pn.prd_start_dt AS start_date
FROM datawarehouse.silver_crm_prd_info pn
LEFT JOIN silver_erp_px_cat_g1v2 pc ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL;


-- ################################################### CREATING VIEW FOR SALES FACTS ############################################################

SELECT * FROM datawarehouse.silver_crm_sales_details;

SELECT
	GROUP_CONCAT(CONCAT('sd.', COLUMN_NAME) ORDER BY ORDINAL_POSITION SEPARATOR '\n , ') AS col_list    -- 'ORDER BY ORDINAL_POSITION' returns col in order of their order in table
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'silver_crm_sales_details';

-- Copying and pasting the col list generate by above query into the query below (will later evolve to MAIN QUERY) : 
SELECT
	sd.sls_ord_num AS order_number
	, pr.product_key
	, cu.customer_key
	, sd.sls_order_dt AS order_date
	, sd.sls_ship_dt AS shipping_date
	, sd.sls_due_dt AS due_date
	, sd.sls_sales AS sales_amount
	, sd.sls_quantity AS quantity
	, sd.sls_price AS price
	, sd.dwh_create_date         -- not needed for end user in gold layer so removed in MAIN QUERY ahead
FROM datawarehouse.silver_crm_sales_details sd
LEFT JOIN gold_dim_products pr ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold_dim_customers cu ON sd.sls_cust_id = cu.customer_id;

-- MAIN QUERY : above stmt wrapped in a view
DROP VIEW IF EXISTS gold_fact_sales;
CREATE VIEW gold_fact_sales AS
SELECT
	sd.sls_ord_num AS order_number
	, pr.product_key
	, cu.customer_key
	, sd.sls_order_dt AS order_date
	, sd.sls_ship_dt AS shipping_date
	, sd.sls_due_dt AS due_date
	, sd.sls_sales AS sales_amount
	, sd.sls_quantity AS quantity
	, sd.sls_price AS price
FROM datawarehouse.silver_crm_sales_details sd
LEFT JOIN gold_dim_products pr ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold_dim_customers cu ON sd.sls_cust_id = cu.customer_id ;



