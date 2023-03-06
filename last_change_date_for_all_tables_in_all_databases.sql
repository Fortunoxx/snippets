SET NOCOUNT ON
DECLARE @AllTables table (DbName sysname, SchemaName sysname, TableName sysname, Modified datetime)

DECLARE @sql NVARCHAR(max) = N'
SELECT db.name AS DatabaseName, s.name as SchemaName, t.name AS TableName, ius.last_user_update
FROM sys.databases db 
JOIN sys.dm_db_index_usage_stats ius on ius.database_id = db.database_id
JOIN ?.sys.tables t ON t.object_id = ius.object_id
JOIN ?.sys.schemas s on s.schema_id = t.schema_id
JOIN ?.sys.indexes i ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND i.is_primary_key = 1
WHERE db.name = ''?'''
INSERT INTO @AllTables (DbName, SchemaName, TableName, Modified)
    EXEC sp_msforeachdb @SQL
SET NOCOUNT OFF

SELECT * FROM @AllTables ORDER BY DbName, SchemaName, TableName
go
