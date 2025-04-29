USE sql_forda;

-- ---------------------- tbl: ffill -- Forward filling -------------------
SELECT * FROM ffill;

SET @var = NULL;
SELECT *, @var := COALESCE(dept, @var) AS forward_filled_dept FROM ffill;

-- OR

SET @var = NULL;
SELECT *, @var := IF(dept IS NULL, @var, dept) AS forward_filled_dept FROM ffill;

-- another solution ( IMPORTANT )
WITH cte AS
( SELECT *, COUNT(dept) OVER(ORDER BY id) AS cnt FROM ffill -- COUNT here works as ranking fn on 'dept' col when ORDER BY is not as per 'dept'
) SELECT *, FIRST_VALUE(dept) OVER(PARTITION BY cnt ORDER by id) AS ffill_value FROM cte;

-- ------------------ Following identical queries are just for testing ------------
-- SELECT *
-- 	, COUNT(dept) OVER(ORDER BY id)
--     , COUNT(dept) OVER(ORDER BY dept)  -- final ordering of o/p as per this line 
-- FROM ffill;

-- SELECT *
-- 	, COUNT(dept) OVER(ORDER BY dept)
--     , COUNT(dept) OVER(ORDER BY id)    -- final ordering of o/p as per this line
-- FROM ffill;

-- yet another solution ( IMPORTANT )
WITH cte AS 
(SELECT *, SUM(CASE WHEN dept IS NULL THEN 0 ELSE 1 END) OVER(ORDER BY id) AS flag FROM ffill)
SELECT *, FIRST_VALUE(dept) OVER(PARTITION BY flag ORDER by id) AS ffill_value FROM cte;

-- still another solution (in case interested!)
WITH cte AS
(SELECT *, SUM(CASE WHEN dept IS NULL THEN 0 ELSE id END) OVER(ORDER BY id) AS flag FROM ffill) 
SELECT * FROM cte LEFT JOIN (SELECT * FROM cte WHERE dept IS NOT NULL) tmp ON cte.flag = tmp.flag;

-- ---------------------- tbl: threevals -- finding 3 consecutive values in a column ---------------------
SELECT * FROM sql_forda.threevals;
WITH cte AS
(
	SELECT * 
		, LAG(num) OVER win AS prev_val
		, LEAD(num) OVER win AS next_val
	FROM threevals
    WINDOW win AS (order by id)                      --   NOTE how window function is defined here
)
-- SELECT * FROM cte;
SELECT num FROM cte WHERE num = prev_val AND num = next_val;

--  finding the IDs as well of the 3 consecutive nums (extending the above problem) --------------------------------
-- Run the following two queries one by one to see the logic
SELECT * 
	, DENSE_RANK() OVER(PARTITION BY num ORDER BY id) AS drnk
    , id - DENSE_RANK() OVER(PARTITION BY num ORDER BY id) AS diff 
FROM threevals;
SELECT diff, count(*) AS cnt FROM (SELECT *, id - DENSE_RANK() OVER(PARTITION BY num ORDER BY id) AS diff FROM threevals) t GROUP BY diff;

-- final solution using above two queries in CTEs
WITH cte AS 
	(SELECT *, id - DENSE_RANK() OVER(PARTITION BY num ORDER BY id) AS diff FROM threevals),
	cte2 AS (SELECT diff, count(*) cnt FROM cte GROUP BY diff HAVING count(*) >= 3)
-- SELECT * FROM cte, cte2 WHERE cte.diff = cte2.diff ;
SELECT GROUP_CONCAT(id) AS IDs, num AS consecutive_num FROM (SELECT cte.id, cte.num FROM cte, cte2 WHERE cte.diff = cte2.diff) t GROUP BY num;
-- To get 'id' and 'num' only cols, replace the above uncommented SELECT stmt with:  SELECT cte.id, cte.num FROM cte, cte2 WHERE cte.diff = cte2.diff ;
-- For even better result, replace above SELECT with : SELECT GROUP_CONCAT(id) AS IDs, num AS consec_num FROM (SELECT cte.id, cte.num FROM cte, cte2 WHERE cte.diff = cte2.diff) t GROUP BY num;

