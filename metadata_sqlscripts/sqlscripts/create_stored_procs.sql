CREATE PROC dbo.InsertPipelineLog(
    @RunID varchar(20),
    @PipelineID varchar(100),
    @PipelineName varchar(100),
    @SourceToTargetID int,
    @Status varchar(100),
    @EndTime datetime,
    @StartTime datetime,
    @SnapshotDate date,
    @UpdateAt date
)
AS
    INSERT INTO dbo.PipelineLog(
        RunID,
        PipelineID,
        PipelineName,        
        SourceToTargetID,
        Status,
        StartTime,
        EndTime,
        SnapshotDate,
        UpdatedAt
    )
    VALUES (
            @RunID,
            @PipelineID,
            @PipelineName,            
            @SourceToTargetID,
            @Status,
            @StartTime,
            @EndTime,
            @SnapshotDate,
            @UpdateAt)
GO

CREATE PROC dbo.GetSourceToTargetInfo(
    @SourceSystemCode varchar(5),
    @Stage varchar(50),
    @DatasetName varchar(50)
 )
AS
  SELECT 
         [SourceToTargetID]   
        ,[SourceSystemCode]
        ,[SourceSystem]
        ,[SourceDatasetName]
        ,[SourceDataObjectName]
        ,[SourceContainer]
        ,[SourceRelativePathSchema]
        ,[SourceTechnicalName]
        ,[TargetSystemCode]
        ,[TargetSystem]
        ,[TargetDatasetName]
        ,[TargetDataObjectName]
        ,[TargetContainer]
        ,[TargetRelativePathSchema]
        ,[TargetTechnicalName]
        ,[Stage]
        ,[Status]
    FROM [dbo].[SourceToTargetView]
   WHERE SourceSystemCode = @SourceSystemCode    
    AND  Stage = @Stage
    AND  Status = 'Active'
    ORDER BY SourceDatasetName;

RETURN
GO

CREATE PROC dbo.GetEmailAddresses(
    @SystemCode varchar(5),
    @DatasetName varchar(50)
)
AS 
 SELECT 
       [SystemCode]
      ,[DatasetName]
      ,[SystemInfoID]
      ,[FirstName]
      ,[LastName]
      ,[EmailAddress]
  FROM [dbo].[EmailRecipients]
 WHERE SystemCode = @SystemCode
   AND DatasetName = @DatasetName
GO

CREATE PROC GetRunID(
    @SnapshotDate date,
    @BatchID INT,
    @RunNumber INT,
    @RunID varchar(50) OUTPUT
)
AS
DECLARE @BatchString varchar(2)
DECLARE @RunNumberString varchar(2)

IF @BatchID < 10
    SELECT @BatchString = LEFT('0'+CAST(@BatchID AS VARCHAR(2)),2);
ELSE
    SELECT @BatchString = CAST(@BatchID AS VARCHAR(2));

IF @RunNumber < 10
    SELECT @RunNumberString = LEFT('0'+CAST(@RunNumber AS VARCHAR(2)),2);
ELSE
    SELECT @RunNumberString = CAST(@RunNumber AS VARCHAR(2));

SELECT @RunID = CONCAT(REPLACE(CAST(@SnapshotDate AS varchar(11)),'-',''), @BatchString, @RunNumberString)
GO

