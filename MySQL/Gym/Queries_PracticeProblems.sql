-- USE sql_forda;

-- ---------------------- tbl: ffill -- Forward filling -------------------
SELECT * FROM ffill;
SET @var = NULL;
SELECT
    id
    , dept
    , @var := COALESCE(dept, @var) AS ffill_value
FROM ffill;

-- another solution ( IMPORTANT )
WITH cte AS
( SELECT *, COUNT(dept) OVER(ORDER BY id) AS cnt FROM ffill -- COUNT here works as ranking fn on 'dept' col when ORDER BY is not as per 'dept'
) SELECT *, FIRST_VALUE(dept) OVER(PARTITION BY cnt ORDER by id) AS ffill_value FROM cte;

-- ------------------ Following identical queries are just for testing ------------
-- SELECT *
--     , COUNT(dept) OVER(ORDER BY id)
--     , COUNT(dept) OVER(ORDER BY dept)  -- final ordering of o/p as per this line 
-- FROM ffill;

-- SELECT *
--     , COUNT(dept) OVER(ORDER BY dept)
--     , COUNT(dept) OVER(ORDER BY id)    -- final ordering of o/p as per this line
-- FROM ffill;

-- yet another solution ( IMPORTANT )
WITH cte AS 
(SELECT *, SUM(CASE WHEN dept IS NULL THEN 0 ELSE id END) OVER(ORDER BY id) AS flag FROM ffill)
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
(SELECT *
    , id - DENSE_RANK() OVER(PARTITION BY num ORDER BY id) AS diff
FROM threevals
),
cte2 AS
(SELECT diff
	, count(*) cnt
FROM cte
GROUP BY diff
HAVING count(*) >= 3 )
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

-- ----------------------- tbl: puzzle --  evaluate expr in col 'rule' in tbl ---------------------------------- 

select * from puzzle; -- 'rule' col is of string (VARCHAR) type, not numeric type
-- Splitting an expression like '1+2' in 3 tokens (1, +, 2) in 3 separate columns
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



-- SELECT LENGTH("APPLE") - LENGTH(REGEXP_REPLACE("APPLE", '[aeiouAEIOU]', ''));  -- Counting the no. of vowels in a word

