----------------------------------------------------------------
-- Scenario:  I have an existing database, and I want the database and any backups to be encrypted at rest
--             using SQL Server's Transparent Data Encription.
--
-- Assumption: I have:
--                 - an edition of SQL Server 2008+ that supports encryption at rest. i.e. NOT Express edition.
--                 - a database that I want to be encrypted at rest.  MyDatabase
--
-- Credit & further reading: https://www.red-gate.com/simple-talk/sql/sql-development/encrypting-sql-server-transparent-data-encryption-tde/
----------------------------------------------------------------
-- Create Database Master Key in the master database, protected with password 	
USE master;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'myS3cr3tP4ssw0rd!';
go

-- Create a self-signed certificate that is used to protect the database encryption key later
CREATE CERTIFICATE MyServerCert WITH SUBJECT = 'DEK Certificate';
go

-- Verify that the master key has been created.  A service key will also have been created
SELECT * FROM sys.symmetric_keys;

-- Verify certificate has been created, and it is protected by the master key created previously
SELECT name CertName, certificate_id CertID, pvt_key_encryption_type_desc EncryptType, issuer_name Issuer
FROM sys.certificates
WHERE issuer_name = 'DEK certificate';

-- Now switch to the database to be encrypted, and create the encryption key there protected by MyServerCert
USE MyDatabase;
GO

CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_128
ENCRYPTION BY SERVER CERTIFICATE MyServerCert;
GO

-- Verify encryption key has been created
-- Should show that encryptState = 1 (Unencrypted)
SELECT DB_NAME(database_id) DbName,
  encryption_state EncryptState,
  key_algorithm KeyAlgorithm,
  key_length KeyLength,
  encryptor_type EncryptType
FROM sys.dm_database_encryption_keys;

-- Encrypt the database
ALTER DATABASE MyDatabase
SET ENCRYPTION ON;

-- Repeating the previous SELECT should now show encryptState = 3 (Encrypted)
-- tempDB will also be encrypted

-- To remove encryption again:
--ALTER DATABASE MyDatabase
--SET ENCRYPTION OFF;


----------------------------------------------------------------
-- Scenario: I have and encrypted database and want to back up the certificates
--             so that I can restore the database again for DR purposes
--
-- Assumption: I have:
--                 - a database encrypted using the process above
----------------------------------------------------------------

-- Switch to master database
Use master;
GO

-- Backup service master key and password protect it.  
--  (Probably not needed, but included for completeness)
BACKUP SERVICE MASTER KEY 
TO FILE = 'C:\temp\SvcMasterKey.key'
ENCRYPTION BY PASSWORD = 'myS3cr3tP4ssw0rd!';

-- Backup Database Master Key and password protect it.
--  (Probably not needed for restoring data, but included for completeness)
BACKUP MASTER KEY 
TO FILE = 'C:\temp\DbMasterKey.key'
ENCRYPTION BY PASSWORD = 'myS3cr3tP4ssw0rd!';

-- Backup encryption certificate & private key, and password protect it.
--  ESSENTIAL FOR RESTORING ENCRYPTED DATABASE TO NEW MACHINE
--
BACKUP CERTIFICATE MyServerCert 
TO FILE = 'C:\temp\MyServerCert.cer'
WITH PRIVATE KEY(
  FILE = 'C:\temp\MyServerCert.key',
  ENCRYPTION BY PASSWORD = 'myS3cr3tP4ssw0rd!'
);


----------------------------------------------------------------
-- Scenario:  I have an existing encrypted database, and want to back it up
--               and restore it to a new SQL Server instance
--
-- Assumption: I have:
--                 - backup of the Database Master Key DbMasterKey.key, and a note of the password it is protected with.
--                 - backup of the Certificate and private key used to encrypt the database  MyServerCert.cer  MyServerCert.key
--                 - encrypted backup of the (encrypted) database  MyDb_20200101.bak
----------------------------------------------------------------

-- Restore master key to master database
use master;
GO
RESTORE MASTER KEY
	FROM FILE = 'C:\temp\DbMasterKey.key'
	DECRYPTION BY PASSWORD = 'myS3cr3tP4ssw0rd!'
	ENCRYPTION BY PASSWORD = 'myS3cr3tP4ssw0rd!';
GO

-- Verify that key has been restored
SELECT name KeyName,
  symmetric_key_id KeyID,
  key_length KeyLength,
  algorithm_desc KeyAlgorithm
FROM sys.symmetric_keys;

-- Restore server certificate
open master key decryption by password = 'myS3cr3tP4ssw0rd!';

create certificate MyServerCert
from file = 'C:\temp\MyServerCert.cer'
with private key (file= 'c:\temp\MyServerCert.key', 
	decryption by password = 'myS3cr3tP4ssw0rd!');

close master key;

-- Verify encryption certificate has been restored and is encrypted by master key
select * from sys.certificates;

-- Now should be able to restore the encrypted database backup
RESTORE DATABASE MyDatabase
from DISK = 'C:\mssql\backup\MyDb_20200101.bak';