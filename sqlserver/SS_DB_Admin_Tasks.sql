-- Bring a database online from a tSQL query window.  (Need to open the master key first for an encrypted DB)
ALTER DATABASE <myDatabase> SET ONLINE;

-- Restore a database from backup from tSQL query 
RESTORE DATABASE <myDatabase> FROM DISK = 'C:\temp\MyDbBackup.bak'

-- If restoring a database, the database users might not be linked to logins in the database instance

-- Associate instance login with database user (2008+)
ALTER USER <databaseUser> WITH LOGIN = <myLoginName>;

-- Associate instance login with database user (<2008)
EXEC sp_change_users_login 'Update_One', '<databaseUser>', '<myLoginName>';  
GO

-- Get table size information for all tables in DB

SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    TotalSpaceMB DESC, t.Name

-- Get Index sizes for all indices in database
SELECT
    OBJECT_NAME(i.OBJECT_ID) AS TableName,
    i.name AS IndexName,
    i.index_id AS IndexID,
    8 * SUM(a.used_pages) AS 'Indexsize(KB)'
FROM
    sys.indexes AS i
    JOIN sys.partitions AS p ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
    JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
WHERE
    i.is_primary_key = 0 -- fix for size discrepancy
GROUP BY
    i.OBJECT_ID,
    i.index_id,
    i.name
ORDER BY
	'Indexsize(KB)' DESC
