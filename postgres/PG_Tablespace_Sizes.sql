-- report the size of each tablespace, excluding specific tablespaces
select spcname, pg_size_pretty(pg_tablespace_size(spcname)) 
from pg_tablespace
where spcname not like 'pg_%'
order by spcname;