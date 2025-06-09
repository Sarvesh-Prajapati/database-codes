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

CREATE INDEX idx_accident_timestamp ON accident_data (Accident_Timestamp);

SELECT * FROM accident_data;

TRUNCATE sql_forda.accident_data;

-- -------- LOAD THE ACCIDENT DATA FROM THE CSV:
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\AccidentData.csv' 
INTO TABLE accident_data
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- SELECT * FROM accident_data;
SELECT Lat_Long FROM accident_data;

ALTER TABLE accident_data ADD COLUMN Lat_Long POINT;   -- adding new col, of POINT data type, to store spatial values
UPDATE accident_data SET Lat_Long = ST_GeomFromText(REPLACE(LatLong, "'", ''));    -- moving str vals of 'LatLong' (of VARCHAR type e.g. 'POINT(10.123 -10.123)') to 'Lat_Long' (of POINT type) 

ALTER TABLE accident_data MODIFY COLUMN Lat_Long POINT AFTER LatLong;  -- moving the 'Lat_Long' col from the last pos to right beside 'LatLong' col

SELECT * FROM accident_data;    -- shows 'Lat_long' vals as BLOB objects as it should

-- We can now drop the VARCHAR type 'LatLong' col as it is no longer needed but let's just keep it since 'Lat_Long' vals are displayed as BLOB
-- ALTER TABLE accident_data DROP COLUMN LatLong;

-- ##########################################################################################################################################
-- ------ One can extract the Lat and Long vals from BLOB geometry value in following ways:

SELECT ST_AsText(Lat_Long) AS ReadablePoint FROM accident_data;   -- Displays the BLOB spatial info as readable text

SELECT
	accident_id AS Acc_ID
    , ST_X(Lat_Long) AS Latitude        -- ST_X for x-coordinate or Latitude
    , ST_Y(Lat_Long) AS Longitude       -- ST_Y for y-coordinate or Longitude
FROM accident_data WHERE accident_id = 1;


-- ----------------- Extracting X and Y coordinates from a geometry/spatial value ------------------
-- SELECT ST_X(POINT(10, 20));   -- 10
-- SELECT ST_X(ST_GeomFromText('POINT(15 20)'));   -- 15
-- -------------------------------------------------------------------------------------------------


