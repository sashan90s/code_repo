-- Select the relevant columns after pivoting
SELECT  
    [Name],             -- The original non-pivoted column for employee names
    [Period],           -- The original non-pivoted column for time periods
    [Saturday],         -- The first pivoted column for Saturday
    [Sunday],           -- The second pivoted column for Sunday
    [Monday],           -- Pivoted columns for Monday through Friday
    [Tuesday],
    [Wednesday],
    [Thursday],
    [Friday]            -- The last pivoted column for Friday
    
FROM 
(
    -- Subquery: Select relevant columns from the original table
    SELECT 
        [Name],
        [Period],
        [Workday],
        [Hours]
    FROM [z_BI_SYS_TEAM_TRAIN_01].[DataSources02].[tbl_timesheet_raw_data]
) as pvtme
PIVOT
(
    MAX([Hours]) FOR [Workday] IN ([Saturday],[Sunday],[Monday],[Tuesday],[Wednesday],[Thursday],[Friday])
) as Pvt;


/* The PIVOT operation is used to transform the long-format data into a wide format. 
It aggregates the [Hours] column for each [Workday] value, 
creating separate columns for each day of the week ([Saturday], [Sunday], ..., [Friday]). */ 
