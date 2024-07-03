INSERT INTO dbo.BatchRun(
    RunID,
    BatchID,
    SystemCode,
    RunNumber,
    SnapshotDate,
    Status,
    Restart,
    CurrentIND,
    UpdateAt 
)VALUES(
    CONCAT(REPLACE(CAST(CAST(GETDATE()-3 AS Date) AS varchar),'-',''),'01','01'),
    1,
    'OWS',
    1,
    CAST(GETDATE()-3 AS Date),
    'NOT-STARTED',
    'False',
    1,
    GETDATE()
)
GO

INSERT INTO dbo.BatchRun(
    RunID,
    BatchID,
    SystemCode,
    RunNumber,
    SnapshotDate,    
    Status,
    Restart,
    CurrentIND,
    UpdateAt 
)VALUES(
    CONCAT(REPLACE(CAST(CAST(GETDATE()-3 AS Date) AS varchar),'-',''),'02','01'),
    2,
    'OWS',
    1,
    CAST(GETDATE()-3 AS Date),
    'NOT-STARTED',
    'False',
    1,
    GETDATE()
)
GO
