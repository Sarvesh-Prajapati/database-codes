DROP PROCEDURE IF EXISTS load_silver;

DELIMITER //
CREATE PROCEDURE load_silver()
BEGIN

	-- -------------------- Loading 'silver_crm_cust_info'

	TRUNCATE TABLE datawarehouse.silver_crm_cust_info;

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
	\! echo "LOADED silver_crm_cust_info ..."

	-- -------------------- Loading 'silver_crm_prd_info'

	TRUNCATE TABLE datawarehouse.silver_crm_prd_info;

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
	\! echo "LOADED silver_crm_prd_info ..."

	-- -------------------- Loading 'silver_crm_sales_details'

	TRUNCATE TABLE datawarehouse.silver_crm_sales_details;

	INSERT INTO datawarehouse.silver_crm_sales_details(sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
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
	\! echo "LOADED silver_crm_sales_details ..."

	-- -------------------- Loading 'silver_erp_cust_az12'

	TRUNCATE TABLE datawarehouse.silver_erp_cust_az12;

	INSERT INTO datawarehouse.silver_erp_cust_az12(cid, bdate, gen)
	SELECT
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) ELSE cid END AS cid
		, CASE WHEN bdate > CURRENT_DATE() THEN NULL ELSE bdate END AS bdate
		, CASE
			WHEN UPPER(TRIM(REPLACE(gen, CHAR(13), ''))) IN ('F', 'FEMALE') THEN 'Female'   -- removing carriage return and then trimming spaces
			WHEN UPPER(TRIM(REPLACE(gen, CHAR(13), ''))) IN ('M', 'MALE') THEN 'Male'       -- removing carriage return and then trimming spaces
			ELSE 'NA'
		  END AS gen
	FROM datawarehouse.bronze_erp_cust_az12 ;
	\! echo "LOADED silver_erp_cust_az12 ..."

	-- -------------------- Loading 'silver_erp_loc_a101'

	TRUNCATE TABLE datawarehouse.silver_erp_loc_a101;

	INSERT INTO datawarehouse.silver_erp_loc_a101(cid, cntry)
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
	\! echo "LOADED silver_erp_loc_a101 ..."

	-- -------------------- Loading 'silver_erp_px_cat_g1v2'

	TRUNCATE TABLE datawarehouse.silver_erp_px_cat_g1v2;

	INSERT INTO datawarehouse.silver_erp_px_cat_g1v2(id, cat, subcat, maintenance)
	SELECT
		id
		, cat
		, subcat
		, TRIM(REPLACE(maintenance, CHAR(13), '')) AS maintenance
	FROM datawarehouse.bronze_erp_px_cat_g1v2;
	\! echo "LOADED silver_erp_px_cat_g1v2 ..."

END //
DELIMITER ;