+-------------+---------------------+-------------+--------------------------+-------------------------+-------------------+------------------------------+------------------------------------------------------+-----------------------+--------------------------+---------------------+----------------+---------------+---------------------+-------------------------+--------------------+-------------+-------+--------------------+--------------------------------------+
| Accident_ID | Accident_Timestamp  | Day_Of_Week | Junction_Control         | Junction_Detail         | Accident_Severity | LatLong                      | Lat_Long                                             | Light_Conditions      | Local_Authority_District | Carriageway_Hazards | Casualty_Count | Vehicle_Count | Police_Force        | Road_Surface_Conditions | Road_Type          | Speed_Limit | Area  | Weather_Conditions | Vehicle_Type                         |
+-------------+---------------------+-------------+--------------------------+-------------------------+-------------------+------------------------------+------------------------------------------------------+-----------------------+--------------------------+---------------------+----------------+---------------+---------------------+-------------------------+--------------------+-------------+-------+--------------------+--------------------------------------+
|           1 | 2021-01-01 15:11:00 | Thursday    | Give way or uncontrolled | T or staggered junction | Serious           | 'POINT(51.512273 -0.201349)' | 0x000000000101000000D9CF622992C14940F0880AD5CDC5C9BF | Daylight              | Kensington and Chelsea   | None                |              1 |             2 | Metropolitan Police | Dry                                                   | 30 | Urban | Fine no high winds | Car
|           2 | 2021-01-05 10:59:00 | Monday      | Give way or uncontrolled | Crossroads              | Serious           | 'POINT(51.514399 -0.199248)' | 0x0000000001010000002C0C91D3D7C14940658EE55DF580C9BF | Daylight              | Kensington and Chelsea   | None                |             11 |             2 | Metropolitan Police | Wet or damp                         |iageway |          30 | Urban | Fine no high winds | Taxi/Private hire car
|           3 | 2021-01-04 14:19:00 | Sunday      | Give way or uncontrolled | T or staggered junction | Slight            | 'POINT(51.486668 -0.179599)' | 0x0000000001010000003F0114234BBE49408E78B29B19FDC6BF | Daylight              | Kensington and Chelsea   | None                |              1 |             2 | Metropolitan Police | Dry                                 |iageway |          30 | Urban | Fine no high winds | Taxi/Private hire car
|           4 | 2021-01-05 08:10:00 | Monday      | Auto traffic signal      | T or staggered junction | Serious           | 'POINT(51.507804 -0.20311)'  | 0x0000000001010000009563B2B8FFC04940ACCABE2B82FFC9BF | Daylight              | Kensington and Chelsea   | None                |              1 |             2 | Metropolitan Police | Frost or ice                        |iageway |          30 | Urban | Other              | Motorcycle over 500cc
|           5 | 2021-01-06 17:25:00 | Tuesday     | Auto traffic signal      | Crossroads              | Serious           | 'POINT(51.482076 -0.173445)' | 0x000000000101000000DF1797AAB4BD4940DDCD531D7233C6BF | Darkness - lights lit | Kensington and Chelsea   | None                |              1 |             2 | Metropolitan Police | Dry                                                   | 30 | Urban | Fine no high winds | Car
|           6 | 2021-01-01 11:48:00 | Thursday    | Give way or uncontrolled | T or staggered junction | Slight            | 'POINT(51.493415 -0.185525)' | 0x0000000001010000008C2D043928BF49403A92CB7F48BFC7BF | Daylight              | Kensington and Chelsea   | None                |              3 |             2 | Metropolitan Police | Dry                                                   | 30 | Urban | Fine no high winds | Car
|           7 | 2021-01-08 13:58:00 | Thursday    | Give way or uncontrolled | T or staggered junction | Serious           | 'POINT(51.480177 -0.178561)' | 0x0000000001010000004CA59F7076BD4940B9A7AB3B16DBC6BF | Daylight              | Kensington and Chelsea   | None                |              1 |             2 | Metropolitan Police | Dry                                 |iageway |          30 | Urban | Fine no high winds | Motorcycle over 500cc
|           8 | 2021-01-02 13:18:00 | Friday      | Auto traffic signal      | Crossroads              | Slight            | 'POINT(51.491957 -0.178524)' | 0x000000000101000000E6046D72F8BE4940938AC6DADFD9C6BF | Daylight              | Kensington and Chelsea   | None                |              1 |             1 | Metropolitan Police | Dry                                                   | 30 | Urban | Fine no high winds | Car
|           9 | 2021-01-07 12:15:00 | Wednesday   | Give way or uncontrolled | T or staggered junction | Slight            | 'POINT(51.49646 -0.167395)'  | 0x000000000101000000D6E253008CBF494021C84109336DC5BF | Daylight              | Kensington and Chelsea   | None                |              2 |             1 | Metropolitan Police | Dry                   | | Single carriageway |          30 | Urban | Fine no high winds | Van / Goods 3.5 tonnes mgw or under
|          10 | 2021-01-10 09:52:00 | Saturday    | Auto traffic signal      | Crossroads              | Slight            | 'POINT(51.48115 -0.183275)'  | 0x000000000101000000363CBD5296BD4940BD5296218E75C7BF | Daylight              | Kensington and Chelsea   | None                |              1 |             1 | Metropolitan Police | Wet or damp                                           | 30 | Urban | Other              | Car
+-------------+---------------------+-------------+--------------------------+-------------------------+-------------------+------------------------------+------------------------------------------------------+-----------------------+--------------------------+---------------------+----------------+---------------+---------------------+-------------------------+--------------------+-------------+-------+--------------------+--------------------------------------+








