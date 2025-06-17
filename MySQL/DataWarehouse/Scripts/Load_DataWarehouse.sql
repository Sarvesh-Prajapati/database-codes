-- ########################## LOADING THE BRONZE LAYER TABLES ##########################

SHOW VARIABLES LIKE 'secure_file_priv';  -- returns path where the files to be loaded must be present

-- Paste the three raw files into the path returned by the above query and then run the following :

TRUNCATE TABLE bronze_crm_cust_info;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\cust_info.csv'
IGNORE                             -- IGNORE deprecates errors to warnings and file continues loading
INTO TABLE bronze_crm_cust_info
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES ;









