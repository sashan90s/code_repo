--conditionally running select statements
--saving values into variables


DECLARE @dec INT;
DECLARE @counting INT = 1;


-- Count the number of rows in the table and assign to @dec
SELECT @dec = COUNT(*)
FROM [DATAMART_SOCIAL_CARE].[ade].[vw_all_visits_FY_start_date_24_25];

-- Check if the count is less than 1
IF @dec > 1
BEGIN
    -- Select the top 6 rows from the table
    SELECT TOP 6 *
    FROM [DATAMART_SOCIAL_CARE].[ade].[vw_all_visits_FY_start_date_24_25];
END

ELSE
Begin
	SELECT count (*)
	FROM [DATAMART_SOCIAL_CARE].[ade].[vw_all_visits_FY_start_date_24_25]
End
