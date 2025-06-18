import mysql.connector


## Before running this script, run this in MySQL: SET GLOBAL local_infile = 1 ;
## After running this script, run this in MySQL: SET GLOBAL local_infile = 0 ;


# Database connection parameters
config = {
    'user': 'root',
    'password': "YOUR_PW_HERE", # pw within single quotes throws error coz it has special chars
    'host': 'localhost',
    'database': 'datawarehouse',
    'allow_local_infile': True   # must include this line to load file from any local dir
}

# Connect to MySQL
conn = mysql.connector.connect(**config)
# Instead of specifying the creds as in var 'config' above, following line works too :
##conn = mysql.connector.connect(user='root', password="zaq1ZAQ!xsw2XSW@", host='localhost', database='datawarehouse')
cursor = conn.cursor()

if conn.is_connected(): print('\nCONNECTION ESTABLISHED ....\n')

# Create the stage table (if not exists)

cursor.execute("""DROP TABLE IF EXISTS stage_tbl""")

print('CREATING STAGE ...')

cursor.execute("""
    CREATE TABLE IF NOT EXISTS stage_tbl
    (
        id INT,
        ckey VARCHAR(50),
        first_name VARCHAR(100),
        last_name VARCHAR(100),
        mat_status VARCHAR(50),
        gender VARCHAR(20),
        create_date DATE
    )
""")

print('STAGE CREATED.\nLOADING DATA ...')


# Bulk load data from CSV into the stage table (NOTE how path has forward slash(es), a MUST)
load_sql = """
    LOAD DATA LOCAL INFILE "D:/cust_info.csv"
    IGNORE
    INTO TABLE stage_tbl
    CHARACTER SET utf8mb4
    FIELDS TERMINATED BY ','
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
"""
cursor.execute(load_sql)
conn.commit()

print("DATA SUCCESSFULLY LOADED INTO STAGE TABLE.")

## After loading data, run this in MySQL: SET GLOBAL local_infile = 0 ;

cursor.close()
print('CURSOR CLOSED.')
conn.close()
print('CONNECTION CLOSED.')
