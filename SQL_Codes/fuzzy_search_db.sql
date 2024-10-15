DECLARE @results table (ColumnName nvarchar(370), ColumnValue nvarchar(3690))
DECLARE @SearchStr nvarchar(100) = 'full'

SET NOCOUNT ON

-- declaring more variables

DECLARE @TableName nvarchar(256), 
		@ColumnName nvarchar(128), 
		@SearchStr2 nvarchar(110)
SET  @TableName = ''
SET @SearchStr2 = QUOTENAME('%' + @SearchStr + '%','''')

WHILE @TableName IS NOT NULL

Begin
	SET @ColumnName = ''
	SET @TableName = 
    (
        SELECT MIN(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))  -- min helps fetch the latest 
        FROM    INFORMATION_SCHEMA.TABLES
        WHERE       TABLE_TYPE = 'BASE TABLE'
            AND QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) > @TableName  --fetch the greater (new) table name
            AND OBJECTPROPERTY(
                    OBJECT_ID(
                        QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
                         ), 'IsMSShipped'
                           ) = 0
    )

	WHILE (@TableName IS NOT NULL) and (@ColumnName IS NOT NULL)
	Begin
		SET @ColumnName = 
		(
			SELECT MIN(QUOTENAME(COLUMN_NAME)) -- min helps fetch the latest 
			FROM    INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_SCHEMA = PARSENAME(@TableName, 2)
			AND TABLE_NAME  = PARSENAME(@TableName, 1)
			AND DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar')
			AND QUOTENAME(COLUMN_NAME) > @ColumnName --fetch the greater (new) column name
		
		)

		IF @ColumnName IS NOT NULL
			Begin
				INSERT INTO @Results
				EXEC
				(
					'SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT(' + @ColumnName + ', 3630) 
					FROM ' + @TableName + 
					' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
				)
			End
		End
End


SELECT ColumnName, ColumnValue FROM @results