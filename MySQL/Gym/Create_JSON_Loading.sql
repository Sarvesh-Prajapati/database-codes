USE sql_ForDA;

-- -------------------- Step 1: Create the target table
DROP TABLE IF EXISTS people;
CREATE TABLE people (
  id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  first_name TEXT,
  last_name TEXT,
  email VARCHAR(30)
);

-- -------------------- Step 2: Load the JSON file into a session variable
-- Make sure the JSON file is present inside the 'secure_file_priv' directory; check this directory using:
SHOW VARIABLES LIKE 'secure_file_priv';  -- returns local path where the JSON file must be present

-- Load the JSON file into a session variable using LOAD_FILE() fn :
SET @json_data = LOAD_FILE('C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/people.json');

-- Check if the content was loaded (optional)
SELECT LEFT(@json_data, 1000);  -- Check first 1000 chars

-- -------------------- Step 3: Populate the 'people' table using JSON_TABLE

-- LOAD_FILE() used above returns file content as BLOB (binary string), not automatically as JSON or utf8 text. So when it's passed 
-- directly to JSON_TABLE() used ahead in SELECT, MySQL will throw error because it expects a proper character set like UTF8mb4. 
-- So, we cast the loaded data to a proper JSON-compatible string using CAST(... AS CHAR CHARACTER SET utf8mb4) as in SELECT ahead.

SELECT *              -- viewing the JSON content loaded in variable '@json_data'
FROM JSON_TABLE(
  CAST(@json_data AS CHAR CHARACTER SET utf8mb4),         -- casting BLOB to JSON-compatible string
  '$[*]'    -- root-level array;  [{},{},...]  is an array (list) of records
  COLUMNS 
  (
    pid INT PATH '$.id',                -- 'pid' is col alias for 'id' field of JSON content
    fname TEXT PATH '$.first_name',     -- 'fname' is col alias for 'first_name' field of JSON content
    lname TEXT PATH '$.last_name',      -- 'lname' is col alias for 'last_name' field of JSON content
    emailID VARCHAR(30) PATH '$.email'  -- 'emailID' is col alias for 'email' field of JSON
  )
) AS tmp_tbl LIMIT 10;

+------+------------+----------+-------------------------+
| pid  | fname      | lname    | emailID                 |
+------+------------+----------+-------------------------+
|    1 | Guenna     | Guage    | gguage0@zimbio.com      |
|    2 | Corie      | Couth    | ccouth1@posterous.com   |
|    3 | Lorie      | Sutter   | lsutter2@google.nl      |
|    4 | Susie      | Dootson  | sdootson3@smh.com.au    |
|    5 | Rutherford | Abbots   | rabbots4@purevolume.com |
|    6 | Siusan     | Tole     | stole5@nydailynews.com  |
|    7 | Ilaire     | Pikesley | ipikesley6@1688.com     |
|    8 | Yehudi     | Skerme   | yskerme7@jigsy.com      |
|    9 | Emerson    | Linnane  | elinnane8@bandcamp.com  |
|   10 | Garey      | Fernando | gfernando9@columbia.edu |
+------+------------+----------+-------------------------+

-- Now that the query above produced the JSON data in tabluar form as desired, load that result into table 'people':
  
INSERT INTO people (id, first_name, last_name, email)
SELECT *
FROM JSON_TABLE(
  CAST(@json_data AS CHAR CHARACTER SET utf8mb4),
  '$[*]' COLUMNS 
  (
    id INT PATH '$.id',
    first_name TEXT PATH '$.first_name',
    last_name TEXT PATH '$.last_name',
    email VARCHAR(30) PATH '$.email'
  )
) AS tmp_tbl;

-- -------------------- Step 4: View inserted data (optional)
SELECT * FROM people LIMIT 5;

+----+------------+-----------+-------------------------+
| id | first_name | last_name | email                   |
+----+------------+-----------+-------------------------+
|  1 | Guenna     | Guage     | gguage0@zimbio.com      |
|  2 | Corie      | Couth     | ccouth1@posterous.com   |
|  3 | Lorie      | Sutter    | lsutter2@google.nl      |
|  4 | Susie      | Dootson   | sdootson3@smh.com.au    |
|  5 | Rutherford | Abbots    | rabbots4@purevolume.com |
+----+------------+-----------+-------------------------+

-- DROP TABLE people;
