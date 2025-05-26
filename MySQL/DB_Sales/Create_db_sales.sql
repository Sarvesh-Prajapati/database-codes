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

-- CSV files were imported into above 3 tables using 'Table Data Import Wizard' utility.
-- We can also load the CSVs into the above tables using LOAD DATA statement.
-- First copy-paste CSVs in locatino 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\' , otherwise --secure-file-priv error is raised
-- Then edit and run the following statement, thrice for loading 3 CSVs in the 3 tables created above:
 
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\CSV_FILE_NAME_HERE.csv'  -- path where CSVs MUST be present
INTO TABLE table_into_which_CSV_is_to_load_here
FIELDS TERMINATED BY ','
-- ENCLOSED BY ''         -- uncomment if applicable
-- ESCAPED BY '\\'        -- uncomment if applicable
LINES TERMINATED BY '\n'
IGNORE 1 LINES;           -- if topmost record in CSV is header, this line skips it







