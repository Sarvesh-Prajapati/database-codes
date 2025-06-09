-- When loading a huge file ('AccidentData.csv' here), it's better to first load a small subset of it (e.g. 'AccidentDataTEST.csv' present in the LHS in the tree hierarchy)
-- So, 'AccidentDataTEST.csv' with 30 rows was created, opened, & its 2 columns 'Accident_Date' & 'Time' were combined into a single column 'Accident_Timestamp'. Saved as CSV 'AccidentDataTEST_GEO.csv'.
-- File 'AccidentDataTEST_GEO.csv' was then opened, & its 2 columns 'Latitude' & 'Longitude' were combined as col 'LatLong' as VARCHAR (basically, string type) because direct import of spatial info
-- is not possible in MySQL. Then, 'Latitude' & 'Longitude' cols were deleted from CSV. Next, after saving changes, all 30 rows of 'AccidentDataTEST_GEO.csv' were loaded into 
-- the MySQL table successfully through LOAD DATA command. Next, a new col 'Lat_Long' (of spatial POINT dtype) was created through ALTER TABLE. Then, using UPDATE SET, col 'Lat_Long' was
-- populated with the values from 'LatLong' col through 'ST_GEOMFROMTEXT()' fn. Finally, col 'Lat_Long' was moved beside col 'LatLong'.

USE sql_ForDA;

SHOW VARIABLES LIKE 'secure_file_priv';   --   C:\ProgramData\MySQL\MySQL Server 8.0\Uploads    <-- copy+paste 'AccidentData.csv' here

DROP TABLE IF EXISTS accident_data;

CREATE TABLE accident_data (
Accident_ID INT PRIMARY KEY,              -- 1 to 307973
Accident_Timestamp TIMESTAMP,
Day_Of_Week VARCHAR(10),
Junction_Control VARCHAR(100),
Junction_Detail VARCHAR(100),
Accident_Severity VARCHAR(20),            -- slight, serious, fatal
LatLong VARCHAR(50),                      -- CSV file has 'LatLong' vals as string (e.g. 'POINT(10.123 -10.123)') so VARCHAR specified here; fixed below after loading data 
Light_Conditions VARCHAR(50),
Local_Authority_District VARCHAR(50),
Carriageway_Hazards VARCHAR(100),
Casualty_Count INT,                        -- 1 to 48
Vehicle_Count INT,                         -- 1 to 32
Police_Force VARCHAR(50),
Road_Surface_Conditions VARCHAR(25),       -- dry, wet or damp, frost or ice, flood, snow etc.
Road_Type VARCHAR(20),                     -- one way, roundabout, single carriageway, dual carriageway, slip road
Speed_Limit INT,                           -- 10 to 70mph
Area VARCHAR(15),                          -- urban, rural
Weather_Conditions VARCHAR(25),
Vehicle_Type VARCHAR(40)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- CREATE INDEX idx_accident_timestamp ON accident_data (Accident_ID);

TRUNCATE sql_forda.accident_data;

-- -------- LOAD THE ACCIDENT DATA FROM THE CSV:
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\AccidentData.csv' 
INTO TABLE accident_data
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- SELECT * FROM accident_data;

ALTER TABLE accident_data ADD COLUMN Lat_Long POINT;   -- adding new col, of POINT data type, to store spatial values
UPDATE accident_data SET Lat_Long = ST_GeomFromText(REPLACE(LatLong, "'", ''));    -- moving str vals of 'LatLong' (of VARCHAR type e.g. 'POINT(10.123 -10.123)') to 'Lat_Long' (of POINT type) 

ALTER TABLE accident_data MODIFY COLUMN Lat_Long POINT AFTER LatLong;  -- moving the 'Lat_Long' col from the last pos to right beside 'LatLong' col


SELECT * FROM accident_data;    -- shows 'Lat_long' vals as BLOB objects as it should

-- We can now drop the VARCHAR type 'LatLong' col as it is no longer needed but let's just keep it since 'Lat_Long' vals are displayed as BLOB
-- ALTER TABLE accident_data DROP COLUMN LatLong;

-- One can extract the Lat and Long vals from BLOB geometry value as follows:
SELECT
	accident_id AS Acc_ID
    , ST_X(Lat_Long) AS Latitude        -- ST_X for x-coordinate or Latitude
    , ST_Y(Lat_Long) AS Longitude       -- ST_Y for y-coordinate or Longitude
FROM accident_data WHERE accident_id = 1;


-- ----------------- Extracting X and Y coordinates from a geometry/spatial value ------------------
-- SELECT ST_X(POINT(10, 20));   -- 10
-- SELECT ST_X(ST_GeomFromText('POINT(15 20)'));   -- 15
-- -------------------------------------------------------------------------------------------------









