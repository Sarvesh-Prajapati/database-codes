-- Query typing order is: SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY
-- Query processing order is: FROM (including JOINS), WHERE, GROUP BY (including aggregate fns.), HAVING, SELECT, ORDER BY

USE sql_store;
SHOW TABLES;

SELECT * FROM customers;

SELECT * FROM customers WHERE customer_id = 1;
SELECT * FROM customers ORDER BY first_name;
SELECT first_name, last_name, points, points+10 FROM customers;
SELECT first_name, last_name, points, points * 10 + 100 AS new_points FROM customers;
SELECT first_name, last_name, points, points * 10 + 100 AS 'new points' FROM customers;
SELECT state FROM customers;
SELECT DISTINCT state FROM customers;

SELECT * FROM customers WHERE points > 3000;
SELECT * FROM customers WHERE state = 'VA';
SELECT * FROM customers WHERE state <> 'VA'; -- state is not equal to VA
SELECT * FROM customers WHERE birth_date > '1990-01-01' OR points < 1000 AND state = 'VA' ; -- AND has higher precedence over OR
SELECT * FROM customers WHERE NOT (birth_date > '1990-01-01' OR points > 1000);
SELECT * FROM customers WHERE (birth_date < '1990-01-01' AND points < 1000); -- same as above query
SELECT * FROM customers WHERE state IN ('VA', 'FL', 'GA');
SELECT * FROM customers WHERE state NOT IN ('VA', 'FL', 'GA');

SELECT * FROM products WHERE quantity_in_stock IN (49, 38, 72);
SELECT * FROM customers WHERE points BETWEEN 1000 AND 3000; -- Both 1000 and 3000 inclusive
SELECT * FROM customers WHERE last_name LIKE 'brush%'; -- last name starting with brush or Brush or BRUSH
SELECT * FROM customers WHERE last_name LIKE '%b%'; -- any no. of chars before/after b or B
SELECT * FROM customers WHERE last_name LIKE '_____y'; -- 6th char should be y in last_name (hence 5 underscores before y in pattern)
SELECT * FROM customers WHERE last_name LIKE 'b____y'; -- only 4 chars b/w b and y in last_name
SELECT * FROM customers WHERE last_name LIKE 'b%y'; -- any no. of chars b/w b and y in last_name
SELECT * FROM customers WHERE last_name LIKE '%y' ; -- any no. of chars preceding y in last_name

SELECT * FROM customers WHERE address LIKE '%trail%' OR address LIKE '%avenue%';
SELECT * FROM customers WHERE last_name REGEXP 'field';
SELECT * FROM customers WHERE last_name REGEXP '^b'; -- last_name STARTING with 'b'
SELECT * FROM customers WHERE last_name REGEXP 'y$'; -- last_name ENDING with 'y'
SELECT * FROM customers WHERE last_name REGEXP 'field|mac'; -- last_name with 'field' or 'mac' in it; 'field | mac' will return NULLs due to spaces
SELECT * FROM customers WHERE last_name REGEXP '^field|rose'; -- last_name either start with 'field' or have 'rose'
SELECT * FROM customers WHERE last_name REGEXP '[gim]e'; -- last name having ge, ie, or me
SELECT * FROM customers WHERE last_name REGEXP '[a-h]e'; -- last_name having any letter from 'a' to 'h' preceding 'e'

SELECT * FROM customers WHERE first_name REGEXP 'elka|ambur';
SELECT * FROM customers WHERE last_name REGEXP 'ey$|on$';
SELECT * FROM customers WHERE last_name REGEXP '^my|se';
SELECT * FROM customers WHERE last_name REGEXP 'b[ru]';

SELECT * FROM customers WHERE phone IS NULL;
SELECT * FROM customers WHERE phone IS NOT NULL;

SELECT * FROM CUSTOMERS ORDER BY first_name DESC;
SELECT * FROM CUSTOMERS ORDER BY state, first_name; -- sort by state first, & then within state by first_name
SELECT * FROM CUSTOMERS ORDER BY state DESC, first_name DESC;
SELECT first_name, last_name, state FROM CUSTOMERS ORDER BY state, first_name;
SELECT first_name, last_name, state FROM CUSTOMERS ORDER BY state DESC, first_name; -- after 'state' is sorted DESC, first_name gets sorted ASC

SELECT first_name, last_name, 10 AS points FROM customers ORDER BY points, first_name;
SELECT first_name, last_name, 10 AS points FROM customers ORDER BY 1,2; -- not a good practice to use numbers for col

SELECT *
	, quantity * unit_price AS total_price 
FROM order_items 
WHERE order_id = 2 
ORDER BY total_price DESC;

SELECT * FROM customers LIMIT 3; -- fetch only top 3 rows
SELECT * FROM customers LIMIT 6, 3; -- skip first 6 rows and fetch next 3
SELECT * FROM customers ORDER BY points DESC LIMIT 3;

SELECT * FROM customers JOIN orders ON customers.customer_id = orders.customer_id ; -- 'join' is by default 'inner join'

