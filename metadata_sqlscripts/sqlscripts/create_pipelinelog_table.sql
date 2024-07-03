
CREATE TABLE dbo.PipelineLog(
    PipelineID varchar(100) null,
    PipelineName varchar(100) null,
    Stage varchar(50) null,
    RunId varchar(100) null,
    SourceInfo  varchar(100) null,
    SourceName  varchar(100),
    SourceType  varchar(20),
    TargetInfo  varchar(100),
    TargetName  varchar(100),
    TargetType  varchar(20),
    Status varchar(100) null,
    StartTime datetime null,
    EndTime datetime null,
    SnapshotDate date,
    UpdatedAt datetime null
)
GO


CREATE PROC dbo.InsertPipelineLog(
    @PipelineID varchar(100),
    @PipelineName varchar(100) null,
    @Stage varchar(50),
    @RunID varchar(100),
    @Status varchar(100),
    @StartTime datetime null,
    @EndTime datetime null,
    @SnapshotDate date,
    @UpdatedAt DateTime
)
AS
INSERT INTO dbo.PipelineLog(PipelineID,PipelineName,Stage, RunId,Status, StartTime, EndTime,SnapshotDate,UpdatedAt)
VALUES (@PipelineID, @RunID, @Status, @UpdatedAt)
GO