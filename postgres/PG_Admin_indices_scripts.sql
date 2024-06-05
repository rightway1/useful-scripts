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

--- Alternative query for duplicates - from 
SELECT ni.nspname || '.' || ct.relname AS "table", 
       ci.relname AS "dup index",
       pg_get_indexdef(i.indexrelid) AS "dup index definition", 
       i.indkey AS "dup index attributes",
       cii.relname AS "encompassing index", 
       pg_get_indexdef(ii.indexrelid) AS "encompassing index definition",
       ii.indkey AS "enc index attributes"
  FROM pg_index i
  JOIN pg_class ct ON i.indrelid=ct.oid
  JOIN pg_class ci ON i.indexrelid=ci.oid
  JOIN pg_namespace ni ON ci.relnamespace=ni.oid
  JOIN pg_index ii ON ii.indrelid=i.indrelid AND
                      ii.indexrelid != i.indexrelid AND
                      (array_to_string(ii.indkey, ' ') || ' ') like (array_to_string(i.indkey, ' ') || ' %') AND
                      (array_to_string(ii.indcollation, ' ')  || ' ') like (array_to_string(i.indcollation, ' ') || ' %') AND
                      (array_to_string(ii.indclass, ' ')  || ' ') like (array_to_string(i.indclass, ' ') || ' %') AND
                      (array_to_string(ii.indoption, ' ')  || ' ') like (array_to_string(i.indoption, ' ') || ' %') AND
                      NOT (ii.indkey::integer[] @> ARRAY[0]) AND -- Remove if you want expression indexes (you probably don't)
                      NOT (i.indkey::integer[] @> ARRAY[0]) AND -- Remove if you want expression indexes (you probably don't)
                      i.indpred IS NULL AND -- Remove if you want indexes with predicates
                      ii.indpred IS NULL AND -- Remove if you want indexes with predicates
                      CASE WHEN i.indisunique THEN ii.indisunique AND
                         array_to_string(ii.indkey, ' ') = array_to_string(i.indkey, ' ') ELSE true END
  JOIN pg_class ctii ON ii.indrelid=ctii.oid
  JOIN pg_class cii ON ii.indexrelid=cii.oid
 WHERE ct.relname NOT LIKE 'pg_%' AND
       NOT i.indisprimary
 ORDER BY 1, 2, 3
       ;

--------------------------------
-- Identify rarely used indexes.
-- From github.com/pgexperts/pgx_scripts
--------------------------------
WITH table_scans as (
    SELECT relid,
        tables.idx_scan + tables.seq_scan as all_scans,
        ( tables.n_tup_ins + tables.n_tup_upd + tables.n_tup_del ) as writes,
                pg_relation_size(relid) as table_size
        FROM pg_stat_user_tables as tables
),
all_writes as (
    SELECT sum(writes) as total_writes
    FROM table_scans
),
indexes as (
    SELECT idx_stat.relid, idx_stat.indexrelid,
        idx_stat.schemaname, idx_stat.relname as tablename,
        idx_stat.indexrelname as indexname,
        idx_stat.idx_scan,
        pg_relation_size(idx_stat.indexrelid) as index_bytes,
        indexdef ~* 'USING btree' AS idx_is_btree
    FROM pg_stat_user_indexes as idx_stat
        JOIN pg_index
            USING (indexrelid)
        JOIN pg_indexes as indexes
            ON idx_stat.schemaname = indexes.schemaname
                AND idx_stat.relname = indexes.tablename
                AND idx_stat.indexrelname = indexes.indexname
    WHERE pg_index.indisunique = FALSE
),
index_ratios AS (
SELECT schemaname, tablename, indexname,
    idx_scan, all_scans,
    round(( CASE WHEN all_scans = 0 THEN 0.0::NUMERIC
        ELSE idx_scan::NUMERIC/all_scans * 100 END),2) as index_scan_pct,
    writes,
    round((CASE WHEN writes = 0 THEN idx_scan::NUMERIC ELSE idx_scan::NUMERIC/writes END),2)
        as scans_per_write,
    pg_size_pretty(index_bytes) as index_size,
    pg_size_pretty(table_size) as table_size,
    idx_is_btree, index_bytes
    FROM indexes
    JOIN table_scans
    USING (relid)
),
index_groups AS (
SELECT 'Never Used Indexes' as reason, *, 1 as grp
FROM index_ratios
WHERE
    idx_scan = 0
    and idx_is_btree
UNION ALL
SELECT 'Low Scans, High Writes' as reason, *, 2 as grp
FROM index_ratios
WHERE
    scans_per_write <= 1
    and index_scan_pct < 10
    and idx_scan > 0
    and writes > 100
    and idx_is_btree
UNION ALL
SELECT 'Seldom Used Large Indexes' as reason, *, 3 as grp
FROM index_ratios
WHERE
    index_scan_pct < 5
    and scans_per_write > 1
    and idx_scan > 0
    and idx_is_btree
    and index_bytes > 100000000
UNION ALL
SELECT 'High-Write Large Non-Btree' as reason, index_ratios.*, 4 as grp 
FROM index_ratios, all_writes
WHERE
    ( writes::NUMERIC / ( total_writes + 1 ) ) > 0.02
    AND NOT idx_is_btree
    AND index_bytes > 100000000
ORDER BY grp, index_bytes DESC )
SELECT reason, schemaname, tablename, indexname,
    index_scan_pct, scans_per_write, index_size, table_size
FROM index_groups;


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
--  Change in ratio is more indicative than actual value
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