-- Following query will fail to run since SQL can't discern 'customer_id' from which table is being called by SELECT
SELECT order_id, customer_id, first_name, last_name FROM orders JOIN customers ON orders.order_id = customers.customer_id;

-- Above query modified as ahead:
SELECT order_id, orders.customer_id, first_name, last_name FROM orders JOIN customers ON orders.order_id = customers.customer_id;

-- Above query using aliases for tables
SELECT order_id, o.customer_id, first_name, last_name FROM orders o JOIN customers c ON o.order_id = c.customer_id;

SELECT * FROM order_items oi JOIN products p ON oi.product_id = p.product_id;
SELECT order_id, oi.product_id, quantity, oi.unit_price FROM order_items oi JOIN products p ON oi.product_id = p.product_id;

-- Joining Across Databases: note that only have to prefix tables (with DB name) that aren't part of currently USEed db
SELECT * FROM order_items oi JOIN sql_inventory.products p ON oi.product_id = p.product_id;

-- --------------------- Self joins: joining a table with itself ---------------------
USE sql_hr;
SELECT * FROM employees e JOIN employees m ON e.reports_to = m.employee_id;
SELECT 
	e.employee_id AS EmpID
	, e.first_name AS EmpName
	, m.first_name AS Manager 
FROM employees e JOIN employees m ON e.reports_to = m.employee_id;

-- Joining multiple tables: orders, customers, order_statuses
USE sql_store;
SELECT * 
FROM orders o JOIN customers c ON o.customer_id = c.customer_id JOIN order_statuses os ON o.status = os.order_status_id;

SELECT
	o.order_id
	, o.order_date
	, c.first_name
	, c.last_name
	, os.name AS Order_Status
FROM orders o JOIN customers c ON o.customer_id = c.customer_id 
JOIN order_statuses os ON o.status = os.order_status_id
ORDER BY o.order_id;

-- Exercise
USE sql_invoicing;
SELECT * 
	FROM payments p JOIN clients c ON p.client_id = c.client_id
	JOIN payment_methods pm ON p.payment_method = pm.payment_method_id;

SELECT
	p.payment_id
	, p.client_id
	, p.invoice_id
	, p.date
	, p.amount
	, c.name
	, c.city
	, pm.payment_method_id
	, pm.name
FROM payments p JOIN clients c ON p.client_id = c.client_id
JOIN payment_methods pm ON p.payment_method = pm.payment_method_id;

-- Compound join conditions (referring to more than one col in a table to uniquely identify records while joining many tables)
USE sql_store;
SELECT *
FROM order_items oi JOIN order_item_notes oin ON oi.order_id = oin.order_id AND oi.product_id = oin.product_id;

