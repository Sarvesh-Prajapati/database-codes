-- Query typing order is: SELECT, FROM [JOINS], WHERE, GROUP BY, HAVING, ORDER BY
-- Query processing order is: FROM [JOINS], WHERE, GROUP BY, HAVING, SELECT, [Window Fns if any], ORDER BY

USE sql_cookbook;
SHOW TABLES; -- shows all tables in sql_cookbook database; also shows views
SELECT table_name FROM information_schema.tables WHERE table_schema = 'sql_cookbook'; -- hard-coded way to show tables in sql_cookbook as in above query
DESCRIBE dept; -- describes table 'dept'

SELECT * FROM emp; -- returns all rows of table 'emp'
SELECT * FROM dept; -- returns all rows of table 'dept' 

SELECT * FROM emp LIMIT 5; -- returns only top 5 rows
SELECT * FROM emp ORDER BY rand() LIMIT 5; -- returns random 5 rows from 'emp' table

SELECT ename FROM emp WHERE deptno = 10;
SELECT sal AS Salary, comm AS Commission FROM emp;

SELECT sal AS Salary, comm AS Commission FROM emp WHERE Salary < 5000; -- error as alias 'Salary' can't be used in WHERE (recall query processing order)
SELECT * FROM (SELECT sal AS Salary, comm AS Commission FROM emp) tmp WHERE Salary < 5000; -- above query modified with parentheses after FROM

SELECT ename, job FROM emp WHERE deptno = 10;
SELECT CONCAT(ename, ' works as a ', job) AS Message FROM emp WHERE deptno = 10;

SELECT * FROM emp 
WHERE deptno = 10 OR comm IS NOT NULL OR sal <=2000 AND deptno = 20;
-- above query with parentheses in WHERE clause
SELECT * FROM emp 
WHERE (deptno = 10 OR comm IS NOT NULL OR sal <=2000) AND deptno = 20;

-- Date formattings
SELECT
				hiredate,
                DATE_FORMAT(hiredate, '%Y-%m') AS JustHireDate,
                EXTRACT(YEAR FROM hiredate) AS HireYear,
                YEAR(hiredate) AS HireYear2,
                extract(MONTH FROM hiredate) AS HireMonth,
                MONTHNAME(hiredate) AS HireMonth2
FROM emp;

-- -----------------------------------------------------------Conditional logic (CASE-WHEN-THEN-ELSE-END) ---------------------------------------------
SELECT ename, sal,
	CASE
		WHEN sal <=2000 THEN 'UNDERPAID'
        WHEN sal >= 4000 THEN 'OVERPAID'
        ELSE 'OK'
	END AS 'STATUS'
FROM emp;

-- Transforming NULL values in a column to other values
SELECT COALESCE(comm, 0) FROM emp; 
-- above query can be re-written as CASE-WHEN-THEN form as follows
SELECT 
	CASE 
		WHEN comm IS NOT NULL THEN comm
        ELSE 0
	END AS 'Nulls Replaced'
FROM emp;

SELECT ename, job, deptno FROM emp WHERE deptno IN (10, 20);
-- Return enames that have either an 'I' somewhere in their name or a job ending with 'ER'
SELECT ename, job, deptno FROM emp 
WHERE deptno IN (10, 20)
HAVING ename LIKE '%I%' OR job LIKE '%ER';
-- above query can also be written as:
SELECT ename, job, deptno FROM emp 
WHERE deptno IN (10, 20) AND (ename LIKE '%I%' OR job LIKE '%ER');

-- -------------------------------------------------------------------------------------ORDER BY ------------------------------------------------------------------------------

-- Display the names, jobs, and salaries of employees in department 10 in order based on their salary (from lowest to highest)
SELECT ename, job, sal FROM emp WHERE deptno = 10 ORDER BY sal ASC;
SELECT ename, job, sal FROM emp WHERE deptno = 10 ORDER BY 3 DESC; -- ordinal position of 'sal' (which is 3 in SELECT) can be use for DESC sorting

-- Sort the rows from EMP first by DEPTNO ascending, then by salary descending.
SELECT empno,deptno,sal,ename,job FROM emp ORDER BY deptno ASC, sal DESC;

