Declare @dateReducer int =1;
SELECT DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-  @dateReducer, -1) as something;

Select DATEDIFF(MONTH, -1, GETDATE()) as what;

SELECT DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-  @dateReducer, -1) as something;
