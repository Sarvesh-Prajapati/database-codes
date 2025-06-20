-- ########################## LOADING BRONZE TABLES ##########################

-- SHOW VARIABLES LIKE 'secure_file_priv';  -- returns path where the files to be loaded must be present

-- Since LOAD DATA INFILE can't be wrapped within a stored procedure in MySQL, a Python script can be created to load the files in a stage table.
-- Then, a procedure can be created/called to copy content from stage table to desired destination table. Cleaning can be performed in stage.
-- Finally, stage table can be dropped. 
-- Ref. to script file stored in the repo.

-- Before running the script file run (in MySQL) : 
SET GLOBAL local_infile = 1;
-- After the script has loaded the data, run (in MySQL) : 
SET GLOBAL local_infile = 0;
-- To check if the variable local_infile is ON/OFF, run : 
SHOW VARIABLES LIKE 'local_infile';

-- When not using the script file, we proceed to load data as usual as ahead:
-- Paste the raw data files into the path returned by the topmost query and then run the following queries to load all the bronze tables:

TRUNCATE TABLE bronze_crm_cust_info;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\cust_info.csv'
IGNORE                             -- IGNORE deprecates errors to warnings and file continues loading
INTO TABLE bronze_crm_cust_info
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES ;

TRUNCATE TABLE bronze_crm_prd_info;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\prd_info.csv'
IGNORE                             -- IGNORE deprecates errors to warnings and file continues loading
INTO TABLE bronze_crm_prd_info
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES ;

TRUNCATE TABLE bronze_crm_sales_details;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\sales_details.csv'
IGNORE                             -- IGNORE deprecates errors to warnings and file continues loading
INTO TABLE bronze_crm_sales_details
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES ;

TRUNCATE TABLE bronze_erp_cust_az12;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\CUST_AZ12.csv'
IGNORE                             -- IGNORE deprecates errors to warnings and file continues loading
INTO TABLE bronze_erp_cust_az12
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES ;

TRUNCATE TABLE bronze_erp_loc_a101;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\LOC_A101.csv'
IGNORE                             -- IGNORE deprecates errors to warnings and file continues loading
INTO TABLE bronze_erp_loc_a101
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES ;

TRUNCATE TABLE bronze_erp_px_cat_g1v2;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\PX_CAT_G1V2.csv'
IGNORE                             -- IGNORE deprecates errors to warnings and file continues loading
INTO TABLE bronze_erp_px_cat_g1v2
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES ;

-- ######################################### LOADING SILVER TABLES #########################################

INSERT INTO datawarehouse.silver_crm_cust_info (cust_id, cust_key, cust_firstname, cust_lastname, cust_marital_status, cust_gender, cust_create_date)
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


INSERT INTO datawarehouse.silver_crm_prd_info(prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
SELECT
    prd_id
    , REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
    , SUBSTRING(prd_key, 7, length(prd_key)) AS prd_key
    , prd_nm
    , prd_cost
    , CASE UPPER(TRIM(prd_line))            -- instead of using 'UPPER(TRIM(prd_line))' in every WHEN, CASE block is written compactly
		WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
	  ELSE 'NA' END AS prd_line
    , CAST(prd_start_dt AS DATE) AS prd_start_dt               -- since the HH:MMM:SS values are all 00:00:00, we discard them
    , CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL 1 DAY AS DATE) AS prd_end_dt  -- current end date must not overlap with next record's start date
FROM datawarehouse.bronze_crm_prd_info ;


INSERT INTO silver_crm_sales_details(sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
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



