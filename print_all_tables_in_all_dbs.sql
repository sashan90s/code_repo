CREATE TABLE ##resultss (This_Table_Name nvarchar(MAX), This_DB_Name varchar(50));

DECLARE @db_holder VARCHAR(50);
Declare @sql_code NVARCHAR(MAX);

DECLARE db_cursor CURSOR For
SELECT name FROM sys.databases
Order by name



Open db_cursor;

FETCH NEXT FROM db_cursor  
INTO @db_holder;

While @@FETCH_STATUS = 0
BEGIN
	-- use @db_holder;

	IF HAS_DBACCESS(@db_holder)= 1
	Begin
		SET @sql_code = 'USE [' + @db_holder + ']; 
                        INSERT INTO ##resultss (This_Table_Name, This_DB_Name)
                        SELECT name, ''' + @db_holder + ''' FROM sys.tables;
                        ' ;
		exec sp_executesql @sql_code;
	END
	ELSE
	BEGIN
	print 'No access to' + @db_holder;
	END

	

	
	--print '@db_holder'

	FETCH NEXT FROM db_cursor  
    INTO @db_holder; 
;
END

CLOSE db_cursor;  
DEALLOCATE db_cursor;  
GO 

SELECT * FROM ##resultss;

-- Drop the global temporary table when done
DROP TABLE ##resultss;
