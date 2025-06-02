--=================================================================================
--Created by:	Sibbir Sihan
--Date:			28th of February 2025
--Description:	Loads Timely Handover Reason data from staging.DimTimelyHandoverReason into dbo.DimTimelyHandoverReason
--Usage:		EXEC staging.usp_LoadDimTimelyHandoverReason 0;
--=================================================================================
CREATE PROCEDURE staging.usp_LoadDimTimelyHandoverReason
	@IsFullProcess BIT
AS
SET NOCOUNT ON;
DECLARE	 @ProcedureName		SYSNAME = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
		,@StartTime			DATETIME2(0) = SYSDATETIME()
		,@EndTime			DATETIME2(0)
		,@ErrorMessage		VARCHAR(1000)
		,@Inserts			INT = 0
		,@Updates			INT = 0
		,@Deletes			INT = 0
		,@Success			BIT = 0
		,@LogId				INT
		,@InsertUpdateUser	VARCHAR(100) = ORIGINAL_LOGIN()
		,@InsertUpdateTime	DATETIME2(0) = SYSDATETIME()
		,@UnknownMemberKey	INT = CAST(ref.udf_GetGlobalVariable('UnknownMemberKey') AS INT);

-- Log the start of the load
EXEC logging.usp_CreateEtlLog	 @PackageName           = @ProcedureName
								,@SourceObjectType      = 'Table'
								,@SourceObjectName      = '$(DatabaseName).staging.DimLateHandoverReason'
								,@DestinationObjectType = 'Table'
								,@DestinationObjectName = '$(DatabaseName).dbo.DimLateHandoverReason'
								,@StartTime             = @StartTime
								,@LogId                 = @LogId OUTPUT;

-- Create a temporary table variable to hold the output actions.
DECLARE @SummaryOfChanges TABLE(Change VARCHAR(250));


BEGIN TRY
	BEGIN TRANSACTION;
		-- INSERTING NEW RECORDS INTO TARGET TABLE
		INSERT INTO dbo.DimTimelyHandoverReason
			(TimelyHandoverReason
			,IsActive
			,InsertUser
			,InsertTime
			,UpdateUser
			,UpdateTime)
		OUTPUT 'Insert' INTO @SummaryOfChanges
		SELECT	 SOURCE.TimelyHandoverReason
				,1
				,@InsertUpdateUser
				,@InsertUpdateTime
				,@InsertUpdateUser
				,@InsertUpdateTime
		FROM staging.DimTimelyHandoverReason AS SOURCE
		WHERE NOT EXISTS (	SELECT 1
							FROM dbo.DimTimelyHandoverReason AS TARGET
							WHERE TARGET.TimelyHandoverReason = SOURCE.TimelyHandoverReason); 		

		-- UPDATING TARGET TABLE FOR INACTIVE RECORDS
		UPDATE TARGET
		SET	 IsActive = 1
			,UpdateUser = @InsertUpdateUser
			,UpdateTime = @InsertUpdateTime
		OUTPUT 'Update' INTO @SummaryOfChanges
		FROM dbo.DimTimelyHandoverReason AS tARGET
		INNER JOIN staging.DimTimelyHandoverReason AS SOURCE
			ON TARGET.TimelyHandoverReason = SOURCE.TimelyHandoverReason
		WHERE TARGET.IsActive = 0;

		-- UPDATING TARGET TABLE FOR RECORDS NOT IN SOURCE
		UPDATE TARGET
		SET	 IsActive = 0
			,UpdateUser = @InsertUpdateUser
			,UpdateTime = @InsertUpdateTime
		OUTPUT 'Update' INTO @SummaryOfChanges
		FROM dbo.DimTimelyHandoverReason AS TARGET
		WHERE NOT EXISTS (
				SELECT 1
				FROM #SOURCE AS SOURCE
				WHERE SOURCE.TimelyHandoverReason = TARGET.TimelyHandoverReason
			)
		AND @IsFullProcess = 1
		AND TARGET.IsActive = 1
		AND TARGET.TimelyHandoverReasonKey <> @UnknownMemberKey;

	COMMIT TRANSACTION;
	
END TRY

BEGIN CATCH
	SELECT	 @ErrorMessage = ERROR_MESSAGE()
			,@EndTime = SYSDATETIME();

	ROLLBACK TRANSACTION;

	-- Log the inserts, updates, and deletes, as well as any error message captured
	EXEC logging.usp_UpdateEtlLog	 @LogId			= @LogId
									,@EndTime		= @EndTime
									,@Success		= @Success
									,@ErrorMessage	= @ErrorMessage
									,@Inserts		= @Inserts
									,@Updates		= @Updates
									,@Deletes		= @Deletes;

	-- Throwing error stops the execution of any code after this point
	THROW;
END CATCH

SELECT	 @EndTime = SYSDATETIME()
		,@Success = 1;

-- Count the number of changes of each type from the merge
SELECT	 @Inserts = ISNULL(SUM(IIF(Change = 'Insert', 1, 0)), 0)
		,@Updates = ISNULL(SUM(IIF(Change = 'Update', 1, 0)), 0)
		,@Deletes = ISNULL(SUM(IIF(Change = 'Delete', 1, 0)), 0)
FROM @SummaryOfChanges;

-- Log the inserts, updates, and deletes, as well as any error message captured
EXEC logging.usp_UpdateEtlLog	 @LogId			= @LogId
								,@EndTime		= @EndTime
								,@Success		= @Success
								,@ErrorMessage	= @ErrorMessage
								,@Inserts		= @Inserts
								,@Updates		= @Updates
								,@Deletes		= @Deletes;