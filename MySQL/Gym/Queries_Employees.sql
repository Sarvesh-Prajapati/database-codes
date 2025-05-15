USE sql_forda;
SELECT * FROM sql_forda.employees;

-- Each dept's total salary as % of net salary of all depts
SELECT 
    deptid
    , SUM(salary) AS total_dept_sal
    , SUM(SUM(salary)) OVER () AS net_sal
    , (SUM(salary) / SUM(SUM(salary)) OVER ()) * 100 AS pct_of_net FROM employees 
GROUP BY deptid;

-- SELECT SUM(SUM(salary)) OVER() FROM employees;  -- returns 529000
-- SELECT SUM(salary) OVER() FROM employees;   -- returns 529000 for each row

-- Dept having more than 3 employees
SELECT deptid 
FROM employees
GROUP BY deptid 
HAVING COUNT(DISTINCT empid) > 3;

-- Employees having salaries greater than overall avg salary (NOT THE TRIVIAL QUERY!)
WITH CTE_avg_sal AS
(SELECT avg(salary) AS avgsal FROM employees )
SELECT fullname, salary, avgsal 
FROM employees JOIN CTE_avg_sal ON 1=1     -- select and run upto this line to see intermediate result
WHERE salary > avgsal;

-- Instantly getting no. of rows in a table [ coz COUNT(*) will be slow for, say, 500 million rows so we query metadata]
SELECT TABLE_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'sql_forda' AND TABLE_NAME = 'c4_legislators_terms';


-- Calculate table sizes in different memory units

SELECT 
     table_schema AS `Database`
     , table_name AS `Table`
     , ROUND((data_length + index_length) / (1024), 2) AS `Size (B)`
     , ROUND((data_length + index_length) / (1024 * 1024), 2) AS `Size (MB)`
     , ROUND((data_length + index_length) / (1024 * 1024 * 1024), 2) AS `Size (GB)`
FROM information_schema.tables
WHERE table_schema = 'sql_forda' AND table_name = 'c7_game_actions';

-- Running total of salaries without window functions

SELECT
 A.hiredate,
 A.salary,
 (
 SELECT SUM(B.salary)
 FROM employees B
 WHERE B.hiredate <= A.hiredate
 ) AS RunningTotal
FROM employees A
ORDER BY A.hiredate;

-- ------------------ N'th Highest Salary ---------------------------------------------

SET @prev_salary = NULL;
SET @temp_rank = 0;

WITH CTE_Salary_Ranked AS 
(SELECT
	salary
    , @temp_rank := IF(salary = @prev_salary, @temp_rank, @temp_rank + 1) AS salary_rank
    , @prev_salary := salary
FROM (SELECT DISTINCT salary FROM employees ORDER BY salary DESC) tmp_tbl
)
SELECT salary FROM CTE_Salary_Ranked WHERE salary_rank = 3;    -- Third highest salary

-- Checking NULLs in all columns

SELECT CONCAT        -- Generates a SELECT statement as output
(
  'SELECT ', 
   GROUP_CONCAT(CONCAT('SUM(`', COLUMN_NAME, '` IS NULL) AS `', COLUMN_NAME, '_nulls`') SEPARATOR ', '),
   -- GROUP_CONCAT(CONCAT('SUM(', COLUMN_NAME, ' IS NULL) AS ', COLUMN_NAME, '_nulls') SEPARATOR ', '),        will also work
  ' FROM employees;'
) AS auto_selecting_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'sql_forda' AND TABLE_NAME = 'employees';

SELECT                -- Here is the SELECT statement generated as o/p in above query
	SUM(`empid` IS NULL) AS `empid_nulls`
	, SUM(`fullname` IS NULL) AS `fullname_nulls`
	, SUM(`deptid` IS NULL) AS `deptid_nulls`
    , SUM(`salary` IS NULL) AS `salary_nulls`
    , SUM(`hiredate` IS NULL) AS `hiredate_nulls`
    , SUM(`mgrid` IS NULL) AS `mgrid_nulls`
FROM employees;

-- All info about every column of `employees` table
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'sql_forda' AND TABLE_NAME = 'employees';

-- Table `employees` size in Mb
SELECT TABLE_NAME, sum( data_length + index_length ) / 1024 / 1024 "Table Size in MB" 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'sql_forda' AND table_name = 'employees'
GROUP BY 1;


