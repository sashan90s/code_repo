
INSERT INTO [dbo].[EmailRecipients](
    SystemCode,
    DatasetName,
    SystemInfoID,
    FirstName,
    LastName,
    EmailAddress
)VALUES(
    'OWS',
    'Sales',
    1,
    'SomeName1',
    'SomeLastName1',
    'foo1@gmail.com'
)
GO

INSERT INTO [dbo].[EmailRecipients](
    SystemCode,
    DatasetName, 
    SystemInfoID,
    FirstName,
    LastName,
    EmailAddress
)VALUES(
    'OWS',
    'Sales',
     1,
    'SomeName2',
    'SomeLastName2',
    'foo2@gmail.com'
)
GO

INSERT INTO [dbo].[EmailRecipients](
    SystemCode,
    DatasetName,
    SystemInfoID,
    FirstName,
    LastName,
    EmailAddress
)VALUES(
    'OWS',
    'SalesRef',
    2,
    'SomeName1',
    'SomeLastName1',
    'foo1@gmail.com'
)
GO

INSERT INTO [dbo].[EmailRecipients](
    SystemCode,
    DatasetName,
    SystemInfoID, 
    FirstName,
    LastName,
    EmailAddress
)VALUES(
    'OWS',
    'SalesRef',
    2,
    'SomeName2',
    'SomeLastName2',
    'foo2@gmail.com'
)
GO