--  Return employee names and jobs from table EMP and sort by the last two characters in the JOB field
SELECT ename, job FROM emp ORDER BY SUBSTR(job, LENGTH(job)-1) ;

-- SQL Cookbook Page-45
-- Sorting NULLs first or NULLs last (while also sorting non-NULLs asc/desc simultaenously)
SELECT * FROM emp ORDER BY comm DESC; -- this is a simple sorting of NULLs 
-- Sort NULL values differently than non-NULL values e.g. sort non-NULL values in ASC/DESC order & all NULL values last; use a CASE expression to conditionally sort column
SELECT ename, sal, comm
FROM
	(SELECT ename, sal, comm,   -- nested query
		CASE WHEN comm IS NULL THEN 0 ELSE 1 END AS is_NULL
	FROM emp) tmp
ORDER BY is_NULL DESC, comm DESC;

-- Re-writing above query using CTE to make is_NULL column visible for better understanding
WITH cte AS 
(SELECT ename, sal, comm,
	CASE WHEN comm IS NULL THEN 0 ELSE 1 END AS is_NULL
FROM emp)
SELECT ename, sal, comm, is_NULL
FROM cte
ORDER BY is_NULL DESC, comm ; -- NULLs last, comm ASC 

-- Page-50: SORTING ON A DATA-DEPENDENT KEY
-- if JOB is 'SALESMAN', sort on COMM; otherwise, sort by SAL.
SELECT ename, sal, job, comm
FROM emp
ORDER BY 
	CASE
		WHEN job = 'SALESMAN' THEN comm
        ELSE sal
	END;
-- above query can be re-written as:
SELECT ename, sal, job, comm,
	CASE WHEN job = 'SALESMAN' THEN comm
    ELSE sal
    END AS Ordered
FROM emp
ORDER BY Ordered;

-- ------------------------------------------------ WORKING WITH MULTIPLE TABLES (JOINS & UNIONS etc.) Page-52----------------------------------------------------------

-- As with all set operations, columns in all the SELECT lists must match in number & data type.
SELECT ename AS Ename_and_Dname, deptno FROM emp WHERE deptno = 10
UNION ALL
SELECT '-------------------', '-----'
UNION ALL
SELECT dname, deptno FROM dept;

-- UNION ALL includes duplicates if they exist.
SELECT deptno FROM emp
UNION ALL
SELECT deptno FROM dept;

-- Re-writing above query (same output)
SELECT DISTINCT deptno
FROM 
	(SELECT deptno FROM emp
	UNION ALL
	SELECT deptno FROM dept) tt; -- 'tt' is alias (mandatory) for derived table 

-- Use UNION to exclude duplicates.  
SELECT deptno FROM emp
UNION
SELECT deptno FROM dept;

-- Next query is an example of a JOIN, or more accurately an equi-join, which is a type of inner join. A join is an operation that combines rows from 2 tables into one. An
-- equi-join is one in which the join condition is based on an equality condition (e.g., where one department number equals another).
SELECT e.ename, d.loc FROM emp e, dept d 
WHERE e.deptno = d.deptno AND e.deptno = 10;

-- Conceptually, the result set from a join is produced by first creating a Cartesian product (all possible combinations of rows) from the tables listed in FROM clause
SELECT e.ename, d.loc, 
	e.deptno AS EMP_DEPTNO, 
    d.deptno AS DEPT_DEPTNO
FROM emp e, dept d WHERE e.deptno = 10;

-- WHERE clause involving e.deptno & d.deptno (the join) restricts result set with only those rows returned where EMP.DEPTNO and DEPT.DEPTNO are equal:
SELECT e.ename, d.loc, 
	e.deptno AS EMP_DEPTNO, 
    d.deptno AS DEPT_DEPTNO
FROM emp e, dept d 
WHERE e.deptno = d.deptno AND e.deptno = 10;

-- An alternative to above query makes use of an explicit JOIN clause (the INNER keyword is optional)
SELECT e.ename, d.loc, 
	e.deptno AS EMP_DEPTNO, 
    d.deptno AS DEPT_DEPTNO