-- ------------------ N'th Highest Salary (Using variables) ---------------------------------------------
SET @prev_salary = NULL;
SET @temp_rank = 0;
WITH CTE_Salary_Ranked AS 
(SELECT
    salary
    , @temp_rank := IF(salary = @prev_sal, @temp_rank, @temp_rank + 1) AS salary_rank
    , @prev_sal := salary
FROM (SELECT DISTINCT salary FROM employees ORDER BY salary DESC) tmp
) SELECT salary FROM CTE_Salary_Ranked WHERE salary_rank = 3;            -- third highest salary, as an example

-- Checking NULLs in all columns

SELECT CONCAT                                          -- Generates a SELECT statement as output
(
  'SELECT ',
   GROUP_CONCAT(CONCAT('SUM(`', COLUMN_NAME, '` IS NULL) AS `', COLUMN_NAME, '_nulls`') SEPARATOR ', '),
  ' FROM employees;'
) AS auto_selecting_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'sql_forda' AND TABLE_NAME = 'employees';

SELECT                                                  -- Here is the SELECT statement generated as o/p in above query
     SUM(`empid` IS NULL) AS `empid_nulls`
    , SUM(`fullname` IS NULL) AS `fullname_nulls`
    , SUM(`deptid` IS NULL) AS `deptid_nulls`
    , SUM(`salary` IS NULL) AS `salary_nulls`
    , SUM(`hiredate` IS NULL) AS `hiredate_nulls`
    , SUM(`mgrid` IS NULL) AS `mgrid_nulls`
FROM employees;

-- Replacing all vowels with underscore in column names
SELECT COLUMN_NAME, REGEXP_REPLACE(COLUMN_NAME, '[aeiou]', '_' ) AS new_col_name
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'sql_forda' AND TABLE_NAME = 'employees';

-- Generating ALTER TABLE stmts to rename all columns
SELECT CONCAT('ALTER TABLE `employees` RENAME COLUMN `', COLUMN_NAME, '` TO `', REPLACE(COLUMN_NAME, ' ', '_'), '`;') AS rename_statement
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'sql_forda' AND TABLE_NAME = 'employees';


-- ------------------ Who is the manager of who ---------------------------------------
-- SELECT * from employees;
SELECT e.empid as e_empid, e.fullname as emp_name, m.fullname As mgr_name, m.mgrid AS m_mgrid FROM employees e JOIN employees m
WHERE e.mgrid = m.empid AND e.fullname <> m.fullname;

-- ---------------- Who's the boss of all the employees (above query in CTE) -------------------------------
WITH emp_boss AS 
(SELECT e.empid as e_empid, e.fullname as emp_name, m.fullname As mgr_name, m.mgrid AS m_mgrid FROM employees e JOIN employees m
WHERE e.mgrid = m.empid AND e.fullname <> m.fullname)
SELECT DISTINCT mgr_name AS BOSS FROM emp_boss WHERE m_mgrid IS NULL;

SELECT * FROM sql_forda.employees 
JOIN (VALUES ROW(1), ROW(2), ROW(3), ROW(4), ROW(5), ROW(6), ROW(7), ROW(8), ROW(9), ROW(10)) AS column_0 ON empid = column_0;

-- creating a table having year and month using VALUES, ROW and LATERAL
SELECT years.year, months.month 
FROM (VALUES ROW(2023), ROW(2024)) AS years(year)    -- 'years(year)' follows 'tbl_name(col_name)'
JOIN (VALUES ROW(1), ROW(2), ROW(3), ROW(4), ROW(5), ROW(6), ROW(7), ROW(8), ROW(9), ROW(10), ROW(11), ROW(12)) AS months(month)
ORDER BY year;

SELECT years.year, months.month 
FROM (VALUES ROW(2023), ROW(2024)) AS years(year),    -- 'years(year)' follows 'tbl_name(col_name)'
LATERAL (VALUES ROW(1), ROW(2), ROW(3), ROW(4), ROW(5), ROW(6), ROW(7), ROW(8), ROW(9), ROW(10), ROW(11), ROW(12)) AS months(month)
ORDER BY year;

