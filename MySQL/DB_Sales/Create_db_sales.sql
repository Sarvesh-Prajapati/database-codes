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
sales DECIMAL 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS targets;
CREATE TABLE targets(
sales_person VARCHAR(30),
target DECIMAL 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;