-- Implicit join syntax (be aware of this but DON'T use in real life)
USE sql_store;
SELECT * FROM orders o, customers c WHERE o.customer_id = c.customer_id;

-- ------------------ Outer Joins -------------------------
USE sql_store;
SELECT
	c.customer_id
	, c.first_name
	, o.order_id 
FROM orders o JOIN customers c ON o.customer_id = c.customer_id
ORDER BY c.customer_id;

-- Above 'select' stmt's o/p doesn't show all customers because only cust IDs 2,5,6,7,8 & 10 have orders placed (evident in 'orders' table). If all customer IDs are to be fetched 
-- irrespective of whether they have orders placed or not, WE NEED TO USE Outer Joins; note that LEFT JOIN and LEFT OUTER JOIN are one and same thing.
SELECT
	c.customer_id
	, c.first_name
	, o.order_id
FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id
ORDER BY c.customer_id;

-- SELECT c.customer_id, c.first_name, o.order_id FROM customers c RIGHT JOIN orders o ON o.customer_id = c.customer_id ORDER BY c.customer_id;

-- Exercise
USE sql_store;
SELECT
	p.product_id
	, p.name
	, oi.quantity
FROM products p LEFT JOIN order_items oi ON p.product_id = oi.product_id;

-- --------------------- Outer Joins between multiple tables ---------------------
SELECT
	c.customer_id
	, c.first_name
	, o.order_id
	, sh.shipper_id
	, sh.name AS shipper_name
FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id 
JOIN shippers sh ON o.shipper_id = sh.shipper_id
ORDER BY c.customer_id;

-- Above query doesn't fetch all customer IDs' so 'JOIN shippers' should be changed to 'LEFT JOIN shippers' as ahead:
SELECT
	c.customer_id
	, c.first_name
	, o.order_id
	, sh.shipper_id
	, sh.name AS shipper_name
FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id 
LEFT JOIN shippers sh ON o.shipper_id = sh.shipper_id
ORDER BY c.customer_id;

-- Exercise
SELECT
	o.order_id
	, o.order_date
	, c.first_name AS customer
	, sh.name AS shipper
	, os.name AS status
FROM orders o JOIN customers c ON o.customer_id = c.customer_id
JOIN shippers sh ON o.shipper_id = sh.shipper_id
JOIN order_statuses os ON o.status  = os.order_status_id
ORDER BY o.order_id;

-- Above query doesn't yield all orders so 'JOIN shippers sh' is modified to 'LEFT JOIN shippers sh' as ahead:
SELECT
	o.order_id
	, o.order_date
	, c.first_name AS customer
	, sh.name AS shipper
	, os.name AS status
FROM orders o JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN shippers sh ON o.shipper_id = sh.shipper_id
JOIN order_statuses os ON o.status  = os.order_status_id
ORDER BY o.order_id;

-- -------------------- SELF OUTER JOINS ------------------------------
USE sql_hr;
-- Following 2 queries were covered earlier above (in Self Joins section)
SELECT * FROM employees e JOIN employees m ON e.reports_to = m.employee_id;
SELECT e.employee_id, e.first_name, m.first_name FROM employees e JOIN employees m ON e.reports_to = m.employee_id;

-- Above query basically returns 'Yovonnda' as manager for every employee but it returns no row for 'Yovonnda' as an employee himself; so above query is modified
-- as ahead to get EVERY employee (whether he or she has a manager or not)
SELECT
	e.employee_id
	, e.first_name AS empName
	, m.first_name AS manager
FROM employees e LEFT JOIN employees m ON e.reports_to = m.employee_id;

-- -------------- The USING clause --------------------------
USE sql_store;
SELECT * FROM orders o, customers c WHERE o.customer_id = c.customer_id;

-- The WHERE clause in above query can be made compact by USING clause that takes a column which has exactly same name in all tables it is in
SELECT c.customer_id, o.order_id, c.first_name FROM orders o JOIN customers c USING (customer_id);
SELECT c.customer_id, o.order_id, c.first_name FROM orders o JOIN customers c USING (customer_id) JOIN shippers sh USING (shipper_id);
SELECT
	c.customer_id
	, o.order_id
	, c.first_name
	, sh.name AS shipper
FROM orders o JOIN customers c USING (customer_id) LEFT JOIN shippers sh USING (shipper_id);

-- Table 'order_items' has two cols together making its PK. Query ahead shows how composite PK is used in USING clause:
SELECT * FROM order_items oi JOIN order_item_notes oin USING(order_id, product_id);

-- Exercise: fetch 'date, client, amount, payment method' from 'sql_invoicing' db
USE sql_invoicing;
SELECT
	p.date
	, c.name
	, p.amount
	, pm.name
FROM payments p JOIN clients c USING (client_id)
JOIN payment_methods pm ON p.payment_method = pm.payment_method_id;

-- NATURAL JOINS: simpler to code; NOT recommended as produces unexpected results as it allows DB engine to pick the kind of join
USE sql_store;
SELECT o.order_id, c.first_name FROM orders o NATURAL JOIN customers c;

-- --------------------- AGGREGATE FUNCTIONS ----------------------------------
SELECT count(points), sum(points), avg(points), min(points), max(points), max(points)-min(points) AS points_range from customers;

-- --------------- CROSS JOINS: used to join every record in one table with every record in another table ----------------------------------
USE sql_store;
SELECT * FROM customers c CROSS JOIN products p;     -- Returns 100 rows (10 rows of customers table X 10 rows of products)
SELECT
	c.first_name AS customer
	, p.name AS product
FROM customers c CROSS JOIN products p
ORDER BY c.first_name; -- 100 rows returned for cols in query

SELECT c.first_name AS customer, p.name AS product FROM customers c, products p ORDER BY c.first_name; -- same result as in above query; CROSS JOIN is not written

-- ----------------------------- UNIONS -----------------------------------------
USE sql_store;
SELECT
	order_id
	, order_date
	, 'Active' AS status   -- adding a col 'status' with value 'Active' in results
FROM orders
WHERE order_date >= '2019-01-01';

SELECT
	order_id
	, order_date
	, 'Archived' AS status  -- adding a col 'status' with value 'Archived' in results
FROM orders
WHERE order_date < '2019-01-01';

-- Combining above two queries using UNION

SELECT order_id, order_date, 'Active' AS status FROM orders WHERE order_date>= '2019-01-01'
UNION 
SELECT order_id, order_date, 'Archived' AS status FROM orders WHERE order_date < '2019-01-01';

-- UNION using different tables (in above query, only one table is used); note that no. of cols following each SELECT should be same else error is returned
SELECT first_name FROM customers
UNION
SELECT name FROM shippers; -- returns results under col titled 'first_name'

SELECT name FROM shippers UNION SELECT first_name FROM customers; -- returns results under col titled 'name'; order in this query is reversed as that in above one

-- Exercise: creating BRONZE, SILVER, GOLD type of customers depending on points < 2000, 2000<points<3000, or points>3000 respectively; result sorted by first_name

SELECT customer_id, first_name, points, 'Bronze' AS cust_type FROM customers WHERE points < 2000
UNION
SELECT customer_id, first_name, points, 'Silver' AS cust_type FROM customers WHERE points BETWEEN 2000 AND 3000
UNION
SELECT customer_id, first_name, points, 'Gold' AS cust_type FROM customers WHERE points > 3000
ORDER BY first_name; 

-- Above query re-written using CASE-WHEN-THEN-END

SELECT
	customer_id
	, first_name
	, points
	, CASE
		WHEN points < 2000 THEN 'Bronze'
		WHEN points BETWEEN 2000 AND 3000 THEN 'Silver'
		ELSE 'Gold' 
    	END AS Cust_Status
FROM customers
ORDER BY first_name; 

USE sql_store;
-- ------------------------- Column Attributes -------------------------------------

-- In 'customers' table, 'customer_id' is PK and is set to auto-increment meaning MySQL will assign unique value automatically.
INSERT INTO customers VALUES (DEFAULT, 'John', 'Smith', '1990-01-01', DEFAULT, 'address', 'city', 'CA', DEFAULT);
SELECT * FROM customers;
DELETE FROM customers WHERE customer_id = 18;

-- Inserting values for only specific columns; note that default values (if specified) & data type (& char length) for a col are not violated

INSERT INTO customers (first_name, last_name, birth_date, address, city, state) VALUES ('John', 'Smith', NULL, 'address', 'city', 'CA');

-- -------------------- Inserting multiple rows -------------------------------------
USE sql_store;
INSERT INTO shippers (name) VALUES ('Shipper1'), ('Shipper2'), ('Shipper3'); -- No need to insert value for 'shipper_id' as it is already set as PK and AI (auto-increment)
SELECT * FROM shippers;

-- Exercise: enter 3 rows in 'products' table
USE sql_store;
INSERT INTO products (name, quantity_in_stock, unit_price) VALUES ('Product1', 10, 1.95), ('Product2', 11, 1.95), ('Product3', 12, 1.95); -- product_id is PK & NN & AI
SELECT * FROM products;

-- ----------------------- INSERTING HEIRARCHICAL ROWS (inserting data into multiple tables) --------------------------------------------------

-- SELECT last_insert_id(); -- last_insert_id() is a built-in fn of MySQL Workbench which returns the most recent id added to a table

USE sql_store;
INSERT INTO orders (customer_id, order_date, status) VALUES (1, '2019-01-02', 1);
INSERT INTO order_items VALUES (last_insert_id(), 1, 1, 2.95), (last_insert_id(), 2, 1, 3.95);

-- ----------------------- Creating copy of table: Using sub-queries ----------------------------------------

USE sql_store;
CREATE TABLE orders_archived AS
SELECT * FROM orders; -- copy of 'orders' table created as 'orders_archived' but design (e.g. PK, NN etc.) of 'orders' is NOT copied
TRUNCATE TABLE orders_archived; -- removes all rows but PRESERVES THE TABLE DESIGN
-- DROP TABLE orders_archived; -- deletes the table completely

-- -------------------- Two ways to populate a copy of 'orders' table 'orders_archived' with only selected rows ------------
-- WAY-1
CREATE TABLE orders_archived AS SELECT * FROM orders WHERE order_date < '2019-01-01'; 
-- WAY-2
INSERT INTO orders_archived SELECT * FROM orders WHERE order_date < '2019-01-01'; -- no need to insert rows into table copy one at a time

-- Exercise: Go to 'invoicing' db, create a copy of 'invoices' tbl as 'invoices_archive' which has clients 'name' col from 'clients' tbl; copy only invoices 
-- that do have payment done i.e. payment_date is NOT NULL.
USE sql_invoicing;
CREATE TABLE invoices_archived AS
SELECT
	i.invoice_id
	, i.number
	, c.name AS client
	, i.invoice_total
	, i.payment_total
	, i.invoice_date
	, i.payment_date
	, i.due_date
FROM invoices i JOIN clients c USING (client_id)
WHERE i.payment_date IS NOT NULL;
 
 -- ---------------------- UPDATING A SINGLE ROW: Using UPDATE statement --------------------------------------

UPDATE invoices
SET payment_total = 10, payment_date = '2019-03-01'
WHERE invoice_id = 1;

-- reverting to changes before the above query made change
UPDATE invoices
SET payment_total = 0.00, payment_date = NULL
WHERE invoice_id = 1;
-- OR do as
UPDATE invoices 
SET payment_total = DEFAULT, payment_date = DEFAULT
WHERE invoice_id = 1; -- DEFAULT works here since 'invoices' tbl design specifies DEFAULT values

-- Changing a row's payment_total and payment_date
UPDATE invoices
SET payment_total = invoice_total * 0.5, payment_date = due_date
WHERE invoice_id = 3; 

-- ---------------------------------- Updating multiple rows -------------------------------------------------
USE sql_invoicing;
-- This is only for MySQL Workbench. First go to Edit --> Preferences --> SQL Editor --> Scroll to bottom and uncheck 'Safe Update...' box. 
-- Then restart the current instance. Run following:

UPDATE invoices
SET payment_total = invoice_total * 0.5, payment_date = due_date
WHERE invoice_id IN (3,4);

UPDATE invoices
SET payment_total = invoice_total * 0.5, payment_date = due_date; -- this updates ALL rows of 'invoices' table
 
-- ------------------- Using sub-queries in UPDATE stmt --------------------------------
-- Updating row of a client whose name is known but whose client_id is not known

USE sql_invoicing;
UPDATE invoices
SET payment_total = invoice_total * 2, payment_date = due_date
WHERE invoice_id = (SELECT client_id FROM clients WHERE name = 'Myworks');

-- Updating row of a clients living in CA or NY
UPDATE invoices
SET payment_total = invoice_total * 2, payment_date = due_date
WHERE invoice_id IN (SELECT client_id FROM clients WHERE state IN ('CA', 'NY'));

-- -------------------- Deleting rows --------------------------
DELETE FROM table_name_here
WHERE col_name = some_col_attrib_value;
-- DELETE FROM invoices WHERE client_id = (SELECT * FROM clients WHERE name = 'Myworks');

-- --------------------- Restoring Databases -----------------------
-- After all the insertions, updations, deletions so far, if you wish to restore all databases used here back to original states,
-- press Ctrl+Shift+O to open the directory containing SQL scripts and run the 'create_databases' query again.

-- ########################################################################################################################
-- HACKERRANK SQL PROBLEMS (following queries are created by drawing parallels b/w the H.R. problem and DBs here)
-- ########################################################################################################################

USE sql_store;
-- ### List cities with shortest & longest names (in that order). E.g. if cities are DEF, ABC, PQRS and WXY, then o/p: ABC 3, PQRS 4

-- Query for shortest city name:
SELECT
	city
	, LENGTH(city)
FROM sql_store.customers
ORDER BY LENGTH(city), city   -- 1st orders by name's length & then orders asc alphab. by name; note that default order is ascending
LIMIT 1; 

-- Query for longest city name:
SELECT city, LENGTH(city) FROM sql_store.customers ORDER BY LENGTH(city) DESC, city LIMIT 1; -- 1st orders by len. desc, then orders asc alphab. by name

-- ### List cities starting with vowels a,e,i,o,u AND no duplicate city names allowed (4 ways to solve)
SELECT DISTINCT city FROM customers WHERE REGEXP_LIKE(city, '^[aeiou].+', 'i');         -- 'i' means case-insensitivity is enforced
SELECT DISTINCT city FROM customers WHERE REGEXP_LIKE(city, '^[aeiou]', 'i');           -- only 1st letter is to be checked so '.+' can be discarded in match pattern
SELECT DISTINCT city FROM customers WHERE SUBSTR(city, 1, 1) IN ('A', 'E', 'I', 'O', 'U', 'a', 'e', 'i', 'o', 'u'); -- SUBSTR(col_val, 1, 1): read L2R as 1st letter of 1st word in col_val
SELECT DISTINCT city FROM customers WHERE city REGEXP '^[aeiouAEIOU]';


--  ### List cities ending with vowels a,e,i,o,u AND no duplicate city names allowed
SELECT DISTINCT city FROM customers WHERE city REGEXP '[aeiouAEIOU]$';
SELECT DISTINCT city FROM customers WHERE REGEXP_LIKE(city, '[aeiou]$', 'i'); -- 'i' enforces case insensitivity

--  ### List cities starting OR ending with vowels a,e,i,o,u
SELECT city FROM customers WHERE REGEXP_LIKE(city, '^[aeiou]|[aeiou]$', 'i'); -- this format is accepted in Hackerrank
SELECT city FROM customers WHERE city REGEXP '^[aeiouAEIOU]|[aeiouAEIOU]$';

--  ### List cities starting AND ending with vowels a,e,i,o,u
SELECT city FROM customers WHERE city REGEXP '^[aeiouAEIOU].*[aeiouAEIOU]$';
SELECT city FROM customers WHERE REGEXP_LIKE(city, '^[aeiou].*[aeiou]$', 'i'); -- this format is accepted in Hackerrank

-- ### List cities NOT starting in vowels a,e,i,o,u
SELECT city FROM customers WHERE city REGEXP '^[^aeiouAEIOU]';
SELECT city FROM customers WHERE REGEXP_LIKE(city, '^[^aeiou]', 'i'); -- this format is accepted in Hackerrank

-- ### List cities NOT ending in vowels a,e,i,o,u
SELECT city FROM customers WHERE REGEXP_LIKE(city, '[^aeiou]$', 'i'); -- this format is accepted in Hackerrank
SELECT city FROM customers WHERE city REGEXP '[^aeiouAEIOU]$';

-- ### List cities that either do not start with vowels or do not end with vowels; no duplicate cities.
SELECT DISTINCT city FROM customers WHERE REGEXP_LIKE(city,'^[^aeiou]', 'i')  AND REGEXP_LIKE(city, '[^aeiou]$', 'i');
SELECT DISTINCT city FROM customers WHERE city REGEXP '^[^aeiouAEIOU]' AND city REGEXP '[^aeiouAEIOU]$';

-- ### List customers with points > 2200. Order o/p by last three chars of each last_name; for 2+ customers with names ending in same 3 characters (i.e. Bobby, Robby, etc.), secondary sort them by ascending ID
SELECT last_name, points FROM customers WHERE points > 2200 ORDER BY SUBSTR(last_name, -3), customer_id;

-- ### Add all points, round the sums to 2 digits
SELECT ROUND(sum(points), 2) FROM customers;

-- --------------------------------------------------------------- STRING FUNCTIONS -------------------------------------------------------------------
USE sql_store;
SELECT concat(first_name, ' ', last_name, ', ', points) AS custDetails FROM customers;
SELECT concat_ws('-', first_name, last_name, points) custDetails FROM customers;        -- 'concat_ws' is 'concatenate with separator specified'
SELECT field("a", "n", "c", "s", "a") ;        -- position of 'a' in strings n c s a (which is 4); format of fn is: FIELD(search_value, val1, val2, val3, ...)
SELECT find_in_set("a", "m, a, l"); 
SELECT FORMAT(250500.5634, 2); -- format the no. to only two decimal places
SELECT FORMAT(250500.5634, 0); -- formats to 250501
SELECT INSERT('Monday', 1, 2, 'Su'); -- Sunday;   replace 2 chars by 'Su' starting from 1st pos in 'Monday'
SELECT INSERT('Monday', 1, 3, 'Su'); -- Suday;   replace 3 chars by 'Su' starting from 1st pos in 'Monday'
SELECT INSERT('Monday', 1, 1, 'Su'); -- Suonday

SELECT INSTR("W3Schools.com", "3") AS MatchPosition; -- 2 ; position of '3' in 'w3schools.com'
SELECT INSTR("W3Schools.com", "z") AS MatchPosition; -- 0
SELECT first_name, INSTR(first_name, 'e') AS MatchPosition FROM customers;
SELECT LCASE(first_name) AS LowerCaseCustNames FROM CUSTOMERS; -- returns all first_names in 'customers' table into lowercase
SELECT LOWER(first_name) AS LowerCaseCustNames FROM CUSTOMERS; -- same result as above fn LCASE
SELECT UCASE(first_name) AS LowerCaseCustNames FROM CUSTOMERS; -- returns all first_names in 'customers' table into uppercase
SELECT UPPER(first_name) AS LowerCaseCustNames FROM CUSTOMERS; -- same result as above fn UCASE

USE sql_store;

SELECT LEFT(first_name, '3') AS Leftmost3Chars FROM customers; -- returns 3 chars from first_name from Left side
SELECT RIGHT(first_name, '3') AS Rightmost3Chars FROM customers; -- returns 3 chars from first_name from Right side
SELECT first_name, LENGTH(first_name) AS nameLength FROM customers; -- returns names and their lengths

-- The LOCATE() fn returns pos of 1st occurrence of a substring in a string. If substring is not found within original string, fn returns 0.

SELECT first_name, LOCATE('a', first_name) AS location FROM customers; -- returns positions of 'a' in all first_names
SELECT first_name, POSITION('a' IN first_name) AS location FROM customers; -- same o/p as in above fn, no difference

SELECT first_name, LPAD(first_name, 15, 'SQL') AS LPaddedFirstName FROM customers; -- returns first_names left-padded with 'SQL' such that length = 15 e.g. 'SQLSQLSQLBabara'
SELECT first_name, RPAD(first_name, 15, 'SQL') AS LPaddedFirstName FROM customers; -- returns first_names right-padded with 'SQL' such that length = 15

SELECT LTRIM("     SQL Tutorial") AS LeftTrimmedString; -- LTRIM() fn removes leading spaces from a string
SELECT RTRIM("SQL Tutorial     ") AS RightTrimmedString; -- RTRIM() fn removes trailing spaces from a string
SELECT TRIM('    MySQL    '); -- trim() fn removes both leading and trailing spaces

SELECT MID("SQL Tutorial", 5, 5) AS ExtractString; -- returns 'Tutor'
SELECT MID("SQL Tutorial", -5, 5) AS ExtractString; -- returns 'orial'
SELECT SUBSTR("SQL Tutorial", 3, 5) AS ExtractString; -- returns 'L Tut'
SELECT SUBSTRING("SQL Tutorial", 3, 5) AS ExtractString; -- returns 'L Tut' same as above SUBSTR fn

-- ------------ 'subtring_index()' returns a substring of a string before a specified number of delimiter occurs. ---------------------
SELECT SUBSTRING_INDEX('www.sql.com', '.', 2); -- prints 'www.sql'
SELECT SUBSTRING_INDEX('This+is+a+test', '+', 3); -- prints 'This+is+a'
SELECT SUBSTRING_INDEX('This+is+a+test', '+', -2); -- prints 'a+test'
SELECT SUBSTRING_INDEX('Tom Hanks Wilson', ' ', 1); -- returns firstname 'Tom' (the string before first space)

-- SELECT first_name, REPEAT(first_name, 3) AS RepeatedNames FROM customers; -- returns first_name repeated 3 times (without spaces in b/w)

SELECT first_name, REPLACE(first_name, 'e', 'TOM') AS ReplacedName FROM customers; -- returns first_name with 'e' replaced by 'TOM'
SELECT REPLACE('ABC', 'z', 'p'); -- o/p is ABC;  there is no 'z' to be replaced with 'p'
SELECT first_name, REVERSE(first_name) FROM customers; -- prints each first_name in reverse

SELECT SPACE(10); -- space() fn returns a string of the specified number of space characters.
SELECT STRCMP("SQL Tutorial", "HTML Tutorial"); -- strcmp(str1, str2) returns -1/0/1 if str1 is <, = or > str2 respectively

-- ---------------------------------------------------------------------------------NUMERIC FUNCTIONS-------------------------------------------------------------------
SELECT ABS(-23.654); -- returns absolute value (positive) of a number; takes only one number in parentheses

-- specified numbers in following 2 functions must be between -1 to 1, otherwise functions return NULL.
SELECT ACOS(0.25); --  1.318116071652818
SELECT ACOS(2); -- NULL
SELECT ASIN(-0.3); -- 0.3046926540153975

-- --------------------------------- Trigonometric fns ------------------------------
SELECT COS(PI()); --    -1
SELECT COS(60); --   -0.9524129804151563
SELECT COS( (60 * PI()) / 180); -- 0.5000000000000001
SELECT SIN(60); --    -0.3048106211022167
SELECT SIN( (30 * PI()) / 180); --  0.49999999999999994
SELECT TAN(45); -- 1.6197751905438615
SELECT TAN((45 * PI()) / 180); -- in real life we take tan45 as 1, here it prints 0.9999999999999999
SELECT COT(45); -- 0.6173696237835551
SELECT COT((45 * PI()) / 180); -- 1.0000000000000002


-- ATAN() and ATAN2() take 1 or 2 parameters; returns arc tangent
SELECT ATAN(0.8); -- 0.6747409422235527
SELECT ATAN2(0.8); -- same result as in above line
SELECT ATAN(0.8, 3); -- 0.260602391747341
SELECT ATAN2(-0.8, 2); -- -0.3805063771123649 ;

-- AVG(expr): expr can be a column from a table or a formula
USE sql_store;
SELECT AVG(points) FROM customers ;
SELECT * FROM customers WHERE points > (SELECT AVG(points) FROM customers);

SELECT CEIL(23.4); -- 24
SELECT CEIL(23.6); -- 24
SELECT CEIL(-23.5); --   -23
SELECT CEILING(23.5); -- 24
SELECT CEILING(-23.5); --   -23
SELECT FLOOR(23.5); -- 23
SELECT FLOOR(-23.5); --   -24
SELECT FLOOR(23.6); -- 23
SELECT ROUND(135.375, 2); -- 135.38
SELECT ROUND(135.5); -- 136
SELECT ROUND(135.4); -- 135
SELECT TRUNCATE(135.375, 2); -- 135.37
SELECT TRUNCATE(135.375, 0); -- 135

USE sql_store;
SELECT COUNT(points) FROM customers; -- count() fn returns the number of records returned by a select query.

SELECT DEGREES(1); -- 57.29577951308232 ; degrees() converts radian value to degree
SELECT DEGREES(-10); --    -572.9577951308232
SELECT DEGREES(PI()*2); -- 360
SELECT RADIANS(180); -- 3.141592653589793
SELECT RADIANS(-90); --   -1.5707963267948966

-- ------ DIV() function is used for integer division (x is divided by y). An integer value is returned. --------
SELECT 8 DIV 3; -- 2
SELECT -8 DIV -4; -- 2
-- exp() fn raises e (2.718281...) to the power of num in parentheses
SELECT EXP(2); -- 7.38905609893065

SELECT GREATEST("w3Schools.com", "microsoft.com", "apple.com"); -- w3Schools.com
SELECT GREATEST('tom', 23); -- tom
SELECT GREATEST(22.3, 23, 19, 26, -22); -- 26.0
SELECT GREATEST(22, 23, 19, 26, -22); -- 26
SELECT LEAST(22.3, 23, 19, 26, -22); --    -22.0
SELECT LEAST(22, 23, 19, 26, -22); --   -22
SELECT LEAST('tom', 23); -- 23

USE sql_store;
SELECT LN(2); -- 0.6931471805599453   ;    natural logarithm fn
SELECT LN(EXP(1)); -- 1
SELECT LOG(2); -- 0.6931471805599453  ;   same result as in LN(2) above
SELECT LOG(2, 4); -- 2 ;  log of 4 to base 2
SELECT LOG10(2); -- 0.3010299956639812 ; log of 2 to base 10;  Logarithms work only for num > 0;
SELECT LOG2(2); -- 1
SELECT LOG2(-2); -- NULL

SELECT MAX(points), MIN(points) FROM customers;
SELECT 18 MOD 4 AS modValue1, 18%4 AS modValue2, MOD(18, 4) AS modValue3; -- 2   2   2
SELECT POW(4, 2); -- 16 ;   power() gives same result

SELECT RAND(); -- prints random num in [0, 1) i.e. 0 is included
SELECT RAND(6); 
SELECT RAND() * (10 - 5) + 5; -- returns random float number in [5, 10) i.e. 5 is included
SELECT FLOOR(RAND()*(10-5+1)+5); -- returns random num in [5, 10]

SELECT SIGN(2), SIGN(-2), SIGN(0); --    1   -1   0
SELECT SIGN(points) FROM customers;
SELECT SQRT(points) FROM customers; -- square roots of all points in 'customers' table

-- -------------------------------------------------------------------------------- DATE FUNCTIONS --------------------------------------------------------------------------------

USE sql_store;
SELECT CURRENT_DATE; -- returns today's date
SELECT ADDDATE(CURRENT_DATE , INTERVAL 2 MONTH); -- returns current date forwarded to 2 months
SELECT ADDDATE(CURRENT_DATE + 1, INTERVAL 10 DAY);    -- returns tomorrow's date forwarded to 10 days
SELECT ADDDATE(CURRENT_DATE, INTERVAL 10 YEAR); -- returns present date forwarded to 10 years
SELECT ADDDATE("2015-06-15", INTERVAL 10 DAY); -- 2015-06-25
SELECT ADDDATE("2017-06-15 09:34:21", INTERVAL 15 MINUTE); -- 2017-06-15 09:49:21
SELECT ADDDATE("2017-06-15 09:34:21", INTERVAL -3 HOUR);  -- 2017-06-15 06:34:21
SELECT ADDDATE("2017-06-15", INTERVAL -2 MONTH); -- 2017-04-15

SELECT ADDTIME("2017-06-15 09:34:21.000001", "5.000003"); -- 2017-06-15 09:34:26.000004
SELECT ADDTIME("2017-06-15 09:34:21.000001", "2:10:5.000003"); -- 2017-06-15 11:44:26.000004
SELECT ADDTIME("2017-06-15 09:34:21.000001", "5 2:10:5.000003"); -- 2017-06-20 11:44:26.000004   ;  Note: date changed from 15/06 to 20/6 and time by 2:10:5.000003
SELECT ADDTIME("09:34:21.000001", "2:10:5.000003"); -- 11:44:26.000004

-- The curdate() and currentdate() fns work same way.
SELECT CURDATE(); -- returns date in YYYY-MM-DD format (as string) or YYYYMMDD format (numeric)
SELECT CURRENT_DATE(); -- same result as in above stmt
SELECT CURDATE() + 1; -- returns tomorrow's date (as 20230904)
SELECT CURRENT_DATE() + 1; -- 20230904

SELECT CURRENT_TIME(); -- 16:04:24
SELECT CURTIME(); -- 16:04:38
SELECT CURRENT_TIMESTAMP(); -- 2023-09-03 16:05:20

SELECT DATE("2017-06-15 09:34:21"); -- 2017-06-15  ; this fn extract the date part
SELECT DATE('2017-06-15'); -- same result as in above stmt
SELECT DATE(birth_date) FROM customers;
SELECT DATEDIFF("2017-06-25", "2017-06-15"); -- 10  ;   returns no. of days between  two dates (1st date -  2nd date)
SELECT DATEDIFF("2017-06-15", "2017-06-25"); --  -10
SELECT DATEDIFF("2017-06-25 09:34:21", "2017-06-15 15:25:35"); -- 10

SELECT DATE_ADD("2017-06-15 09:34:21", INTERVAL 15 MINUTE); -- 2017-06-15 09:49:21
SELECT DATE_ADD("2017-06-15 09:34:21", INTERVAL -3 HOUR); -- 2017-06-15 06:34:21
SELECT DATE_ADD("2017-06-15", INTERVAL -2 MONTH); -- 2017-04-15

SELECT DATE_FORMAT("2017-06-15", "%M %d %Y"); -- June 15 2017  ;   %m would yield 06 for June ;   %y would yield 17 for 2017 ;  similarly there are other formattings available on Internet
SELECT DATE_FORMAT("2017-06-15", "%W %M %e %Y"); -- Thursday June 15 2017   ;  %e for day of month as numeric value
SELECT DATE_FORMAT(birth_date, "%W %M %e %Y") FROM customers;
SELECT DAY("2017-06-15 09:34:21"); -- 15
SELECT DAY(CURDATE());
SELECT DAYNAME(CURDATE()); -- Thursday (since it's Thursday on the day of this line's run)
SELECT DAYOFMONTH(CURDATE()); -- same as DAY() fn above
SELECT DAYNAME(birth_date), DAYOFMONTH(birth_date), DAYOFWEEK(birth_date), DAYOFYEAR(birth_date) FROM customers;
SELECT DAYNAME("2023-09-07"), DAYOFWEEK("2023-09-07");





