--Insert System Data
INSERT INTO SystemInfo(
    SystemCode,
    SystemName,
    DatasetName,
    Description,
    Status,
    UpdateAt
)
VALUES(
    'OWS',
    'Online Web Store (Buyalot)',
    'Sales',
    'Online Web Store, Sales Data',
    'Active',
     GETDATE()
);

INSERT INTO SystemInfo(
    SystemCode,
    SystemName,
    DatasetName,
    Description,
    Status,
    UpdateAt
)
VALUES(
    'OWS',
    'Online Web Store (Buyalot)',
    'SalesRef',
    'Online Web Store, Sales Reference Data',
    'Active',
     GETDATE()
);

INSERT INTO SystemInfo(
    SystemCode,
    SystemName,
    DatasetName,
    Description,
    Status,
    UpdateAt
)
VALUES(
    'DEDL',
    'Data Engineering Data Lake',
    'OnlineWebStore',
    'Online Web Store Data stored in the Data Lake',
    'Active',
     GETDATE()
);

INSERT INTO DataObjectMetadata(
    SystemInfoID, 
    DataObjectInfo, 
    DataObjectName, 
    DataObjectType, 
    Container,      
    TechnicalName, 
    UpdatedAt 
)
VALUES(
    1,
    'Online Sales Data from the Buyalot Online WebStore',
    'Online Sales',
    'json',
    'sales',
    'onlinesales.json',
     GETDATE() 
);

INSERT INTO DataObjectMetadata(
    SystemInfoID, 
    DataObjectInfo, 
    DataObjectName, 
    DataObjectType, 
    Container,      
    TechnicalName, 
    UpdatedAt 
)
VALUES(
    2,
    'Product Inventory Data from the Buyalot Online WebStore',
    'Product Inventory',
    'json',
    'salesref',
    'products.json',
     GETDATE() 
);

INSERT INTO DataObjectMetadata(
    SystemInfoID, 
    DataObjectInfo, 
    DataObjectName, 
    DataObjectType, 
    Container,      
    TechnicalName, 
    UpdatedAt 
)
VALUES(
    2,
    'Currency Codes Data from the Buyalot Online WebStore',
    'Currency Codes',
    'json',
    'salesref',
    'currencycodes.json',
     GETDATE() 
);

INSERT INTO DataObjectMetadata(
    SystemInfoID, 
    DataObjectInfo, 
    DataObjectName, 
    DataObjectType, 
    Container,      
    TechnicalName, 
    UpdatedAt 
)
VALUES(
    2,
    'Promotion Type Data from the Buyalout Online WebStore',
    'Promotion Type',
    'json',
    'salesref',
    'promotiontype.json',
     GETDATE() 
);


INSERT INTO DataObjectMetadata(
    SystemInfoID, 
    DataObjectInfo, 
    DataObjectName, 
    DataObjectType, 
    Container,
    RelativePathSchema,      
    TechnicalName, 
    UpdatedAt 
)
VALUES(
    3,
    'Buyalot Online WebStore Sales Data within the Data Lake',
    'Online Sales',
    'json',
    'webdevelopment',
    'webstore/raw/onlinesales',
    'onlinesales.json',
     GETDATE() 
);

INSERT INTO DataObjectMetadata(
    SystemInfoID, 
    DataObjectInfo, 
    DataObjectName, 
    DataObjectType, 
    Container,
    RelativePathSchema,      
    TechnicalName, 
    UpdatedAt 
)
VALUES(
    3,
    'Buyalot Online WebStore Product Inventory Data within the Data Lake',
    'Product Inventory',
    'json',
    'webdevelopment',
    'webstore/raw/productinventory',
    'products.json',
     GETDATE() 
);

INSERT INTO DataObjectMetadata(
    SystemInfoID, 
    DataObjectInfo, 
    DataObjectName, 
    DataObjectType, 
    Container,
    RelativePathSchema,      
    TechnicalName, 
    UpdatedAt 
)
VALUES(
    3,
    'Buyalot Online WebStore Currency Codes Data within the Data Lake',
    'Currency Codes',
    'json',
    'webdevelopment',
    'webstore/raw/currencycodes',
    'currencycodes.json',
     GETDATE() 
);

INSERT INTO DataObjectMetadata(
    SystemInfoID, 
    DataObjectInfo, 
    DataObjectName, 
    DataObjectType, 
    Container,
    RelativePathSchema,      
    TechnicalName, 
    UpdatedAt 
)
VALUES(
    3,
    'Buyalot Online WebStore Promotion Type Data within the Data Lake',
    'Promotion Type',
    'json',
    'webdevelopment',
    'webstore/raw/promotiontype',
    'promotiontype.json',
     GETDATE() 
);

INSERT INTO SourceToTargetMetadata(
    SourceID,
    TargetID,
    Stage,
    Status,
    UpdateAt
)VALUES(
    1,
    5,
    'SOURCE_TO_RAW',
    'Active',
    GETDATE()
);

INSERT INTO SourceToTargetMetadata(
    SourceID,
    TargetID,
    Stage,
    Status,
    UpdateAt
)VALUES(
    2,
    6,
    'SOURCE_TO_RAW',
    'Active',
    GETDATE()
);


INSERT INTO SourceToTargetMetadata(
    SourceID,
    TargetID,
    Stage,
    Status,
    UpdateAt
)VALUES(
    3,
    7,
    'SOURCE_TO_RAW',
    'Active',
    GETDATE()
);

INSERT INTO SourceToTargetMetadata(
    SourceID,
    TargetID,
    Stage,
    Status,
    UpdateAt
)VALUES(
    4,
    8,
    'SOURCE_TO_RAW',
    'Active',
    GETDATE()
);


INSERT INTO dbo.Batch(
    SystemInfoID,
    SystemCode,
    ScheduledStartTime,
    TimeZone,
    Frequency,
    [Status],
    UpdateAt
)VALUES(
    1,
    'OWS',
    '01:00',
    'South Africa Standard Time',
    'DAILY',
    'Active',
    GETDATE()
)
GO
INSERT INTO dbo.Batch(
    SystemInfoID,
    SystemCode,
    ScheduledStartTime,
    TimeZone,
    Frequency,
    [Status],
    UpdateAt
)VALUES(
    2,
    'OWS',
    '02:00',
    'South Africa Standard Time',
    'DAILY',
    'Active',
    GETDATE()
)
GO
