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


-- Count the number of connections to the database
SELECT sum(numbackends) FROM pg_stat_database;
--or
select count(*) from pg_stat_activity;


-- Size of database
SELECT pg_size_pretty(pg_database_size('scotgovosmm')) As fulldbsize;


-- Ensure all tables and indexes in correct tablespace
select 'alter table ' || schemaname || '.'  || tablename || ' set tablespace my_tablespace;' from pg_tables where schemaname like 'my_schema%' and tablespace = 'old_tablespace';


-- update the contents of one table to match the contents of another, using a spatial join (point in polygon)
update streets s set countyname = c.countyname from counties c where st_intersects(c.shape, s.shape);


-- Update values in one table with multiple values from another table
Update table1 t1 set
	newfield1 = t2.oldfield1,
	newfield2 = td2.oldfield2
	from table2 t2
	where t2.id = t1.id;
	
