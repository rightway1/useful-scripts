--------------------------------------------------------------------------------
-- Just a collection of examples of query structures for Postgres / Postgis
--------------------------------------------------------------------------------
-- update the contents of one table to match the contents of another, using a spatial join (point in polygon)
UPDATE streets s SET countyname = c.countyname FROM counties c WHERE st_intersects(c.shape, s.shape);


-- Update values in one table with multiple values from another table
UPDATE table1 t1 SET
	newfield1 = t2.oldfield1,
	newfield2 = td2.oldfield2
	FROM table2 t2
	WHERE t2.id = t1.id;


-- Get a list of tables and views with their comments
SELECT table_catalog, table_schema, table_name, table_type,
    obj_description((table_schema||'.'||quote_ident(table_name))::regclass)
FROM information_schema.tables 
WHERE table_schema not in ('pg_catalog', 'information_schema', 'public')
-- and table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;