-- Between the earliest and latest 'hiredate', find name of hirees each month; put '**NONE**' in case nobody was hired in a month
-- SELECT min(hiredate) AS mindate, max(hiredate) AS maxdate FROM employees;
SELECT years.year_hired, months.month_hired, COALESCE(tmp.fullname, '**NONE**') AS employeename
FROM (VALUES ROW(2012), ROW(2013), ROW(2014), ROW(2015), ROW(2016), ROW(2017), ROW(2018), ROW(2019), ROW(2020)) AS years(year_hired)    -- 'years(year_hired)' follows 'tbl_name(col_name)'
JOIN (VALUES ROW(1), ROW(2), ROW(3), ROW(4), ROW(5), ROW(6), ROW(7), ROW(8), ROW(9), ROW(10), ROW(11), ROW(12)) AS months(month_hired)
LEFT JOIN
(SELECT fullname, YEAR(hiredate) AS hireyear, MONTH(hiredate) AS hiremonth FROM employees) tmp 
ON tmp.hireyear = years.year_hired AND tmp.hiremonth = months.month_hired
ORDER BY year_hired;

-- -------------------------------------SOLVING THE ABOVE PROBLEM USING CTEs-----------------------------------------
SET @yr = 2012, @mnth = 1;
WITH RECURSIVE years AS                             -- creating col containing years from 2012 till 2020
(
	SELECT @yr AS yrs UNION ALL SELECT yrs + 1 FROM years WHERE yrs <= 2019
),
months AS                                           -- creating col containing months from 1 till 12
(
	SELECT @mnth AS mnths UNION ALL SELECT mnths + 1 FROM months WHERE mnths <= 11
) 
SELECT yrs, mnths, COALESCE(tmp.fullname, '-----') AS emp_name 
FROM years JOIN months ON 1=1
LEFT JOIN 
(SELECT fullname, YEAR(hiredate) AS hireyear, MONTH(hiredate) AS hiremonth FROM employees) tmp
ON yrs = hireyear AND mnths = hiremonth
ORDER BY yrs, mnths;


SELECT version() AS MySQLVer, user() AS CurrUser, database() AS CurrDB;

-- emp salary less than own dept avg salary but more than other dept avg salary
SELECT e.empid AS emp_id, e.deptid AS e_deptid, e1.deptid AS e1_deptid, e.salary AS e_sal, e1.avgsal AS e1_avgsal FROM employees e
INNER JOIN
(SELECT deptid, AVG(salary) AS avgsal FROM employees GROUP BY deptid) e1
ON e.deptid = e1.deptid AND e.salary < e1.avgsal
AND e.salary > ANY (SELECT AVG(salary) AS avgsal FROM employees GROUP BY deptid);

-- dept where no employee has sal > mgr's sal
SELECT e.fullname AS EMPNAME, e.salary AS EMPSAL, e.mgrid AS EMPMGRID, m.empid AS MGREMPID, m.fullname AS MGRNAME, m.salary AS MGRSAL
FROM employees e JOIN employees m ON e.mgrid = m.empid WHERE e.salary < m.salary;

-- diff b/w emp sal and avg sal of his dept
WITH cte AS 
(SELECT e.fullname AS ENAME, e.deptid AS EDEPTID, e.salary AS EMPSAL, t.deptid AS TDEPTID,
t.dptavgsal AS AVGSAL 
FROM employees e INNER JOIN (SELECT deptid, AVG(salary) AS dptavgsal FROM employees GROUP BY deptid) t
ON e.deptid = t.deptid)
SELECT ENAME, EMPSAL - AVGSAL AS difference FROM cte;

-- total salary of each dept followed by total salary as a rollup row on all depts
SELECT IF(GROUPING(deptid), "ALL DEPTS", deptid) AS DEPTARTMENT, SUM(salary) AS SAL_SUM FROM employees GROUP BY deptid WITH ROLLUP;

-- list those emps whose salaries are more than salaries of emps in dept 2
SELECT * FROM employees WHERE salary > ALL (SELECT salary FROM employees WHERE deptid = 2);

SELECT * FROM
(WITH cte AS (SELECT e.deptid AS EMPDEPT, 0.90 * AVG(salary) AS AVGSAL FROM employees e GROUP BY e.deptid)
SELECT *, ROW_NUMBER() OVER(PARTITION BY deptid) AS rownum FROM employees e1 JOIN cte c ON e1.deptid = EMPDEPT AND e1.salary > AVGSAL) t
WHERE rownum >= 2;

-- Hierarchy of employees (as level 0, 1, 2, ...)
WITH RECURSIVE cte AS
(
	SELECT empid, fullname, mgrid, 0 AS EMPLEVEL FROM employees WHERE mgrid IS NULL
    UNION ALL
    SELECT e.empid, e.fullname, e.mgrid, EMPLEVEL + 1
    FROM employees e 
    INNER JOIN cte mgr ON e.mgrid = mgr.empid
) SELECT * FROM cte;

