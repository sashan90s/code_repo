Create User [Dscro_Landing_ReadOnly] from External Provider;
Alter Role db_datareader ADD MEMBER [Dscro_Landing_ReadOnly];
SELECT name, type_desc
FROM sys.database_principals
WHERE name = 'Dscro_Landing_ReadOnly';