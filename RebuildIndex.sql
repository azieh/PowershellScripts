
DECLARE @Table VARCHAR(255)  
DECLARE @cmd NVARCHAR(500)  
DECLARE @fillfactor INT = 90 

SET @cmd = 'DECLARE TableCursor CURSOR FOR SELECT ''['' + table_catalog + ''].['' + table_schema + ''].['' + 
table_name + '']'' as tableName FROM INFORMATION_SCHEMA.TABLES 
WHERE table_type = ''BASE TABLE'''   

-- create table cursor  
EXEC (@cmd)  
OPEN TableCursor   

FETCH NEXT FROM TableCursor INTO @Table   
WHILE @@FETCH_STATUS = 0   
BEGIN   
	print @Table

    -- SQL 2005 or higher command 
    SET @cmd = 'ALTER INDEX ALL ON ' + @Table + ' REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ')' 
    EXEC (@cmd) 

    FETCH NEXT FROM TableCursor INTO @Table   
END   

CLOSE TableCursor   
DEALLOCATE TableCursor   