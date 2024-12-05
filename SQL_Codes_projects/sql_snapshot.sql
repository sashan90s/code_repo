-- get the logical name of the datafile of the database you want to take snapshot of
-- use the following code. 
-- I have shown you both, dynamic and normal strategy.




Use Master

CREATE DATABASE SM_DB_SNAP ON
(
NAME = SampleDb, -- datalog file name
FILENAME = 'E:\programming\SQL Projects\SAMPLEDB.SS'
) AS SNAPSHOT OF SampleDb; -- database name that you want to take snapshot of
GO



-- lets make the code bit dynamic

DECLARE @DatabaseName varchar(MAX) = 'SM_DB_SNAP'
    , @SQL NVARCHAR(MAX);

SET @SQL = 

N'CREATE DATABASE ' +QUOTENAME(@DatabaseName + '_' + Cast(Format(GETDATE(),'dd-MM-yyyy', 'en-gb') as varchar)) +' ON
(
NAME = SampleDb, 
FILENAME = ''E:\programming\SQL Projects\SAMPLEDB' + Cast(Format(GETDATE(),'dd-MM-yyyy', 'en-gb') as varchar) + '.SS''
) AS SNAPSHOT OF SampleDb; 
'

PRINT(@SQL);
-- USE [MainDb]

EXECUTE(@SQL);

-- Ensure no active connections to the source database before reverting:
USE master;
ALTER DATABASE [SourceDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

-- Syntax to revert to a snapshot
USE master;
RESTORE DATABASE SourceDatabaseName FROM DATABASE_SNAPSHOT = 'SnapshotName';


-- safer approach would be to use insert into ... select statement
INSERT INTO [SourceDatabase].[SchemaName].[TableName] (Column1, Column2, ...)
SELECT Column1, Column2, ...
FROM [SnapshotName].[SchemaName].[TableName];

  



------------------------------------------------------------------------------------------------------------------------
-- if you are working with the stored procedure, the following approach might work better for you
-- following code NEEDS TO BE ADJUSTED TO MEET OUR REQUIREMENTS. 

CREATE PROCEDURE DM_TCM_TO_COMCARE 
    @FROM_DB varchar(100) = '',
    @TO_DB varchar(100) = ''
AS
BEGIN
    --CHECK INPUT VARIABLES

    DROP SYNONYM dbo.From_TableA 
    SET @SQL_SCRIPT = 'CREATE SYNONYM dbo.From_TableA FOR ['+@FROM_DB+'].[dbo].[TableA]'
    exec (@SQL_SCRIPT)

    DROP SYNONYM dbo.To_TableB
    SET @SQL_SCRIPT = 'CREATE SYNONYM dbo.To_TableB FOR ['+@TO_DB+'].[dbo].[TableB]'
    exec (@SQL_SCRIPT)

    select * from dbo.From_TableA
    select * from dbo.To_TableB

    insert into dbo.To_TableB 
         select * from dbo.From_TableA where 1 = 1
    -- etc
END
GO