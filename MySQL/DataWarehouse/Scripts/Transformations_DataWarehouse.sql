-- ######################################### TRANSFORMING TBL 'bronze_crm_cust_info' ###################################################
SELECT * FROM datawarehouse.bronze_crm_cust_info ;

-- Checking duplications/NULLs of col 'cust_id'
SELECT cust_id, COUNT(*) FROM datawarehouse.bronze_crm_cust_info GROUP BY cust_id HAVING COUNT(*) > 1 OR cust_id IS NULL;

-- Retrieving cust_id with latest information (this will be our MAIN QUERY) :
SELECT * 
FROM
(
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY cust_id ORDER BY cust_create_date DESC) AS flag_last
	FROM datawarehouse.bronze_crm_cust_info 
	WHERE cust_id <> 0
) temp WHERE flag_last = 1;

-- Checking leading/trailing spaces in VARCHAR columns (i.e. string vals); as example, col 'cust_firstname' is checked here:
SELECT cust_firstname 
FROM datawarehouse.bronze_crm_cust_info
WHERE cust_firstname <> TRIM(cust_firstname);

-- Re-writing MAIN QUERY of above :
SELECT
	cust_id
    , cust_key
    , TRIM(cust_firstname) AS cust_firstname
    , TRIM(cust_lastname) AS cust_lastname
    , cust_marital_status
    , cust_gender
    , cust_create_date
FROM
(
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY cust_id ORDER BY cust_create_date DESC) AS flag_last
	FROM datawarehouse.bronze_crm_cust_info 
	WHERE cust_id <> 0
) temp WHERE flag_last = 1;

-- Checking distinct values of 'cust_marital_status' and 'cust_gender' (as these cols have only 2 valid values, DISTINCT will tell if NULL is there too)
SELECT DISTINCT cust_marital_status FROM datawarehouse.bronze_crm_cust_info;  -- last row in o/p is blank as it has default '' string (empty string); this is owing to IGNORE keyword in LOAD DATA INFILE command
SELECT DISTINCT cust_gender FROM datawarehouse.bronze_crm_cust_info;  -- same explanation for output as above

-- Re-writing the MAIN QUERY from above [ replacing 'M', 'F', 'S' and blank (i.e. '') ]:
SELECT
	cust_id
    , cust_key
    , TRIM(cust_firstname) AS cust_firstname
    , TRIM(cust_lastname) AS cust_lastname
    , CASE WHEN UPPER(TRIM(cust_marital_status)) = 'M' THEN 'Married'
		   WHEN UPPER(TRIM(cust_marital_status)) = 'S' THEN 'Single'
	  ELSE 'NA'
      END AS cust_marital_status
    , CASE WHEN UPPER(TRIM(cust_gender)) = 'F' THEN 'Female'
		   WHEN UPPER(TRIM(cust_gender)) = 'M' THEN 'Male'
	  ELSE 'NA'
      END AS cust_gender
    , cust_create_date
FROM 
(
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY cust_id ORDER BY cust_create_date DESC) AS flag_last
	FROM datawarehouse.bronze_crm_cust_info 
	WHERE cust_id <> 0
) temp WHERE flag_last = 1 ;

-- Note that bronze tbl hasn't been altered so far.
-- Using above MAIN QUERY to load cleaned bronze table's content into silver counterpart : 
INSERT INTO silver_crm_cust_info (cust_id, cust_key, cust_firstname, cust_lastname, cust_marital_status, cust_gender, cust_create_date)
SELECT                  -- this returns only 7 cols, hence 7 cols specified in above INSERT; actual silver tbl has 8 cols, 8th col auto populates
	cust_id
    , cust_key
    , TRIM(cust_firstname) AS cust_firstname
    , TRIM(cust_lastname) AS cust_lastname
    , CASE WHEN UPPER(TRIM(cust_marital_status)) = 'M' THEN 'Married'
		   WHEN UPPER(TRIM(cust_marital_status)) = 'S' THEN 'Single'
	  ELSE 'NA'
      END AS cust_marital_status
    , CASE WHEN UPPER(TRIM(cust_gender)) = 'F' THEN 'Female'
		   WHEN UPPER(TRIM(cust_gender)) = 'M' THEN 'Male'
	  ELSE 'NA'
      END AS cust_gender
    , cust_create_date
FROM 
(
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY cust_id ORDER BY cust_create_date DESC) AS flag_last
	FROM datawarehouse.bronze_crm_cust_info 
	WHERE cust_id <> 0
) temp WHERE flag_last = 1 ;

-- Now load tbl 'silver_crm_cust_info'

-- ######################################### TRANSFORMING TBL 'bronze_crm_prd_info' ###################################################

SELECT * FROM datawarehouse.bronze_crm_prd_info;

-- Checking duplications/NULLs in 'prd_id' vals
SELECT
	prd_id
    , COUNT(*)