CREATE PROC GetBatch(
    @PSystemCode varchar(5),
    @PFrequency varchar(10)
)
AS
    DECLARE @RunID varchar(50);
    DECLARE @RC int;
    DECLARE @SnapshotDate date;
    DECLARE @BatchID int;
    DECLARE @RunNumber int;
    DECLARE @SystemCode varchar(5);
    DECLARE @StartTime datetime;
    DECLARE @Restart varchar(10);
    DECLARE @Status varchar(20);
    DECLARE @CurrentIND int; 
    DECLARE @UpdateAt datetime;
    DECLARE @CurrentTimeZoneTimeStamp datetime;
    DECLARE @TimeZone varchar(100); 

    SET @TimeZone = (SELECT distinct TimeZone from dbo.Batch WHERE SystemCode = @PSystemCode AND Frequency = @PFrequency)
    SET @CurrentTimeZoneTimeStamp = CAST((GETDATE() AT TIME ZONE 'UTC' AT TIME ZONE @TimeZone) as datetime)
            
    UPDATE dbo.BatchRun
       SET Status = 'IN-PROGRESS',
           StartTime = @CurrentTimeZoneTimeStamp, 
           UpdateAt = @CurrentTimeZoneTimeStamp
     WHERE SystemCode = @PSystemCode
       AND Status = 'NOT-STARTED'
       AND SnapshotDate <= CAST(@CurrentTimeZoneTimeStamp-1 AS Date)
       AND BatchID IN (SELECT BatchID
                         FROM Batch
                        WHERE Status = 'Active'
                          AND SystemCode = @PSystemCode
                          AND Frequency = @PFrequency);

    DECLARE batchrun_cursor CURSOR LOCAL
        FOR SELECT  BatchID,
                    SystemCode,
                    (RunNumber + 1) as RunNumber,
                    @CurrentTimeZoneTimeStamp as StartTime,
                    SnapshotDate,
                    'True' as Restart,
                    'IN-PROGRESS' as Status,
                     CurrentIND,
                     @CurrentTimeZoneTimeStamp as UpdateAt 
            FROM  dbo.BatchRun
            WHERE  SystemCode = @PSystemCode
            AND  SnapshotDate <= CAST(@CurrentTimeZoneTimeStamp-1 AS Date)
            AND CurrentIND = 1
            AND Status IN ('COMPLETED-WITH-ERRORS')
            AND BatchID IN (SELECT BatchID
                              FROM Batch
                             WHERE Status = 'Active'
                               AND SystemCode = @PSystemCode
                               AND Frequency = @PFrequency);  
    
    OPEN batchrun_cursor;
    FETCH NEXT FROM batchrun_cursor INTO @BatchID, @SystemCode, @RunNumber, @StartTime, @SnapshotDate, @Restart, @Status, @CurrentIND, @UpdateAt;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXECUTE @RC = [dbo].[GetRunID] 
                 @SnapshotDate
                ,@BatchID
                ,@RunNumber
                ,@RunID OUTPUT

        INSERT INTO dbo.BatchRun(
             RunID,
             BatchID,
             SystemCode,
             RunNumber,
             StartTime,
             SnapshotDate,
             Restart,
             Status,
             CurrentIND,
             UpdateAt
        )
        VALUES(
             @RunID,
             @BatchID,
             @SystemCode,
             @RunNumber,
             @StartTime,
             @SnapshotDate,
             @Restart,
             @Status,
             @CurrentIND,
             @UpdateAt
        );

        FETCH NEXT FROM batchrun_cursor INTO @BatchID, @SystemCode, @RunNumber, @StartTime, @SnapshotDate, @Restart, @Status, @CurrentIND,  @UpdateAt;
        
    END;

    CLOSE batchrun_cursor;

    UPDATE dbo.BatchRun
       SET CurrentIND = 0, 
           UpdateAt = @CurrentTimeZoneTimeStamp
     WHERE SystemCode = @PSystemCode
       AND Status = 'COMPLETED-WITH-ERRORS'
       AND CurrentIND = 1
       AND SnapshotDate <= CAST(@CurrentTimeZoneTimeStamp-1 AS Date)
       AND BatchID IN (SELECT BatchID
                              FROM Batch
                             WHERE Status = 'Active'
                               AND SystemCode = @PSystemCode
                               AND Frequency = @PFrequency); 

    WITH TMP_LATEST_BATCH
    AS
    (SELECT BatchID,
            max(SnapshotDate) as SnapshotDate
    FROM BatchRun
    GROUP BY 
        BatchID)
    SELECT  c.RunID
        ,c.RunNumber
        ,c.StartTime
        ,c.EndTime
        ,c.SnapshotDate
        ,c.Restart
        ,c.Status as RunStatus
        ,c.CurrentIND
        ,a.[ID] as BatchID
        ,a.[SystemInfoID]
        ,b.SystemCode
        ,b.SystemName
        ,b.DatasetName
        ,b.[Status] as SystemStatus
        ,a.[ScheduledStartTime] as BatchScheduledStartTime
        ,a.[Frequency] as BatchFrequency
        ,a.[Status] as BatchStatus      
    FROM [dbo].[Batch] a
    INNER JOIN dbo.SystemInfo b
    ON a.SystemInfoID = b.ID
    AND b.[Status] = 'Active'
    INNER JOIN dbo.BatchRun c
    ON a.ID = c.BatchID
    AND c.SnapshotDate <= CAST(@CurrentTimeZoneTimeStamp-1 AS Date)
    AND c.CurrentIND = 1
    AND c.Status = 'IN-PROGRESS'
    INNER JOIN TMP_LATEST_BATCH d
    ON c.SnapshotDate = d.SnapshotDate
    AND c.BatchID = d.BatchID
    WHERE a.[Status] = 'Active'
      AND a.SystemCode = @PSystemCode
      AND a.Frequency = @PFrequency;

    RETURN
GO

