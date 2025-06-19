-- This project is a replication of Bara Khatib Salkini's video: https://www.youtube.com/watch?v=9GVqKuTVANE
-- He created it in SSMS. We're doing in MySQL.

DROP DATABASE IF EXISTS DataWarehouse;
CREATE DATABASE DataWarehouse;
USE DataWarehouse;

-- ################## CREATING THE BRONZE LAYER TABLES ##################

DROP TABLE IF EXISTS bronze_crm_cust_info;
CREATE TABLE bronze_crm_cust_info (
    cust_id INT,
    cust_key VARCHAR(50),
    cust_firstname VARCHAR(50),
    cust_lastname VARCHAR(50),
    cust_marital_status VARCHAR(50),
    cust_gender VARCHAR(50),
    cust_create_date DATE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS bronze_crm_prd_info;
CREATE TABLE bronze_crm_prd_info (
    prd_id INT,
    prd_key VARCHAR(50),
    prd_nm VARCHAR(50),
    prd_cost INT,
    prd_line VARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_date DATETIME
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS bronze_crm_sales_details;
CREATE TABLE bronze_crm_sales_details (
    sls_ord_num  VARCHAR(50),
    sls_prd_key  VARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt INT,
    sls_ship_dt  INT,
    sls_due_dt   INT,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ;

DROP TABLE IF EXISTS bronze_erp_loc_a101 ;
CREATE TABLE bronze_erp_loc_a101 (
    cid    VARCHAR(50),
    cntry  VARCHAR(50)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ;

DROP TABLE IF EXISTS bronze_erp_cust_az12 ;
CREATE TABLE bronze_erp_cust_az12 (
    cid    VARCHAR(50),
    bdate  DATE,
    gen    NVARCHAR(50)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ;

DROP TABLE IF EXISTS bronze_erp_px_cat_g1v2 ;
CREATE TABLE bronze_erp_px_cat_g1v2 (
    id           VARCHAR(50),
    cat          VARCHAR(50),
    subcat       VARCHAR(50),
    maintenance  VARCHAR(50)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ;

-- ################## CREATING THE SILVER LAYER TABLES ##################







-- ################## CREATING THE GOLD LAYER TABLES ##################
