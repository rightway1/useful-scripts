
-- get list of all partition tables in database, along with the parent table partition key, and partition bounds for each partition table
SELECT
    pn.nspname                             AS parent_schema,
    p.relname                              AS parent_table,
    pg_get_partkeydef(p.oid)               AS partition_key,

    cn.nspname                             AS partition_schema,
    c.relname                              AS partition_table,
    pg_get_expr(c.relpartbound, c.oid)      AS partition_bound
FROM pg_inherits i
JOIN pg_class p
    ON p.oid = i.inhparent
JOIN pg_namespace pn
    ON pn.oid = p.relnamespace
JOIN pg_class c
    ON c.oid = i.inhrelid
JOIN pg_namespace cn
    ON cn.oid = c.relnamespace
WHERE p.relkind = 'p'
ORDER BY
    pn.nspname,
    p.relname,
    c.relname;

-- Create a partition table with the same structure and constraints as the parent
CREATE TABLE my_schema.p_parent_table_2023q1 (LIKE my_schema.f_parent_table INCLUDING defaults INCLUDING constraints);

-- Attach the partition table to the parent table - in this case using the "list" partitioning option
ALTER TABLE my_schema.f_parent_table ATTACH PARTITION my_schema.p_parent_table_2023q1 for values in (20,21,22);