FROM datawarehouse.bronze_crm_prd_info GROUP BY prd_id HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Checking leading/trailing spaces in VARCHAR columns (i.e. string vals); as example, col 'prd_nm' is checked here:
SELECT prd_nm
FROM datawarehouse.bronze_crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);

-- Checking for prd_cost having NULL (represented by 0 here) or negative vals
SELECT * FROM datawarehouse.bronze_crm_prd_info WHERE prd_cost = 0 OR prd_cost < 0;
SELECT DISTINCT prd_line FROM datawarehouse.bronze_crm_prd_info;

-- Check for invalid date orders (e.g. end date should come after start date)
SELECT * FROM datawarehouse.bronze_crm_prd_info WHERE prd_end_date < prd_start_dt;  -- 397 records are faulty

-- Correcting faulty records (LEAD statement from below will be used in MAIN QUERY )
SELECT
	prd_id
    , prd_key
    , prd_nm
    , prd_start_dt
    , prd_end_date
    , LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL 1 DAY AS prd_end_date_test  -- current end date must not overlap with next record's start date
FROM datawarehouse.bronze_crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509', 'AC-HE-HL-U509-R');

-- Extracting column headers of bronze tbl as a list for quick copy-pasting into SELECT statement of MAIN QUERY below:
SELECT GROUP_CONCAT(COLUMN_NAME SEPARATOR ', ')
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'bronze_crm_prd_info';

-- MAIN TRANSFORMATION QUERY :
SELECT
    prd_id
    , REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id    -- to link with tbl 'bronze_erp_px_cat_g1v2'
    , SUBSTRING(prd_key, 7, length(prd_key)) AS prd_key        -- to link with tbl 'bronze_crm_sales_details'
    , prd_nm
    , prd_cost
    , CASE UPPER(TRIM(prd_line))            -- Note how this CASE block is written
		WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
	  ELSE 'NA' END AS prd_line
    , CAST(prd_start_dt AS DATE) AS prd_start_dt   -- sincec the HH:MMM:SS values are all 00:00:00, we discard them
    , CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL 1 DAY AS DATE) AS prd_end_dt  -- current end date must not overlap with next record's start date
FROM datawarehouse.bronze_crm_prd_info;

-- Now load tbl 'silver_crm_prd_info'

-- ######################################### TRANSFORMING TBL 'bronze_crm_sales_details' ###################################################

SELECT * FROM datawarehouse.bronze_crm_sales_details;  -- shows date cols are not alright, so will be fixed

-- Finding if 'sls_ord_num' has duplications (there are few)
SELECT sls_ord_num, COUNT(sls_ord_num)
FROM datawarehouse.bronze_crm_sales_details
GROUP BY sls_ord_num HAVING COUNT(sls_ord_num) > 1;

-- Finding if any 'sls_ord_num' has leading/trailing spaces
SELECT * FROM datawarehouse.bronze_crm_sales_details WHERE sls_ord_num <> TRIM(sls_ord_num);

-- Checking if any 'sls_prd_key' is absent in tbl 'silver_crm_prd_info' (will be joined later)
SELECT * FROM datawarehouse.bronze_crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver_crm_prd_info);

-- Checking if any 'sls_cust_id' is absent in tbl 'silver_crm_cust_info' (will be joined later)
SELECT * FROM datawarehouse.bronze_crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cust_id FROM silver_crm_cust_info);

-- If any date col is faulty (or has outliers), replace such vals with NULL ('sls_order_dt' is done here as example)
SELECT sls_order_dt FROM datawarehouse.bronze_crm_sales_details WHERE sls_order_dt <= 0;
SELECT NULLIF(sls_order_dt, 0) AS sls_ord_dt       -- NULLIF() returns NULL if two exprns are equal, else returns first expr
FROM datawarehouse.bronze_crm_sales_details
WHERE sls_order_dt <= 0 OR length(sls_order_dt) <> 8 OR sls_order_dt > 20500101 OR sls_order_dt < 19000101;  -- this condition used in MAIN QUERY

-- Turning a string to date (all three lines below yield same output) :
-- SELECT str_to_date(20500101, '%Y%m%d');
-- SELECT str_to_date('20500101', '%Y%m%d');
-- SELECT cast(20500101 AS DATE);   -- this is used in MAIN QUERY below

-- Check if : sls_sales <> sls_quantity * sls_price ... or any of the 3 cols is NULL/less than 0 (yields lot of problematic rows)
SELECT DISTINCT
	sls_sales AS old_sls_sales
    , sls_quantity
    , sls_price AS old_sls_price
    , CASE
		WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
	  END AS sls_sales
	, CASE 
		WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0) 
        ELSE sls_price
	  END AS sls_price
FROM datawarehouse.bronze_crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <=0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- Extracting columns of tbl 'bronze_crm_sales_details' as list to be pasted in MAIN QUERY (post which transformations are applied there)
SELECT GROUP_CONCAT(COLUMN_NAME SEPARATOR ', ') AS col_list
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'bronze_crm_sales_details';

