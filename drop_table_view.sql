-- how to drop a view if already exists before creating from the scratch
Use db
GO

IF (SELECT OBJECT_ID('[db].[tmp].[vw_details]')) IS NOT NULL 
DROP VIEW [tmp].[vw_details]


GO


CREATE VIEW [tmp].[vw_details] AS


-- code goes here after improment

Select * from db.tmp.tbl_working_days

GO
