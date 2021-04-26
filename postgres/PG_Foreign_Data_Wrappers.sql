-----------------------------------------------------------
-- Example showing the steps in using FOREIGN DATA WRAPPERS
-----------------------------------------------------------

-----------------------------------------------------------
-- 1. Make sure the FDW extension is installed
-----------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgres_fdw SCHEMA public;

-----------------------------------------------------------
-- 2. Create foreign server link to remote database
--     Note that this may or may not be in a different cluster -
--      it could be another DB on the same machine
--     Here mapping to "DEVDB" on another server
--     Extensions option tells pg that remote database has postgis installed,
--      so postgis functions can be run on remote db without copying all data locally first
-----------------------------------------------------------
CREATE SERVER my_remote_db
	FOREIGN DATA WRAPPER postgres_fdw
	OPTIONS (
		host 'my-remote-server.local',
		dbname 'devdb',
		extensions 'postgis',
		use_remote_estimate 'true'
	);
	
-- Allow a user to access the foreign server if required
GRANT USAGE ON FOREIGN SERVER my_remote_db TO myuser;

-----------------------------------------------------------
-- 3. Create foreign user mapping.
--     Maps a user from your current db to a user in your remote db
--     Here mapping the "local_dba" local superuser 
--       to the "remote_reader" readonly role in the remote database
-----------------------------------------------------------
CREATE USER MAPPING FOR local_dba
	SERVER my_remote_db
	OPTIONS (
		user 'remote_reader',
		password 'reader_pwd'
	);
	
------------------------------------------------------------
-- 4a. Create individual foreign table(s)
--     Here creating a local foreign table "ft_contacts" 
--       which links to "sales.contacts" in remote 
------------------------------------------------------------
CREATE FOREIGN TABLE myschema.ft_contacts
(
	contactid	integer	not null,
	forename	varchar(20),
	surname		varchar(40),
	title		varchar(10),
	address		varchar(150),
	postcode	varchar(10)
)
SERVER my_remote_db
OPTIONS (
	schema_name 'sales',
	table_name 'contacts',
	use_remote_estimate 'true'
);

------------------------------------------------------------
-- 4b. Create foreign tables for every table in foreign schema
--     This doesn't require you to find the definition of each table 
------------------------------------------------------------
IMPORT FOREIGN SCHEMA myschema
    FROM SERVER my_remote_db
    INTO my_local_schema
    OPTIONS ( 
	    option 'value' [, ... ] 
    ); 

-- Note. setting "use_remote_estimate" allows the remote postgres db to handle the optimisation of queries on this table,
--   making it much more efficient since the remote database has all the stats on the data, which the local db doesn't.
-- - Also, for spatial queries, make sure the foreign server "extensions" option includes postgis, otherwise spatial queries 
--    will be VERY slow while it copies data to the local database to run the spatial query against it.
