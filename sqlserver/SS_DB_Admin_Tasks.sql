-- If restoring a database, the database users might not be linked to logins in the database instance

-- Associate instance login with database user (2008+)
ALTER USER <databaseUser> WITH LOGIN = <myLoginName>;

-- Associate instance login with database user (<2008)
EXEC sp_change_users_login 'Update_One', '<databaseUser>', '<myLoginName>';  
GO