FROM emp e JOIN dept d ON e.deptno = d.deptno -- By default, JOIN here is INNER JOIN
WHERE e.deptno = 10;

--  following view 'vw' created from the EMP table for teaching purposes (this view is stored in 'Views' folder of the schema in Navigator pane on LHS)
CREATE VIEW vw
AS
SELECT ename, job, sal FROM emp WHERE job = 'CLERK';

-- fetching common rows from 'vw' and 'emp'
SELECT e.empno, e.ename, e.job, e.sal, e.deptno
FROM emp e, vw
WHERE e.ename = vw.ename AND e.job = vw.job AND e.sal = vw.sal;


-- re-writing above query using JOIN to produce same result (INTERSECT clause is used in DB2, PostgreSQL & Oracle)
SELECT e.empno, e.ename, e.job, e.sal, e.deptno
FROM emp e JOIN vw ON (e.ename = vw.ename AND e.job = vw.job AND e.sal = vw.sal);

-- Retrieving Values from One Table That Do Not Exist in Another (MINUS clause in Oracle, EXCEPT clause in DB2, PostgreSQL and SQL Server)
-- Find which departments (if any) in table DEPT do not exist in table EMP
SELECT d.deptno FROM dept d
WHERE d.deptno NOT IN (SELECT e.deptno FROM emp e);

-- All employees with their depts and work locations [note that dept OPERATIONS returns NULLs for 'ename' and 'deptno' (of 'emp' table)]
SELECT d.*, e.deptno AS Emp_Dept, e.ename
FROM dept d LEFT JOIN emp e
ON d.deptno = e.deptno;
-- To find dept having no employees, add a WHERE clause to above query to pick out the row having col alias 'Emp_Dept' as NULL
SELECT d.*, e.deptno AS Emp_Dept, e.ename
FROM dept d LEFT JOIN emp e
ON d.deptno  = e.deptno
WHERE e.deptno IS NULL; 

-- Employees along with location who have recd bonus (bonus is in 'emp_bonus' table)
SELECT e.ename, d.loc, eb.received
FROM 
	emp e JOIN dept d ON e.deptno = d.deptno
    LEFT JOIN emp_bonus eb ON e.empno = eb.empno -- here LEFT OUTER JOIN is happening due to which all rows of 'emp-JOIN-dept' will be retained in result-set
ORDER BY d.loc;

-- Above query can be re-written as scalar subquery (a subquery placed in the SELECT list) to mimic an outer join
SELECT e.ename, d.loc,
	(SELECT eb.received FROM emp_bonus eb
    WHERE eb.empno = e.empno) AS received
FROM emp e, dept d
WHERE e.deptno = d.deptno;

-- -------------------------------------------------------------------------------------- GROUP BY (Page-530)--------------------------------------------------------------------------
-- Count the number of employees in each dept, highest and lowest salaries in that dept
SELECT deptno,
				count(*) AS Count,
                max(sal) AS HighSal, 
                min(sal) AS LowSal
FROM emp GROUP BY deptno;

-- find no. of people in different jobs in 'emp' table
SELECT job, count(*) AS emp_count FROM emp GROUP BY job;
-- find no. of people in diff jobs, highest & lowest salaries in of each job
SELECT job, count(*) AS emp_count, max(sal), min(sal)
FROM emp GROUP BY job; 

-- In next query, by listing another column, JOB, from table EMP, we are changing the group and changing the result set. Thus, we must now include JOB in the GROUP BY clause
-- along with DEPTNO; otherwise, the query will fail. The inclusion of JOB in the SELECT/GROUP BY clauses changes the query from “How many employees are in
-- each department?" to "How many different types of employees are in each department?”
SELECT deptno, job, count(*) AS Count 
FROM emp GROUP BY deptno, job ;

-- If you choose not to put items other than aggregate functions in the SELECT list, then you may list any valid column you want in the GROUP BY clause (next 2 queries)
SELECT count(*) FROM emp GROUP BY deptno;
SELECT deptno, job, count(*) FROM emp GROUP BY deptno, job ;

