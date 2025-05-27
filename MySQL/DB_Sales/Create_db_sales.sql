-- Create database: db_sales
-- In CSV files, change date cols to format 'yyyy-mm-dd' and Save.
-- Load CSV files into the tables using 'Table Data Import Wizard' utility of MySQL

DROP DATABASE IF EXISTS db_sales;
CREATE DATABASE db_sales;

USE db_sales;

DROP TABLE IF EXISTS leads;
CREATE TABLE leads(
cust_id INT,
cust_name VARCHAR(30),
sector VARCHAR(20),
city VARCHAR(20), 
state VARCHAR(20),
postal_code BIGINT,         -- column dropped after data loading
region VARCHAR(20),
sp_assigned VARCHAR(30),
lead_date DATE   -- yyyy-mm-dd format
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS sales;
CREATE TABLE sales(
cust_id INT,             -- column dropped after data loading
cust_name VARCHAR(30),
sp_assigned VARCHAR(30),
category VARCHAR(20),
order_date DATE,   -- yyyy-mm-dd format
sales DECIMAL(10, 2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS targets;
CREATE TABLE targets(
sales_person VARCHAR(30),
target DECIMAL(10, 2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- #################################################################################################################
-- CSV files were imported into above 3 tables using 'Table Data Import Wizard' utility.
-- We can also load the CSVs into the above tables using LOAD DATA statement.
-- First copy-paste CSVs in location 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\' , otherwise --secure-file-priv error is raised
-- Then edit and run the following statement, thrice for loading 3 CSVs in the 3 tables created above:
 
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\CSV_FILE_NAME_HERE.csv'  -- path where CSVs MUST be present
INTO TABLE table_into_which_CSV_is_to_load_here
-- CHARACTER SET utf8    -- uncomment if data contains non-standard chars
FIELDS TERMINATED BY ','
-- ENCLOSED BY ''    -- uncomment if applicable
-- ESCAPED BY '\\'   -- uncomment if applicable
LINES TERMINATED BY '\n'
IGNORE 1 LINES;   -- if topmost record in CSV is header, this line skips it

-- #################################################################################################################

-- TO LOAD CSV FROM ANY LOCAL DIRECTORY ON DEVICE INTO A TABLE IN MYSQL TABLE, FOLLOW THESE STEPS:

-- 1. Go to MySQL connection (Home icon at top left corner of Workbench screen).
-- 2. Right click connection -> Edit connection -> Advanced -> textbox 'Others' -> Add line: OPT_LOCAL_INFILE=1
-- 3. Test connection.
-- 4. If successsfully connected, close Workbench and re-start it.
-- 5. Login to the connection again and follow the steps ahead:

SHOW GLOBAL VARIABLES LIKE 'local_infile';  -- shows if this variable is OFF or ON (default OFF due to which LOAD DATA LOCAL throws error)
SET GLOBAL local_infile = 1;  -- turning the 'local_file' var ON; since 'local_file' is global var, GLOBAL is used here
LOAD DATA LOCAL INFILE 'D:\\Targets.csv' INTO TABLE Targets  -- any local source path of CSV
CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;
SET GLOBAL local_infile = 0;  -- turning the setting back to default OFF

-- 6. Again go back to MySQL connection (as in step-1 above).
-- 7. Follow step-2. From the textbox 'Others', delete the previously added line: OPT_LOCAL_INFILE=1
-- 8. Re-start Workbench and login to your instance ('DATraining' in my case).

-- #################################################################################################################







