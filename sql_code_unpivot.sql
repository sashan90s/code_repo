-- Select the relevant columns after unpivoting
SELECT 
    [Name],             -- The original non-unpivoted column for employee names
    [Period],           -- The original non-unpivoted column for time periods
    [Workday],          -- The newly created column for days of the week
    [Hours]             -- The column for hours worked on each day

FROM 
(
    -- Subquery: Select relevant columns from the original table
    SELECT 
        [Name],
        [Period],
        [Saturday],
        [Sunday],
        [Monday],
        [Tuesday],
        [Wednesday],
        [Thursday],
        [Friday]
    FROM [z_BI_SYS_TEAM_TRAIN_01].[DataSources02].[tbl_timesheet]
) p  
UNPIVOT  
(
    [Hours] FOR [Workday] IN ([Saturday],[Sunday],[Monday],[Tuesday],[Wednesday],[Thursday],[Friday])
) AS unpvt;  -- Alias for the unpivoted output
