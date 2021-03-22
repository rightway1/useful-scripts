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
-----------------------------------------------------------
CREATE SERVER my_remote_db
	FOREIGN DATA WRAPPER postgres_fdw
	OPTIONS (
		host 'my-remote-server.local',
		dbname 'devdb'
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
-- 4. Create foreign table(s)
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
	schema_name 'sales'
	table_name 'contacts'
	use_remote_estimate 'true'
);

-- Note. setting "use_remote_estimate" allows the remote postgres db to handle the optimisation of queries on this table,
--   making it much more efficient since the remote database has all the stats on the data, which the local db doesn't.