SHOW FIELDS FROM sql_forda.c3_retail_sales;

SELECT * FROM c3_retail_sales;

SELECT YEAR(sales_month) AS sales_year, SUM(sales) AS total_sales
FROM c3_retail_sales WHERE kind_of_business = 'Retail and food services sales, total'
GROUP BY  1;

SELECT YEAR(sales_month) AS sales_year, kind_of_business, SUM(sales) AS total_sales
FROM c3_retail_sales WHERE kind_of_business in ('Book stores' ,'Sporting goods stores','Hobby, toy, and game stores')
GROUP BY 1, 2 ;

SELECT YEAR(sales_month) AS 'year', kind_of_business, SUM(sales) AS total_sales
FROM c3_retail_sales WHERE kind_of_business in ('Men''s clothing stores', 'Women''s clothing stores') 
GROUP BY 1, 2;

SELECT YEAR(sales_month) AS sales_year,
SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales,
SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
FROM c3_retail_sales WHERE kind_of_business in ('Men''s clothing stores', 'Women''s clothing stores') GROUP BY 1;

SELECT sales_year, womens_sales - mens_sales AS womens_minus_mens, mens_sales - womens_sales AS mens_minus_womens
FROM
(
	SELECT YEAR(sales_month) AS sales_year
	, SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales
    , SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
FROM c3_retail_sales WHERE kind_of_business IN ('Men''s clothing stores' , 'Women''s clothing stores') AND sales_month <= '2019-12-01'
GROUP BY 1
) tmp;

SELECT sales_year, womens_sales/mens_sales AS womens_times_of_mens
FROM
(
	SELECT YEAR(sales_month) AS sales_year
	, SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales
    , SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
FROM c3_retail_sales
WHERE kind_of_business IN ('Men''s clothing stores' , 'Women''s clothing stores') AND sales_month <= '2019-12-01'
GROUP BY 1
) tmp;

SELECT sales_year, (womens_sales /mens_sales -1) * 100 AS womens_pct_of_mens
FROM
(
	SELECT YEAR(sales_month) AS sales_year
	, SUM(CASE WHEN kind_of_business = 'Women''s clothing stores' THEN sales END) AS womens_sales
    , SUM(CASE WHEN kind_of_business = 'Men''s clothing stores' THEN sales END) AS mens_sales
FROM c3_retail_sales
WHERE kind_of_business IN ('Men''s clothing stores' , 'Women''s clothing stores') AND sales_month <= '2019-12-01'
GROUP BY 1
) tmp;


SELECT sales_month, kind_of_business, sales * 100 / total_sales AS pct_total_sales
FROM
(
	SELECT a.sales_month, a.kind_of_business, a.sales, SUM(b.sales) AS total_sales 
    FROM c3_retail_sales a
    JOIN c3_retail_sales b ON a.sales_month = b.sales_month AND b.kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores')
    WHERE a.kind_of_business in ('Men''s clothing stores' , 'Women''s clothing stores')
	GROUP BY 1,2,3
) tmp;

SELECT sales_month, kind_of_business, sales
, SUM(sales) OVER(PARTITION BY sales_month) AS total_sales
, sales * 100 / sum(sales) OVER (PARTITION BY sales_month) AS pct_total
FROM c3_retail_sales WHERE kind_of_business IN ('Men''s clothing stores', 'Women''s clothing stores');

SELECT sales_month, kind_of_business, sales, 
SUM(sales) OVER (PARTITION BY YEAR(sales_month), kind_of_business) AS yearly_sales,
sales * 100 / SUM(sales) OVER (PARTITION BY YEAR(sales_month), kind_of_business) AS pct_yearly
FROM c3_retail_sales
WHERE kind_of_business in ('Men''s clothing stores', 'Women''s clothing stores');

SELECT sales_year, sales, FIRST_VALUE(sales) OVER(ORDER BY sales_year) AS index_year
FROM
(
	SELECT YEAR(sales_month) AS sales_year, SUM(sales) AS sales
    FROM c3_retail_sales WHERE kind_of_business = 'Women''s clothing stores' GROUP BY 1
) tmp;

SELECT sales_year, sales, (sales / FIRST_VALUE(sales) OVER(ORDER BY sales_year) - 1) * 100 AS pct_from_index
FROM
(
	SELECT YEAR(sales_month) AS sales_year, SUM(sales) AS sales
    FROM c3_retail_sales WHERE kind_of_business = 'Women''s clothing stores' GROUP BY 1
) tmp;

SELECT sales_year, kind_of_business, sales, (sales / FIRST_VALUE(sales) OVER(PARTITION BY kind_of_business ORDER BY sales_year)- 1) * 100 as pct_from_index
FROM
(
	SELECT YEAR(sales_month) AS sales_year, kind_of_business, SUM(sales) AS sales
	FROM c3_retail_sales WHERE kind_of_business in ('Men''s clothing stores', 'Women''s clothing stores') AND sales_month <= '2019-12-31'
	GROUP BY 1,2
) tmp;

