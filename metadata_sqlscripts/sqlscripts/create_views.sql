CREATE VIEW dbo.SourceToTargetView
AS
SELECT  
    a.ID as 'SourceToTargetID',
    c.SystemCode as 'SourceSystemCode',
    c.SystemName as 'SourceSystem',
    c.DatasetName as 'SourceDatasetName',
    b.DataObjectName as 'SourceDataObjectName',
    b.Container as 'SourceContainer',
    b.RelativePathSchema as 'SourceRelativePathSchema',
    b.TechnicalName as 'SourceTechnicalName',
    e.SystemCode as 'TargetSystemCode',
    e.SystemName as 'TargetSystem',
    e.DatasetName as 'TargetDatasetName',
    d.DataObjectName as 'TargetDataObjectName',
    d.Container as 'TargetContainer',
    d.RelativePathSchema as 'TargetRelativePathSchema',
    d.TechnicalName as 'TargetTechnicalName', 
    a.Stage,
    a.Status
FROM SourceToTargetMetadata a
INNER JOIN DataObjectMetadata b
 ON a.SourceID = b.ID
INNER JOIN SystemInfo c
 ON b.SystemInfoID = c.ID
INNER JOIN DataObjectMetadata d
 ON a.TargetID = d.ID
INNER JOIN SystemInfo e
 ON d.SystemInfoID = e.ID
GO