-- ----------------------tbl : dual_lang -- find company IDs having at least 2 users speaking both English & German ------------------------
-- SELECT * FROM dual_lang;
-- SELECT compid, userid, GROUP_CONCAT(lang SEPARATOR ' ') AS lang_list FROM dual_lang GROUP BY 1, 2;   -- line used ahead as cte
WITH cte AS (SELECT compid, userid, GROUP_CONCAT(lang SEPARATOR ' ') AS lang_list FROM dual_lang GROUP BY 1, 2)
SELECT compid, userid, lang_list FROM cte WHERE lang_list IN ('German English', 'English German');
-- ----------- another solution -----------
SELECT compid, userid, COUNT(*) FROM dual_lang WHERE lang <> 'Spanish'
GROUP BY compid, userid HAVING count(*) = 2;

-- -----------------------tbl: test_status -- find date range for particular status----------------------------------
-- SELECT * FROM test_status;
-- SELECT *, ROW_NUMBER() OVER(ORDER BY date_value) AS grp FROM test_status;
-- SELECT *, ROW_NUMBER() OVER(PARTITION BY state ORDER BY date_value) AS grp1 FROM test_status;
WITH cte AS
(
	SELECT *, grp - grp1 AS grp_final FROM
     (SELECT *
		, ROW_NUMBER() OVER(ORDER BY date_value) AS grp
        , ROW_NUMBER() OVER(PARTITION BY state ORDER BY date_value) AS grp1
    FROM test_status) tmp
)
-- SELECT * FROM cte;
SELECT MIN(date_value) AS start_date, MAX(date_value) AS end_date, state, grp_final
FROM cte GROUP BY state, grp_final ORDER BY MIN(date_value);

-- -----------------------tbl: distance -- remove duplicate distance records ----------------------------------------
-- SELECT * FROM distances;
WITH CTE AS
(
	SELECT place1, place2, distance,
    ROW_NUMBER() OVER(PARTITION BY 
    CASE WHEN place1 < place2 THEN place1 ELSE place2 END,
    CASE WHEN place1 < place2 THEN place2 ELSE place1 END ORDER BY distance) AS rownum
    FROM distances ORDER BY 4
) SELECT * FROM CTE WHERE rownum <> 2;


-- -----------------------tbl: family -- find which member belongs to which family ----------------------------------
-- SELECT * FROM family;
-- desired output:                   familyid     members
-- xx									1          A,Z,T
-- xx									2          G,V,B,N

WITH RECURSIVE famcte AS
(
	SELECT * FROM family WHERE parent IS NULL
    UNION ALL
    SELECT B.person, B.parent, A.familyid FROM famcte A JOIN family B ON A.person = B.parent
) 
-- SELECT * FROM famcte;
SELECT familyid, GROUP_CONCAT(person SEPARATOR ', ') AS memberList FROM famcte GROUP BY familyid;

-- -----------------------tbl: Products -- Re-order the IDs (Deloitte) ----------------------------------
SELECT * FROM products;  /* ID col in o/p (top to bottom, separated by 'category')  :  1 2 3 9  |  4 5 6 7 8 */
/* ID col in desired o/p (top to bottom, separated by 'category'):  9 3 2 1  |  8 7 6 5 4 */   -- Bascially, order in each partition is reversed

