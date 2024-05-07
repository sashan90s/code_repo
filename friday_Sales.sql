/* In this solution walkthrough, we will explore the SQL query used for 
  analyzing user purchasing behavior on Fridays during the first quarter of the year. 
  We'll discuss how to calculate the average amount spent and how to ensure that all Fridays, 
  whether they have data or not, are represented in the final result.*/



With main as (Select Datepart(WEEK, date) as week_num,
datename(WEEKDAY, date) as day,
date,
avg(amount_spent) as mean_amount
from user_purchases
where Datepart(WEEK, date) < 14
and datename(WEEKDAY, date) = 'Friday'
group by Datepart(WEEK, date), datename(WEEKDAY, date), date),


week_tab as ( 
select n as weeknum from (VALUES(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9),
(10),
(11),
(12),
(13)) as week_tab(n))

select week_tab.weeknum, isnull(main.mean_amount, 0) as mean_amnt
from week_tab
left join main
ON week_tab.weeknum = main.week_num;



-- second way

WITH friday_purchases AS (
    SELECT DATEPART(WEEK, date) AS week_number,
    AVG(amount_spent) AS mean_amount
    FROM user_purchases
    WHERE DATENAME(WEEKDAY, date) = 'Friday' AND DATEPART(QUARTER, date) = 1
    GROUP BY DATEPART(WEEK, date)
),
    all_weeks AS (
    SELECT n AS week_number
    FROM (VALUES (1),
    (2),
    (3),
    (4),
    (5),
    (6),
    (7),
    (8),
    (9),
    (10),
    (11),
    (12),
    (13)) AS all_weeks(n)
)
SELECT all_weeks.week_number,
    ISNULL(friday_purchases.mean_amount, 0) AS mean_amount
FROM all_weeks
LEFT JOIN friday_purchases ON all_weeks.week_number = friday_purchases.week_number;