-- MAIN TRANSFORMATION QUERY
SELECT
    sls_ord_num
    , sls_prd_key
    , sls_cust_id
    , CASE
		WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt) <> 8 THEN NULL
		ELSE CAST(sls_order_dt AS DATE)
	  END AS sls_order_dt
    , CASE
		WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt) <> 8 THEN NULL
		ELSE CAST(sls_ship_dt AS DATE)
	  END AS sls_ship_dt 
    , CASE
		WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt) <> 8 THEN NULL
		ELSE CAST(sls_due_dt AS DATE)
	  END AS sls_due_dt 
    , CASE
		WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
	  END AS sls_sales
    , sls_quantity
	, CASE 
		WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0) 
        ELSE sls_price
	  END AS sls_price
FROM datawarehouse.bronze_crm_sales_details;

-- Now load tbl 'silver_crm_sales_details'

-- ######################################### TRANSFORMING TBL 'bronze_erp_cust_az12' ###################################################

-- Check for duplicate 'cid' vals
SELECT cid, COUNT(cid) FROM datawarehouse.bronze_erp_cust_az12 GROUP BY cid HAVING count(cid) > 1;

SELECT cid FROM datawarehouse.bronze_erp_cust_az12;  
-- since above query shows all 'cid' vals starting from 'NA...', we write following query to check if any 'cid' starts differently (it does)
SELECT cid FROM datawarehouse.bronze_erp_cust_az12 WHERE cid NOT LIKE 'N%';
-- we shall trim 'NAS' from all 'cid' vals :
SELECT
	cid AS old_cid
    , CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) ELSE cid END AS cid   -- used in MAIN QUERY
FROM datawarehouse.bronze_erp_cust_az12 ;

-- Check 'gen' col vals:
SELECT DISTINCT gen FROM datawarehouse.bronze_erp_cust_az12 ;  -- returns 'M', 'F', 'Male', 'Female' and blank ; resolved this in MAIN QUERY
-- Following query reveals what was hidden in 'gen' vals (every val ending in carriage return whose HEX is '0D' and ASCII is 13)
SELECT 
	DISTINCT gen
    , LENGTH(TRIM(gen)) AS gen_length
	, HEX(TRIM(gen)) AS hex_value
FROM bronze_erp_cust_az12;

-- MAIN TRANSFORMATION QUERY
SELECT
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) ELSE cid END AS cid
    , CASE WHEN bdate > CURRENT_DATE() THEN NULL ELSE bdate END AS bdate
    , CASE
		WHEN UPPER(TRIM(REPLACE(gen, CHAR(13), ''))) IN ('F', 'FEMALE') THEN 'Female'   -- removing carriage return and then trimming spaces
        WHEN UPPER(TRIM(REPLACE(gen, CHAR(13), ''))) IN ('M', 'MALE') THEN 'Male'       -- removing carriage return and then trimming spaces
        ELSE 'NA'
	  END AS gen
FROM datawarehouse.bronze_erp_cust_az12 ;

-- Load cleaned data into tbl 'silver_erp_cust_az12'

-- ######################################### TRANSFORMING TBL 'bronze_erp_loc_a101' ###################################################

-- Checking if 'cid' col is duplicated or has NULL or blank (no issues found after query run)
SELECT cid, COUNT(cid) FROM datawarehouse.bronze_erp_loc_a101 GROUP BY cid HAVING COUNT(cid) > 1 OR cid IS NULL or CID = '';

SELECT DISTINCT cntry, HEX(cntry) FROM datawarehouse.bronze_erp_loc_a101;  -- reveals HEX val 0D for carriage return (\r) in each val's end, & HEX val 20 (for space) in blanks

-- tbl 'silver_crm_cust_info' has format of col 'cust_key' bit diff from col 'cid' of table 'bronze_erp_loc_a101'; resolved in MAIN QUERY
SELECT cust_key FROM silver_crm_cust_info;

-- MAIN QUERY
SELECT
	REPLACE(cid, '-', '') AS cid
    , CASE
		WHEN TRIM(REPLACE(REPLACE(cntry, CHAR(32), ''), CHAR(13), '')) = 'DE' THEN 'Germany' 
		WHEN TRIM(REPLACE(REPLACE(cntry, CHAR(32), ''), CHAR(13), '')) IN ('US', 'USA', 'UnitedStates') THEN 'United States'
        WHEN TRIM(REPLACE(REPLACE(cntry, CHAR(32), ''), CHAR(13), '')) IN ('UnitedKingdom') THEN 'United Kingdom'
        WHEN TRIM(REPLACE(REPLACE(cntry, CHAR(32), ''), CHAR(13), '')) = '' OR cntry IS NULL THEN 'NA'
        ELSE TRIM(REPLACE(REPLACE(cntry, CHAR(32), ''), CHAR(13), '')) 
	  END AS cntry -- first replacing carriage return with '', then space with '', finally trimming
FROM datawarehouse.bronze_erp_loc_a101 ;

-- Load cleaned data into tbl 'silver_erp_loc_a101'


















