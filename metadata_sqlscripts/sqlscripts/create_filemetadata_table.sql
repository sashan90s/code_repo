
CREATE TABLE dbo.FileMetadata(
    FileName varchar(100),
    ModifiedAt  datetime NULL,
    UpdatedAt datetime NULL
)
GO

CREATE PROC dbo.InsertFileMeta(
    @FileName varchar(100),
    @ModifiedAt DateTime,
    @UpdatedAt DateTime
)
AS
INSERT INTO dbo.FileMetadata(FileName, ModifiedAt, UpdatedAt)
VALUES (@FileName, @ModifiedAt, @UpdatedAt)
GO