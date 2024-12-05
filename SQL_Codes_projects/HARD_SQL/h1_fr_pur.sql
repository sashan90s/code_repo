with main as(
Select
datepart(WEEK, date) as weeknum
, avg(amount_spent) as avg_amount
from user_purchases
where datename(dw, date) = 'Friday' and datepart(qq, date) = 1
group by datepart(WEEK, date)
),

WEEKTAB AS (
SELECT N AS WEEK_NUM -- weeknumber column selecting from virtual table
FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13)
) AS  WEEKTAB (N) -- creating virtual table weektab with column name N within the FROM clause
) 


select weektab.week_num as weeknumber
, isnull(main.avg_amount, 0) as avg_amount
from weektab
left join main on weektab.week_num = main.weeknum ;