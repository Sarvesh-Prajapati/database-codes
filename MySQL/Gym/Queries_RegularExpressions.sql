USE sql_forda;

DROP TABLE IF EXISTS REGEXP_TABLE;
CREATE TABLE REGEXP_TABLE (ID INT, FULLNAME VARCHAR(100), EMAIL VARCHAR(100), SALARY INT);
-- Insert 10 sample records (with 1 NULL EMAIL and 1 NULL SALARY)
INSERT INTO REGEXP_TABLE VALUES
(1, 'Alice Johnson',   'alice123@gmail.com',   75000),
(2, 'Bob Smith',       'bob@yahoo.com',        60000),
(3, 'Carol99',         'carol_99@gmail.com',   82000),
(4, 'David Green',     'david@org.org',        90000),
(5, 'Eve_Lane',        NULL,                   70000),
(6, 'Frank O''Neill',  'frank.oneill@pro.net', NULL),
(7, 'Grace Hopper',    'grace_h@abc.com',      95000),
(8, 'Heidi',           'heidi@domain.co',      88000),
(9, 'Isaac_007',       'isaac007@site.io',     87000),
(10, 'John',           'john@apple.com',       92000),
(11, 'Tommy Lee Jones','tljones@yahoo.com',    94000);

-- REGEXP Example Queries

SELECT * FROM REGEXP_TABLE WHERE EMAIL REGEXP '\\.com$';   -- all emails ending in .com
SELECT * FROM REGEXP_TABLE WHERE EMAIL NOT REGEXP '\\.com$';  -- negation of above statement (all emails NOT ending in .com)

SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '^[Ac]';  -- case insensitive matching; names starting with A, a, C, c
SELECT * FROM REGEXP_TABLE WHERE FULLNAME COLLATE utf8mb4_bin REGEXP '^[Ac]';  -- name starting ONLY with either A or c ; CASE SENSITIVE

SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '[0-9]$';  -- fullname ending in digit
SELECT * FROM REGEXP_TABLE WHERE EMAIL REGEXP '[0-9]';   -- email having digits
SELECT * FROM REGEXP_TABLE WHERE EMAIL REGEXP '_';   -- email having underscore 

SELECT * FROM REGEXP_TABLE WHERE FULLNAME NOT REGEXP ' ';  -- fullname NOT having a single space
SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '.+';   -- fullname having 1 or more non-empty chars
SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP 'o.';   -- fullname having 'o' followed by any character

SELECT * FROM REGEXP_TABLE WHERE EMAIL REGEXP '^[a-zA-Z]';  -- email starting with uppercase/lowercase letter

SELECT * FROM REGEXP_TABLE WHERE EMAIL REGEXP 'gmail';   -- all emails having 'gmail' in them
SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '[a-z]{3,}';  -- names with 3 or more lowercase letters in a row; can return NULLs

SELECT * FROM REGEXP_TABLE WHERE EMAIL REGEXP '\\.(?!com$)';  -- Emails that are not `.com` domains
SELECT * FROM REGEXP_TABLE WHERE EMAIL NOT REGEXP '.com';   -- less complicated than above line

SELECT * FROM REGEXP_TABLE WHERE EMAIL REGEXP '^[a-z]+@';   -- Emails with only lowercase letters before '@'
SELECT * FROM REGEXP_TABLE WHERE EMAIL IS NOT NULL AND EMAIL REGEXP '.+';  -- emails  not NULL and non-empty

SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '^[A-Za-z]+ [A-Za-z]+$';  -- Names with exactly two words having 1 space within
SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '[^A-Za-z0-9 ]';  --  Names with special characters
SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '^[A-Za-z0-9 ]+$';  -- Names without special characters (only letters, digits, space)
SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '^[A-Za-z ]+$';  -- names with only alphabetic characters (no digits, no symbols)
SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '^[A-Za-z]+$';  -- names with only letters and without any space 

SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '[A-Z]' AND FULLNAME REGEXP '[a-z]';  -- names having both upper and lower letters
SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '[0-9]';  -- names having numbers in them

SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '^[A-Za-z]+( [A-Za-z]+){2,}$';  -- names having 3 words in them

-- first letter capital followed by 1 or more lowercase letter, then MAYBE (or MAY NOT BE) a space followed by 1 upper letter 
-- followed by 1 or more lower letters (BASICALLY, first and last names capitalized)
SELECT * FROM REGEXP_TABLE WHERE FULLNAME REGEXP '^[A-Z][a-z]+( [A-Z][a-z]+)?$';  











