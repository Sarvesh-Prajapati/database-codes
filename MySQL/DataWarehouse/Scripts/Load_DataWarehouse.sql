-- ########################## LOADING THE BRONZE LAYER TABLES ##########################

-- SHOW VARIABLES LIKE 'secure_file_priv';  -- returns path where the files to be loaded must be present

-- Since LOAD DATA INFILE can't be wrapped within a stored procedure in MySQL, a Python script can be created to load the files in MySQL; 
-- refer to the script file stored in the repo.
-- Before running the script file run (in MySQL) : 
SET GLOBAL local_infile = 1;
-- After the script has loaded the data, run (in MySQL) : 
SET GLOBAL local_infile = 0;

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







