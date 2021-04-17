-- Sometimes when starting up a db server, a database gets stuck at the "Recovery Pending" state and won't allow connections
-- Normally this will automatically resolve itself, but if there is a lack of available memory or corruption, this may not happen.
--
-- Workaround to fix "Recovery Pending" status
-- 
use master;
GO

-- Only need the next line if database is encrypted at rest
--open master key decryption by password = 'myMasterKeyPassword';

-- Put database into emergency mode with single user access
ALTER DATABASE [MyDatabase] SET EMERGENCY;
GO
ALTER DATABASE [MyDatabase] set single_user
GO
-- Repair DB - this takes some time!
DBCC CHECKDB ([MyDatabase], REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS;
GO
-- Set database back to normal mode
ALTER DATABASE [MyDatabase] set multi_user;
GO

-- If encrypted db only
--close master key;
--GO