-- count of salaries < 50k and salaries > 50k in each dept
SELECT deptid, SUM(CASE WHEN salary <= 50000 THEN 1 ELSE 0 END) AS cnt_LT_50k, 
SUM(CASE WHEN salary > 50000 THEN 1 ELSE 0 END) AS cnt_MT_50k
FROM employees GROUP BY 1;

-- for each dept, get names of employees as a list 
SELECT deptid, GROUP_CONCAT(fullname) AS employeenames FROM employees GROUP BY deptid;

-- how SUM, COUNT producing output in following window fn queries is not understood
SELECT deptid, mgrid, SUM(mgrid) OVER(PARTITION BY deptid ORDER BY mgrid) AS summed FROM employees;
SELECT deptid, mgrid, COUNT(mgrid) OVER(PARTITION BY deptid ORDER BY mgrid DESC) AS counted FROM employees;
SELECT deptid, mgrid, salary, hiredate, COUNT(salary) OVER(PARTITION BY deptid, mgrid ORDER BY hiredate) AS cnt FROM employees;


-- ------------------------------------------- MISCELLANEOUS ------------------------------------------

SELECT 'hello' + 'world';           -- 0
SELECT 'hello' * 3;                 -- 0
SELECT 'hello' * 'hello';           -- 0 
SELECT NULL + 'hello';              -- NULL
SELECT NULL / NULL + 3;             -- NULL
SELECT NULL UNION SELECT NULL;      -- NULL
SELECT 'hello' UNION SELECT '';     -- hello
SELECT 'hello' FROM (SELECT NULL) tmp;   -- hello
SELECT NULL FROM (SELECT 'hello') tmp;   -- NULL
SELECT t.num * 2 + 2 AS calculation
FROM (VALUES ROW(1), ROW(2), ROW(3)) AS t(num) 
ORDER BY t.num DESC;                  -- 8, 6, 4


SHOW TABLE STATUS LIKE '%sales%';

SELECT CHAR(65);   -- o/p: A
SELECT CONVERT(CHAR(65) USING utf8);  -- o/p: A
SELECT CONVERT(CHAR(65,' ',66) USING utf8);   -- o/p: A B
SELECT ORD('a');  -- o/p: 97
SELECT ORD('ba');  -- o/p: 98   (ORD fn returns ASCII of ONLY the first char in its arg)

-- generating a number series using recursive cte
WITH RECURSIVE rcte AS
(
   SELECT 1 AS cnt
   UNION ALL
   SELECT cnt + 1 FROM rcte WHERE cnt < 10
) SELECT * FROM rcte JOIN sql_store.customers WHERE cnt = customer_id;

USE sql_forda;
SET @pointer = 1;
WITH RECURSIVE cte AS
(
	SELECT @pointer AS ptr
    UNION ALL
    SELECT ptr + 2 FROM cte WHERE ptr <= 9
)
SELECT empid, fullname, GROUP_CONCAT(SUBSTR(fullname, ptr, 1) SEPARATOR '') AS sbstr FROM employees e JOIN cte c ON 1=1 GROUP BY empid;
-- SELECT GROUP_CONCAT(SUBSTR(wiz, ptr, 1) SEPARATOR '') AS sbstr FROM cte;  -- RETURNS ABOVE O/P IN SINGLE ROW

-- generating a list of capital letters of english
WITH RECURSIVE cte AS
(	SELECT CHAR(65) AS letter
	UNION ALL
    SELECT CHAR(ORD(letter) + 1) FROM cte WHERE letter < 'Z'
) SELECT * FROM cte;

 SHOW VARIABLES LIKE "secure_file_priv";   -- shows path to the folder where output of following query is sent in a text file
-- ------------ finding Factorial of a number using recursive CTE and sending the output to a text file-----------

SET @f = 15, @v = 15;
WITH RECURSIVE factorial AS
(
	SELECT @f AS num, @v AS val
    UNION ALL
    SELECT 
		@f := COALESCE(@f * (@v - 1), NULL),
		@v := COALESCE(@v - 1, NULL)
    FROM factorial WHERE @v > 1
)
SELECT * INTO OUTFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\temp.txt' FROM factorial;  
-- only the path used as above format works, using any other path throws error
-- locate the saved file without double slashes in filepath: 'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads'





