-- how to find who has access/permission to this database/ object/ table/ view

EXEC sp_helprotect @username = 'DiisAnalystsSwasft';

-- to get a detailed view of who has access/permission to what database/objects/table/view use the following code

SELECT 
    dp.name AS DatabasePrincipal,
    o.name AS ObjectName,
    o.type_desc AS ObjectType,
    p.permission_name,
    p.state_desc AS PermissionState,
	o.type
FROM 
    sys.database_permissions p
JOIN 
    sys.objects o ON p.major_id = o.object_id
JOIN 
    sys.database_principals dp ON p.grantee_principal_id = dp.principal_id


-- Creating USER for Azure Group/ EntraID group/ AAD group/ Active Directory Group
-- You must be logged in as an Azure AD admin to do this
CREATE USER [AAD-SQL-Readers] FROM EXTERNAL PROVIDER;
SELECT * FROM sys.database_principals WHERE name = 'AAD-SQL-Readers';
GRANT SELECT ON [dbo].[SensitiveTable] TO [AAD-SQL-Readers];

-- if you want to revole any permission from the group
REVOKE SELECT ON [dbo].[SensitiveTable] FROM [SomeUser];


SELECT dp.name, dp.type_desc, p.permission_name, p.state_desc, o.name AS ObjectName
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects o ON p.major_id = o.object_id
WHERE dp.name = 'AAD-SQL-Readers';


