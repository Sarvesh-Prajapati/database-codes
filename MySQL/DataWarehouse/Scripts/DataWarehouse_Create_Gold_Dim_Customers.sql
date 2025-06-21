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