CREATE PROC SetBatchStatus(
    @PSystemCode varchar(5),
    @PFrequency varchar(10)
)
AS

    DECLARE @batchStatus varchar(25);
    DECLARE @RunID varchar(50);
    DECLARE @PipelineStatus varchar(25);
    DECLARE @RC int;
    DECLARE @SnapshotDate date;
    DECLARE @BatchID int;
    DECLARE @RunNumber int;
    DECLARE @SystemCode varchar(5);
    DECLARE @StartTime datetime;
    DECLARE @Restart varchar(10);
    DECLARE @Status varchar(20);
    DECLARE @CurrentIND int; 
    DECLARE @UpdateAt datetime;
    DECLARE @CurrentTimeZoneTimeStamp datetime;
    DECLARE @TimeZone varchar(100); 
    SELECT @batchStatus = 'UNDEFINED';

    SET @TimeZone = (SELECT distinct TimeZone from dbo.Batch WHERE SystemCode = @PSystemCode AND Frequency = @PFrequency)
    SET @CurrentTimeZoneTimeStamp = CAST((GETDATE() AT TIME ZONE 'UTC' AT TIME ZONE @TimeZone) as datetime)

    UPDATE dbo.BatchRun
       SET CurrentIND = -1,
           UpdateAt = @CurrentTimeZoneTimeStamp
     WHERE Status = 'COMPLETED-SUCCESSFULLY'
       AND CurrentIND = 0
       AND SnapshotDate < CAST(@CurrentTimeZoneTimeStamp-1 AS Date)
       AND BatchID in (SELECT BatchID
                      FROM Batch
                      WHERE SystemCode = @PSystemCode
                        AND Frequency = @PFrequency)

    --SET PREVIOUS RUN TO ARCHIVE  

    DECLARE batchrun_status_cursor CURSOR LOCAL
        FOR SELECT distinct 
                a.RunID,
                a.[Status] as PipelineStatus
              FROM 
                dbo.PipelineLog a
            INNER JOIN dbo.BatchRun b
            ON b.RunID = a.RunID
            WHERE a.[Status] in ('Failed')
            AND a.EndTime is not null
            AND b.[Status] = 'IN-PROGRESS';

    OPEN batchrun_status_cursor;
    FETCH NEXT FROM batchrun_status_cursor INTO @RunID, @PipelineStatus;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @PipelineStatus = 'Failed'
            SELECT @batchStatus = 'COMPLETED-WITH-ERRORS'
            UPDATE dbo.BatchRun
               SET [Status] = @batchStatus,
               UpdateAt = @CurrentTimeZoneTimeStamp,
               EndTime = @CurrentTimeZoneTimeStamp
             WHERE RunID = @RunID        
        FETCH NEXT FROM batchrun_status_cursor INTO @RunID, @PipelineStatus;
    END;

    CLOSE batchrun_status_cursor;

     UPDATE dbo.BatchRun
       SET [Status] = 'COMPLETED-SUCCESSFULLY',
       UpdateAt = @CurrentTimeZoneTimeStamp,
       EndTime = @CurrentTimeZoneTimeStamp,
       CurrentIND = 0
     WHERE RunID in (SELECT distinct 
                    a.RunID
                    FROM 
                        dbo.PipelineLog a
                    INNER JOIN dbo.BatchRun b
                    ON b.RunID = a.RunID
                    WHERE a.[Status] in ('Failed','Success')
                    AND a.EndTime is not null
                    AND b.[Status] = 'IN-PROGRESS')
       AND [Status] != 'COMPLETED-WITH-ERRORS';    

       --CREATE NEW BATCH
        DECLARE batchrun_cursor CURSOR LOCAL
            FOR
                SELECT  BatchID,
                        SystemCode,
                        1 as RunNumber,
                        null as StartTime,
                        dateadd(day, 1, SnapshotDate) as SnapshotDate,
                        'False' as Restart,
                        'NOT-STARTED' as Status,
                         1 as CurrentIND,
                         @CurrentTimeZoneTimeStamp as UpdateAt 
                FROM  dbo.BatchRun
                WHERE  SystemCode = 'OWS'
                AND  SnapshotDate <= CAST(@CurrentTimeZoneTimeStamp-1 AS Date)
                AND CurrentIND = 0
                AND Status IN ('COMPLETED-SUCCESSFULLY')
                AND BatchID IN (SELECT BatchID
                                    FROM Batch
                                    WHERE Status = 'Active'
                                    AND SystemCode = @PSystemCode
                                    AND Frequency =  @PFrequency)
                AND BatchID NOT IN (SELECT BatchID
                                    FROM dbo.BatchRun
                                    WHERE [Status] in ('NOT-STARTED','IN-PROGRESS'))
    
        OPEN batchrun_cursor;
        FETCH NEXT FROM batchrun_cursor INTO @BatchID, @SystemCode, @RunNumber, @StartTime, @SnapshotDate, @Restart, @Status, @CurrentIND, @UpdateAt;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXECUTE @RC = [dbo].[GetRunID] 
                    @SnapshotDate
                    ,@BatchID
                    ,@RunNumber
                    ,@RunID OUTPUT

            INSERT INTO dbo.BatchRun(
                RunID,
                BatchID,
                SystemCode,
                RunNumber,
                StartTime,
                SnapshotDate,
                Restart,
                Status,
                CurrentIND,
                UpdateAt
            )
            VALUES(
                @RunID,
                @BatchID,
                @SystemCode,
                @RunNumber,
                @StartTime,
                @SnapshotDate,
                @Restart,
                @Status,
                @CurrentIND,
                @UpdateAt
            );

            FETCH NEXT FROM batchrun_cursor INTO @BatchID, @SystemCode, @RunNumber, @StartTime, @SnapshotDate, @Restart, @Status, @CurrentIND,  @UpdateAt;
            
        END;

        CLOSE batchrun_cursor;      

GO
