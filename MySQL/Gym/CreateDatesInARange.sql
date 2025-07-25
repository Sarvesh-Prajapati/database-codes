-- WITH RECURSIVE Date_Ranges AS
-- (
--     SELECT '2018-11-30' AS Date
--    UNION ALL
--    SELECT Date + INTERVAL 1 DAY FROM Date_Ranges WHERE Date < '2018-12-31'
-- )
-- SELECT * FROM Date_Ranges;

WITH RECURSIVE Date_Ranges AS 
(
   SELECT CURRENT_DATE() AS myDate
   UNION ALL
   SELECT myDate + INTERVAL 1 DAY FROM Date_Ranges WHERE myDate < '2024-12-31'
)
SELECT * FROM Date_Ranges;