SELECT a.sales_month, a.sales, b.sales_month AS rolling_sales_month, b.sales AS rolling_sales
FROM c3_retail_sales a JOIN c3_retail_sales b ON a.kind_of_business = b.kind_of_business
AND b.sales_month BETWEEN a.sales_month - INTERVAL 11 MONTH AND a.sales_month
AND b.kind_of_business = 'Women''s clothing stores'
WHERE a.kind_of_business = 'Women''s clothing stores' AND a.sales_month = '2019-12-01';

SELECT a.sales_month, a.sales, AVG(b.sales) AS moving_avg, COUNT(b.sales) AS records_count
FROM c3_retail_sales a JOIN c3_retail_sales b ON a.kind_of_business = b.kind_of_business
AND b.sales_month BETWEEN a.sales_month - INTERVAL 11 MONTH AND a.sales_month
AND b.kind_of_business = 'Women''s clothing stores'
WHERE a.kind_of_business = 'Women''s clothing stores' AND a.sales_month >= '1993-01-01' GROUP BY 1,2;

SELECT sales_month, AVG(sales) OVER (ORDER BY sales_month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS moving_avg, 
COUNT(sales) OVER (ORDER BY sales_month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS records_count
FROM c3_retail_sales WHERE kind_of_business = 'Women''s clothing stores';

SELECT sales_month, sales, SUM(sales) OVER(PARTITION BY YEAR(sales_month) ORDER BY sales_month) AS sales_ytd
FROM c3_retail_sales WHERE kind_of_business = 'Women''s clothing stores';

SELECT a.sales_month, a.sales, SUM(b.sales) AS sales_ytd
FROM c3_retail_sales a JOIN c3_retail_sales b ON YEAR(a.sales_month) = YEAR(b.sales_month)
AND b.sales_month <= a.sales_month
AND b.kind_of_business = 'Women''s clothing stores' WHERE a.kind_of_business = 'Women''s clothing stores' GROUP BY 1, 2;

SELECT kind_of_business, sales_month, sales, LAG(sales_month) OVER (PARTITION BY kind_of_business ORDER BY sales_month) AS prev_month,
LAG(sales) OVER (PARTITION BY kind_of_business ORDER BY sales_month) AS prev_month_sales
FROM c3_retail_sales WHERE kind_of_business = 'Book stores';

SELECT kind_of_business, sales_month, sales, (sales / LAG(sales) OVER (PARTITION BY kind_of_business ORDER BY sales_month)- 1) * 100 AS pct_growth_from_previous
FROM c3_retail_sales WHERE kind_of_business = 'Book stores';

SELECT sales_year, yearly_sales, LAG(yearly_sales) OVER (ORDER BY sales_year) AS prev_year_sales, 
(yearly_sales / LAG(yearly_sales) OVER (ORDER BY sales_year)-1) * 100 AS pct_growth_from_previous
FROM
(
	SELECT YEAR(sales_month) as sales_year, SUM(sales) AS yearly_sales
	FROM c3_retail_sales WHERE kind_of_business = 'Book stores' GROUP BY 1
) tmp;

SELECT sales_month, MONTH(sales_month)
FROM c3_retail_sales WHERE kind_of_business = 'Book stores';

SELECT sales_month, sales, 
LAG(sales_month) OVER (PARTITION BY MONTH(sales_month) ORDER BY sales_month) AS prev_year_month,  -- sales_month is in YYYY-MM-DD where DD is 01 for all.
LAG(sales) OVER (PARTITION BY MONTH(sales_month) ORDER BY sales_month) AS prev_year_sales
FROM c3_retail_sales WHERE kind_of_business = 'Book stores';

SELECT MONTH(sales_month) AS month_number,  MONTHNAME(sales_month) AS month_name,
MAX(CASE WHEN YEAR(sales_month) = 1992 THEN sales END) AS sales_1992,
MAX(CASE WHEN YEAR(sales_month) = 1993 THEN sales END) AS sales_1993,
MAX(CASE WHEN YEAR(sales_month) = 1994 THEN sales END) AS sales_1994
FROM c3_retail_sales WHERE kind_of_business = 'Book stores' AND sales_month BETWEEN '1992-01-01' AND '1994-12-01' GROUP BY 1, 2;

SELECT sales_month, sales,
sales / ((prev_sales_1 + prev_sales_2 + prev_sales_3) / 3) * 100 AS pct_of_3_prev
FROM
(
	SELECT sales_month, sales, 
    LAG(sales, 1) OVER (PARTITION BY MONTH(sales_month) ORDER BY sales_month) AS prev_sales_1,
    LAG(sales, 2) OVER (PARTITION BY MONTH(sales_month) ORDER BY sales_month) AS prev_sales_2,
	LAG(sales, 3) OVER (PARTITION BY MONTH(sales_month) ORDER BY sales_month) AS prev_sales_3
FROM c3_retail_sales WHERE kind_of_business = 'Book stores'
) tmp;

-- Above query re-written as follows

SELECT sales_month, sales,
sales / AVG(sales) OVER (PARTITION BY MONTH(sales_month) ORDER BY sales_month ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS pct_of_prev_3
FROM c3_retail_sales WHERE kind_of_business = 'Book stores';





