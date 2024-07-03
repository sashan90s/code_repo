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
  AND c.SnapshotDate <= CAST(GETDATE()-1 AS Date)
  AND c.Status != 'COMPLETED'
INNER JOIN TMP_LATEST_BATCH d
   ON c.SnapshotDate = d.SnapshotDate
  AND c.BatchID = d.BatchID
WHERE a.[Status] = 'Active'
 