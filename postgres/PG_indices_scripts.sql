--------------------------------
-- List all geometry columns in the database that don't have an associated spatial index
---------------------------------
SELECT c.table_schema, c.table_name, c.column_name
FROM (SELECT * FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE') As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE udt_name = 'geometry') c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%' || c.column_name || '%') 
WHERE i.tablename IS NULL
ORDER BY c.table_schema, c.table_name;



--------------------------------
-- Identify duplicate indexes.  
-- It is quite common to create an index on a field when there is already
--   a constraint on the field that automatically creates its own index.  e.g. PRIMARY KEY or UNIQUE
---------------------------------
WITH index_cols_ord as (
    SELECT attrelid, attnum, attname
    FROM pg_attribute
        JOIN pg_index ON indexrelid = attrelid
    WHERE indkey[0] > 0
    ORDER BY attrelid, attnum
),
index_col_list AS (
    SELECT attrelid,
        array_agg(attname) as cols
    FROM index_cols_ord
    GROUP BY attrelid
),
dup_natts AS (
SELECT indrelid, indexrelid
FROM pg_index as ind
WHERE EXISTS ( SELECT 1
    FROM pg_index as ind2
    WHERE ind.indrelid = ind2.indrelid
    AND ind.indkey = ind2.indkey
    AND ind.indexrelid <> ind2.indexrelid
) )
SELECT userdex.schemaname as schema_name,
    userdex.relname as table_name,
    userdex.indexrelname as index_name,
    array_to_string(cols, ', ') as index_cols,
    indexdef,
    idx_scan as index_scans
FROM pg_stat_user_indexes as userdex
    JOIN index_col_list ON index_col_list.attrelid = userdex.indexrelid
    JOIN dup_natts ON userdex.indexrelid = dup_natts.indexrelid
    JOIN pg_indexes ON userdex.schemaname = pg_indexes.schemaname
        AND userdex.indexrelname = pg_indexes.indexname
ORDER BY userdex.schemaname, userdex.relname, cols, userdex.indexrelname;

--------------------------------
-- Identify tables without primary keys.  
-- Primary keys are often required for editing, linking to other tables, and replication
---------------------------------
SELECT
    n.nspname AS "Schema",
    c.relname AS "Table Name"
FROM
    pg_catalog.pg_class c
JOIN
    pg_namespace n
ON (
        c.relnamespace = n.oid
    AND n.nspname NOT IN ('information_schema', 'pg_catalog')
    AND c.relkind='r'
)
where c.relhaspkey = False
ORDER BY n.nspname, c.relname
;


--------------------------------
-- Identify ratio between index and table sizes
-- May indicate index bloat if the ratio is high
--------------------------------
SELECT nspname, relname,
	round(100 * pg_relation_size(indexrelid) / pg_relation_size(indrelid)) / 100 as index_ratio,
	pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
	pg_size_pretty(pg_relation_size(indrelid)) as table_size
FROM pg_index I
	left join pg_class C on (C.oid = I.indexrelid)
	left join pg_namespace N on (N.oid = C.relnamespace)
WHERE 
	nspname not in ('pg_catalog', 'information_schema','pg_toast') 
	AND C.relkind='i' 
	AND pg_relation_size(indrelid) > 0
ORDER BY nspname, relname;