

CREATE TABLE SystemInfo (
    ID INT NOT NULL IDENTITY PRIMARY KEY,
    SystemCode varchar(5) not null,
    SystemName varchar(100) not null,
    DatasetName varchar(50) not null,
    Description varchar(200),
    Status varchar(10) not null,
    UpdateAt datetime
)
GO

ALTER TABLE SystemInfo
ADD Constraint SystemInfo_UK1 unique(SystemCode, DatasetName)
GO

CREATE TABLE Batch(
    ID INT NOT NULL IDENTITY PRIMARY KEY,
    SystemInfoID INT NOT NULL,
    SystemCode varchar(5) NOT NULL,
    ScheduledStartTime varchar(10),
    TimeZone varchar(100),
    Frequency varchar(10) NOT NULL,
    Status varchar(20) NOT NULL,
    UpdateAt datetime NOT NULL
)
GO

ALTER TABLE Batch
ADD Constraint Batch_FK1 Foreign Key (SystemInfoID)
REFERENCES SystemInfo(id)
GO

ALTER TABLE Batch
ADD Constraint Batch_UK1 unique(SystemInfoID)


CREATE TABLE BatchRun(
    RunID varchar(20) NOT NULL,
    BatchID INT NOT NULL,
    SystemCode varchar(5) NOT NULL,
    RunNumber INT NOT NULL,
    StartTime datetime,
    EndTime datetime,
    SnapshotDate date,
    Restart varchar(10),
    Status varchar(25),
    CurrentIND INT,
    UpdateAt datetime NOT NULL
)
GO

ALTER TABLE BatchRun
ADD Constraint BatchRun_FK1 Foreign Key (BatchID)
REFERENCES Batch(id)
GO

CREATE TABLE DataObjectMetadata(
    ID INT NOT NULL IDENTITY PRIMARY KEY,
    SystemInfoID INT not null,
    DataObjectInfo varchar(100) not null,
    DataObjectName varchar(50) not null,
    DataObjectType varchar(20) not null,
    Container      varchar(50),
    RelativePathSchema varchar(100),
    TechnicalName varchar(50) not null,    
    UpdatedAt datetime
)
GO

ALTER TABLE DataObjectMetadata
ADD Constraint DataObjectMetadata_UK1 unique(DataObjectName, RelativePathSchema)
GO

ALTER TABLE DataObjectMetadata
ADD Constraint DataObjectMetadata_FK1 Foreign Key ( SystemInfoID)
REFERENCES SystemInfo(id)
GO

CREATE TABLE SourceToTargetMetadata(
    ID INT NOT NULL IDENTITY PRIMARY KEY,
    SourceID int not null,
    TargetID int not null,
    DepSourceToTargetID int, 
    Stage varchar(50) not null,
    Status varchar(10) not null,
    UpdateAt datetime
)
GO

ALTER TABLE SourceToTargetMetadata
ADD Constraint SourceToTargetMetadata_FK1 Foreign Key ( SourceID)
REFERENCES DataObjectMetadata(id)
GO

ALTER TABLE SourceToTargetMetadata
ADD Constraint SourceToTargetMetadata_FK2 Foreign Key (TargetID)
REFERENCES DataObjectMetadata(id)
GO

ALTER TABLE SourceToTargetMetadata
ADD Constraint SourceToTargetMetadata_UK1 unique(SourceID, TargetID)
GO

CREATE TABLE dbo.PipelineLog(
    RunID varchar(20),
    PipelineID varchar(100) not null,
    PipelineName varchar(100) not null,
    SourceToTargetID int not null,
    Status varchar(100) null,
    StartTime datetime null,
    EndTime datetime null,
    SnapshotDate date,
    UpdatedAt datetime
)
GO

CREATE TABLE [dbo].[EmailRecipients](
    SystemCode varchar(5),
    DatasetName varchar(50),
    SystemInfoID INT,
	FirstName varchar(100) NULL,
	LastName varchar(100) NULL,
	EmailAddress varchar(100) NULL
) 
GO

ALTER TABLE EmailRecipients
ADD Constraint EmailRecipients_FK1 Foreign Key (SystemCode, DatasetName)
REFERENCES SystemInfo(SystemCode, DatasetName)
GO 

ALTER TABLE EmailRecipients
ADD Constraint EmailRecipients_UK1 unique(SystemCode, DatasetName, EmailAddress)