WITH CTE AS (
SELECT *
	, ROW_NUMBER() OVER(PARTITION BY category ORDER BY id) AS rnk
    , ROW_NUMBER() OVER(PARTITION BY category ORDER BY id DESC) AS rnkdesc
FROM products)
-- ---------- Intermediate output for checking query processing
SELECT *
FROM CTE c1 INNER JOIN CTE c2 ON c1.category = c2.category AND c1.rnk = c2.rnkdesc;
-- ---------- Final desired output (just selecting desired cols from above intermediate query's o/p)
-- SELECT c1.id AS c1id, c2.item as c2item, c1.category as c1cat, c2.category as c2cat, c1.rnk, c2.rnkdesc 
-- FROM CTE c1 INNER JOIN CTE c2 
-- ON c1.category = c2.category AND c1.rnk = c2.rnkdesc;

-- -----------------------tbl: emp_info --  emp having same salary as another emp in same dept ---------------------------------- 
select * from emp_info;
-- ---------- Query checking intermediate output -------
-- SELECT * 
-- FROM emp_info e1 INNER JOIN emp_info e2 
-- ON e1.dept = e2.dept AND e1.salary = e2.salary AND e1.name <> e2.name;
-- --------- Final output (just selecting cols from above query) ----
SELECT e1.*
FROM emp_info e1 INNER JOIN emp_info e2 
ON e1.dept = e2.dept AND e1.salary = e2.salary AND e1.id <> e2.id;

-- As an add, find median salary WITHOUT using a median function (though MySQL doesn't have such a function)
WITH MedianSalCTE AS 
(SELECT salary 
	, ROW_NUMBER() OVER (ORDER BY SALARY) AS row_num
	, COUNT(*) OVER() AS total_count
FROM emp_info)
SELECT AVG(SALARY) AS median_salary
FROM MedianSalCTE
WHERE row_num IN (FLOOR((total_count + 1) / 2), CEIL((total_count + 1) / 2));

-- ANOTHER ADD: finding highest salary without using ANY function
SET @highest = 0;
WITH cte AS 
(SELECT *, @highest := IF(salary >= @highest, salary, @highest) AS highest_salary FROM emp_info)
-- SELECT DISTINCT @highest FROM cte;  -- this line will also return the highest salary
SELECT SUBSTRING_INDEX(GROUP_CONCAT(highest_salary SEPARATOR ', '), ',', -1) AS highest_sal FROM cte;

-- ----------------------- tbl: puzzle --  evaluate expr in col 'rule' in tbl ---------------------------------- 

select * from puzzle; -- 'rule' col is of string (VARCHAR) type, not numeric type

-- CTE to split expression like '1+2' as 1, +, 2 in 3 separate columns
WITH CTE AS
(SELECT *
    , REGEXP_SUBSTR(rule, '^[0-9]+') AS id1        -- extract one or more digits from the start into col 'id1'
    , REGEXP_SUBSTR(rule, '[0-9]+$') AS id2        -- extract one or more digits from the end into col 'id2'
    , REGEXP_SUBSTR(rule, '[+\\-*/]') AS operator  -- \\ is used to escape '-' else '-' is taken as separator in pattern
FROM puzzle
)
SELECT *
	, CASE WHEN operator = '+' THEN (SELECT val from puzzle where id1 = id) + ((SELECT val from puzzle where id2 = id)) 
		   WHEN operator = '-' THEN (SELECT val from puzzle where id1 = id) - ((SELECT val from puzzle where id2 = id))
           WHEN operator = '/' THEN (SELECT val from puzzle where id1 = id) / ((SELECT val from puzzle where id2 = id)) 
           WHEN operator = '*' THEN (SELECT val from puzzle where id1 = id) * ((SELECT val from puzzle where id2 = id)) 
	  END AS ans 
FROM cte;

-- ----------------------- tbl: bit_status --  count the 1s in tbl ---------------------------------- 
-- YouTube: https://www.youtube.com/watch?v=jjn3H4iS4kc
-- SELECT * FROM bit_state;

-- --------------- First Approach (keeping it here because of logic for partitioning the 'state' column in cte_2)
-- SET @var = 0;
-- WITH 
-- cte_1 AS (SELECT state, CASE WHEN state = 1 THEN @var := @var + 1 ELSE @var := 0 END AS one_counter, ROW_NUMBER() OVER() AS rownum FROM bit_state),
-- cte_2 AS (SELECT *, rownum - one_counter AS parting FROM cte_1),
-- cte_final AS (SELECT *, LEAD(state, 1, CASE WHEN state = 1 THEN 0 ELSE 1 END) OVER() AS lead_status FROM cte_2)
-- -- SELECT * FROM cte_final;
-- SELECT one_counter FROM cte_final WHERE lead_status = 0 AND one_counter <> 0;

-- -- --------------- Second Approach (one less CTE) -----------------------
SET @var = 0;
WITH 
cte_1 AS (SELECT state, CASE WHEN state = 1 THEN @var := @var + 1 ELSE @var := 0 END AS one_counter FROM bit_state),
cte_final AS (SELECT *, LEAD(state, 1, CASE WHEN state = 1 THEN 0 ELSE 1 END) OVER() AS lead_status FROM cte_1)
 -- SELECT * FROM cte_final;
SELECT one_counter FROM cte_final WHERE lead_status = 0 AND one_counter <> 0;
-- ---------------- Shorter approach (using IF) ---------------------
SET @var = 0;
WITH cte1 AS (SELECT *, @var := IF(state = 1, @var + 1, 0) AS one_counter FROM bit_state),
cte2 AS (SELECT *, LEAD(state, 1, CASE WHEN state = 1 THEN 0 ELSE 1 END) OVER() AS lead_status FROM cte1)
SELECT one_counter FROM cte2 WHERE one_counter <> 0 AND lead_status = 0;

-- ----------------------- tbl: employees --  find juniors under each manager ---------------------------------- 

WITH CTE AS (
SELECT A.empid, A.fullname, B.fullname AS mgrname 
FROM employees A LEFT JOIN employees B ON A.mgrid = B.empid)  -- this SELECT finds employees' managers
SELECT                                                        -- this SELECT finds the final ans
    mgrname
    , GROUP_CONCAT(fullname SEPARATOR ', ') AS juniors
FROM cte WHERE mgrname IS NOT NULL GROUP BY mgrname ;


-- ----------------------- tbl: office --  find emp_id who are present inside office ---------------------------------- 

-- CREATE TABLE office (emp_id INT, presence_status VARCHAR(10), time_id DATETIME);
-- INSERT INTO office VALUES ('1', 'ENTRY', '2023-12-22 09:00:00'),('1', 'EXIT', '2023-12-22 09:15:00'), ('2', 'ENTRY', '2023-12-22 09:00:00'), ('2', 'EXIT', '2023-12-22 09:15:00'), ('2', 'ENTRY', '2023-12-22 09:30:00'),('3', 'EXIT', '2023-12-22 09:00:00'),('3', 'ENTRY', '2023-12-22 09:15:00'), ('3', 'EXIT', '2023-12-22 09:30:00'), ('3', 'ENTRY', '2023-12-22 09:45:00'), ('4', 'ENTRY', '2023-12-22 09:45:00'), ('5', 'ENTRY', '2023-12-22 09:40:00');

SELECT * FROM office;

WITH CTE_emp_presence AS
(SELECT *, MAX(time_id) OVER(PARTITION BY emp_id) AS emp_latest_time
FROM office
)
SELECT emp_id
FROM CTE_emp_presence 
WHERE time_id = emp_latest_time AND emp_status = 'ENTRY';


-- ----------------------- tbl: consecutive_raise --  find emp_id having salary increasing over 3 years ---------------------------------- 

-- CREATE TABLE consecutive_raise (emp_id INT, emp_name VARCHAR(100), emp_salary INT, appraisal_year INT);
-- INSERT INTO consecutive_raise(emp_id, emp_name, emp_salary, appraisal_year) VALUES (1, 'Alice', 50000, 2021),(1, 'Alice', 55000, 2022),(1, 'Alice', 60000, 2023),(2, 'Bob', 60000, 2021),(2, 'Bob', 58000, 2022),(2, 'Bob', 62000, 2023), (3, 'Charlie', 70000, 2020), (3, 'Charlie', 72000, 2021), (3, 'Charlie', 71000, 2022), (4, 'David', 40000, 2020), (4, 'David', 45000, 2021), (4, 'David', 50000, 2022), (5, 'Eve', 30000, 2021), (5, 'Eve', 35000, 2022);

SELECT * FROM consecutive_raise;

WITH CTE_years_sorted AS 
(SELECT *, ROW_NUMBER() OVER(PARTITION BY emp_id ORDER BY appraisal_year) AS rw_num FROM consecutive_raise),
CTE_extract_empName AS
(SELECT 
	CASE WHEN emp_salary < LEAD(emp_salary) OVER(PARTITION BY emp_id) 
		   AND LEAD(emp_salary, 1) OVER(PARTITION BY emp_id) < LEAD(emp_salary, 2) OVER(PARTITION BY emp_id)
		THEN emp_name
	END AS incr_sal_emp_name
	FROM CTE_years_sorted 
)
SELECT incr_sal_emp_name FROM CTE_extract_empName WHERE incr_sal_emp_name IS NOT NULL;


-- ----------------------- tbl: skills_table --  find emp_id having ONLY 'SQL' as skill (only SQL, no other skill) ---------------------------------- 

-- SELECT * FROM skills_table; 

SELECT emp_id
FROM 
(SELECT 
    emp_id
    , GROUP_CONCAT(skills SEPARATOR ', ') AS emp_skills
 FROM skills_table
 GROUP BY emp_id
 ) temp_tbl
WHERE emp_skills = "SQL";

-- another solution
SELECT emp_id
FROM skills_table
GROUP BY emp_id
HAVING COUNT(DISTINCT skills) = 1 AND MAX(skills) = 'SQL';

-- SELECT LENGTH("APPLE") - LENGTH(REGEXP_REPLACE("APPLE", '[aeiouAEIOU]', ''));  -- Counting the no. of vowels in a word (2)
-- SELECT LENGTH("APPLE") - LENGTH(REGEXP_REPLACE("APPLE", '[^aeiouAEIOU]', ''));  -- Counting the consonants in a word  (3)