-- Counting NULLs in aggregate function COUNT() 
SELECT coalesce(comm, NULL) AS tmp, count(comm) FROM emp GROUP BY comm; -- returns count of NULLs in 'comm' column as 0 coz aggregate fn neglect NULL value in a column
-- Next query returns correct count of NULLs as 10 in 'comm' column; always use * in count() fn to correctly count no. of rows having NULLs in a column
SELECT coalesce(comm, NULL) AS tmp, count(*) FROM emp GROUP BY comm; 

-- --------------------------------------------------------------------------------------WINDOW FUNCTIONS-----------------------------------------------------------------------------

-- Window functions, like aggregate functions, perform an aggregation on a defined set (a group) of rows, but rather than returning one
-- value per group, window functions can return multiple values for each group. The group of rows to perform the aggregation on is the window.

-- In next query, presence of OVER keyword indicates that invocation of COUNT will be treated as a window fn, not as an aggregate function. 
-- In general, the SQL standard allows for all aggregate functions to also be window functions, and the keyword OVER is how the language distinguishes between the two uses.
SELECT ename, 
			  deptno, 
              COUNT(*) OVER() AS Cnt
FROM emp
ORDER BY deptno; 
-- COUNT(*) OVER () in above query returns count of all the rows in the table. As empty parentheses suggest, OVER keyword accepts additional 
-- clauses to affect the range of rows that a given window function considers. Absent any such clauses, the window function looks at all rows in 
-- the result set, which is why you'll see 14 repeated in each row of output.

-- ----------------------------PARTITIONS----------------------------------------------------------------------
-- unlike a traditional GROUP BY, a group created by PARTITION BY is not distinct in a result set. You can use PARTITION BY to compute an 
-- aggregation over a defined group of rows (resetting when a new group is encountered), and rather than having one group represent all 
-- instances of that value in the table, each value (each member in each group) is returned.
SELECT 
	ename, 
    deptno, 
    COUNT(*) OVER (PARTITION BY deptno) AS CNT
FROM emp;
-- ORDER BY deptno; 
-- In above query, each employee in same dept (in same partition) will have same value for CNT, because aggregation won't reset (recompute) until new dept is encountered.

-- Above query can be re-written as a scalar query as shown ahead (but it is not as efficient as above query):
SELECT 
	e.ename, e.deptno,
    (SELECT COUNT(*) 
		FROM emp d
        WHERE e.deptno = d.deptno) AS CNT
FROM emp e
ORDER BY e.deptno;

-- PARTITION BY clause performs its computations independently of other window functions, partitioning by different columns in same SELECT statement. Consider the 
-- following query which returns each employee, their dept, number of employees in their respective dept, their job, and number of employees with the same job.
SELECT
	ename,
    deptno,
    COUNT(*) OVER (PARTITION BY deptno) AS dept_cnt,
    job,
    COUNT(*) OVER (PARTITION BY job) AS job_cnt
FROM emp
ORDER BY deptno;

-- ----- Dept-wise salary summed by year --------------------------------------------
SELECT YEAR(HIREDATE) AS HireYear, DeptNo, SUM(SAL) OVER(PARTITION BY YEAR(HIREDATE), DEPTNO) AS YearlyDeptSal FROM EMP;
-- ----Above query without Partition function
SELECT YEAR(HIREDATE) AS HireYear, DeptNo, SUM(SAL) AS SalTotal FROM EMP GROUP BY 1, 2;

-- -----------------------------------------------RANK, DENSE_RANK, ROW_NUMBER functions 
SELECT ENAME, SAL,
ROW_NUMBER() OVER(ORDER BY SAL) AS RwNo,          -- 1,2,3,4,5,6,7,8,9,10,11,12,13,14
RANK() OVER(ORDER BY SAL) AS Rnk,                                 -- 1,2,3,4,4,6,7,8,9,10,11,12,12,14
DENSE_RANK()  OVER(ORDER BY SAL) AS Dense_Rnk     -- 1,2,3,4,4,5,6,7,8,9,10,11,11,12
FROM EMP;

