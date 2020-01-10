-- Sometimes there are longrunning transactions that aren't doing anything but blocking other processes

-- Find blocked Processes
SELECT pid, usename, pg_blocking_pids(pid) as blocked_by, query as blocked_query
FROM pg_stat_activity
where cardinality(pg_blocking_pids(pid)) > 0;

-- Now find what queries are being run by the blocking processes, 
--  replacing BLOCKING_PID with the actual "blocked_by" pid from the first query
SELECT pid, usename, query as blocking_query
FROM pg_stat_activity
where pid = BLOCKING_PID;

-- If blocking query isn't critical, Try cancelling the process
SELECT pg_cancel_backedn(BLOCKING_PID);

-- If cancelling doesn't work, terminate
SELECT pg_terminate_backend(BLOCKING_PID);

