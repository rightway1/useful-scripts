-- creates a script to update all sequences to their current value for given schema "my_schemaname"
-- Note that there could be some incorrect entries when this script is run so you will need to delete these first
select 'select setval(''' ||sch || '.' ||seq || ''',max(' || trim('_' from part) || ')) from ' || sch || '.' || tbl || ';' as test
from (select ut.relname as tbl, sc.relname as seq, sc.schemaname as sch, replace(replace(sc.relname,ut.relname,''),'_seq','') as part 
from pg_stat_user_tables ut, pg_statio_user_sequences sc
where sc.schemaname = 'my_schemaname' and ut.schemaname = 'my_schemaname'
and strpos(sc.relname,ut.relname) = 1 ) x;


-- Vacuum analyze all tables in schema "my_schema"
select 'vacuum analyze my_schema.' || tablename || ';' as test 
from pg_tables
where schemaname = 'my_schema';

-- Drop all tables in a schema "my_schema" containing no rows
select 'Drop table ' || schemaname || '."' || relname || '";' as test 
from pg_stat_user_tables
where schemaname = 'my_schema'
and n_live_tup = 0
order by relname;

-- Convert postgis 2.x Geometry column type from "Geometry" to specific geometry type
ALTER TABLE my_schema.my_table ALTER COLUMN shape SET DATA TYPE geometry(Polygon,27700) USING ST_Transform(ST_Force2D(shape),27700);
ALTER TABLE my_schema.my_table ALTER COLUMN shape SET DATA TYPE geometry(MultiPolygon,27700) USING st_multi(ST_Transform(ST_Force2D(shape),27700));
-- Convert Multipoint geometry column to Point. Assumes only one point in each multipoint
ALTER TABLE my_schema.my_table ALTER COLUMN shape SET DATA TYPE geometry(Point,27700) USING st_geometryN(shape,1);


-- Identify tables and indexes in wrong tablespace for schema
select schemaname, tablename, tablespace from pg_tables where schemaname like 'my_schema%' and tablespace <> 'my_tablespace';
select schemaname, indexname, tablespace from pg_indexes where schemaname like 'my_schema%' and tablespace <> 'my_tablespace';
-- Generate commands to move tables and indexes into correct tablespace for schema
select 'alter table ' || schemaname || '.'  || tablename || ' set tablespace my_tablespace;' from pg_tables where schemaname like 'my_schema%' and tablespace = 'old_tablespace';
select 'alter index ' || schemaname || '.' || indexname || ' set tablespace my_tablespace;' from pg_indexes where schemaname like 'my_schema%' and tablespace = 'old_tablespace';


------------------------------------------------------
-- Get info about database
------------------------------------------------------

-- Count the number of connections to the database
SELECT sum(numbackends) FROM pg_stat_database;
--or
SELECT count(*) FROM pg_stat_activity;

-- Get max connections for a database
SELECT * from pg_settings WHERE name = 'max_connections';


-- Size of database
SELECT pg_size_pretty(pg_database_size('scotgovosmm')) As fulldbsize;

-- Size of tablespaces, excluding specific tablespaces
SELECT spcname, pg_size_pretty(pg_tablespace_size(spcname)) 
    FROM pg_tablespace
    WHERE spcname not like 'pg_%'
    ORDER BY spcname;

-- Size of Biggest x tables in a schema
SELECT
    relname as "Table",
    pg_size_pretty(pg_total_relation_size(relid)) As "Size"
    FROM pg_catalog.pg_statio_user_tables
    WHERE schemaname = 'myschema'
    ORDER BY pg_total_relation_size(relid) DESC
    LIMIT 10;

-- Total table size by schema
SELECT
	schemaname,
    pg_size_pretty(sum(pg_total_relation_size(relid))) As "Size"
    FROM pg_catalog.pg_statio_user_tables
    group by schemaname;