-- --------------------------------------------------------------------------------------- FRAME CLAUSES ---------------------------------------------------------------

-- Calculating running total of salary [ 'ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW' is called a frame clause ]

SELECT ename, deptno, sal,
    SUM(SAL) OVER (PARTITION BY deptno ORDER BY ename ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal
FROM emp;

-- 'ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW' as in above query can be shortened to 'ROWS UNBOUNDED PRECEDING'

SELECT ename, deptno, sal,
    SUM(SAL) OVER (PARTITION BY deptno ORDER BY ename ROWS UNBOUNDED PRECEDING) AS RunningTotal
FROM emp;

-- Getting rows with running total > 8000

WITH RunningTotals AS
(SELECT ename, deptno, sal,
    SUM(SAL) OVER (PARTITION BY deptno ORDER BY ename ROWS UNBOUNDED PRECEDING) AS RunningTotal
FROM emp)
SELECT * FROM RunningTotals WHERE RunningTotal > 8000 ORDER BY RunningTotal DESC;

-- ---------------------RUNNING AVERAGE SALARY---------------

SELECT ename, deptno, sal,
    AVG(SAL) OVER (PARTITION BY deptno ORDER BY deptno ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS RunningAvg
FROM emp ;

-- ---------------------------------------------------LAG and LEAD functions for prev and next values respectively (don't support frame clauses)----------------------
SELECT ename, deptno, sal,
    LAG(SAL) OVER (PARTITION BY deptno ORDER BY ename ) AS PrevSal,
    LEAD(SAL) OVER (PARTITION BY deptno ORDER BY ename) AS NextSal
FROM emp;

-- --------Successive salary difference among employees

SELECT empno, ename, deptno, sal,
    LAG(SAL) OVER(ORDER BY empno ) AS PrevSal,  -- -------- Will show value in first row for PrevSal as NULL
    SAL - LAG(SAL) OVER(ORDER BY empno) AS SalDiff
FROM emp;

-- To remove NULL in first row of above query's o/p, change the query to following:
SELECT empno, ename, deptno, sal,
    CASE 
		WHEN LAG(SAL) OVER(ORDER BY empno ) IS NULL THEN 0 
        ELSE SAL - LAG(SAL) OVER(ORDER BY empno) 
        END AS SalDiff
FROM emp;

-- Partioning by Dept, and then ranking within dept (using ROW_NUMBER)
SELECT ename, deptno, sal, COUNT(*) AS Cnt,   -- "COUNT(*) AS Cnt" gives count of every "empno+ename+depno+sal" combo in each dept
ROW_NUMBER() OVER(PARTITION BY deptno ORDER BY COUNT(*) DESC) AS RowNum
FROM emp
GROUP BY ename, deptno, sal;

-- ------------- Using CTE to find highest paid employee in each department -------------------
WITH Toppers AS
(SELECT  ename, deptno, sal,
ROW_NUMBER() OVER(PARTITION BY deptno) AS RowNum
FROM emp)
SELECT ename, deptno, sal FROM Toppers WHERE RowNum = 1;

-- --------------- Without using CTE or window function, find highest salary in each dept-------------------------------------------------

SELECT deptno,
 CASE WHEN deptno THEN max(sal) END AS MaxSal
FROM emp GROUP BY deptno ORDER BY deptno;

-- FIRST_VALUE and LAST_VALUE fns return value expression from first or last rows in window frame, respectively. Both fns support window partition, order, & frame clauses

SELECT ename, deptno, sal,
    FIRST_VALUE(SAL) OVER (PARTITION BY deptno ORDER BY ename  ROWS UNBOUNDED PRECEDING) AS FirstVal,
    LAST_VALUE(SAL) OVER (PARTITION BY deptno ORDER BY ename ROWS UNBOUNDED PRECEDING) AS LastVal, -- updating last value as frame size grows
    LAST_VALUE(SAL) OVER (PARTITION BY deptno ORDER BY ename ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS AnotherLastVal
FROM emp;

SELECT ename, deptno, sal, SUM(sal) OVER(ORDER BY deptno) AS SalSum FROM emp;









