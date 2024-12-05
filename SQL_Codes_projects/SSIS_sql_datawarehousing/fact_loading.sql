INSERT INTO Sales_Fact (Sale_ID, Date_Key, Product_Key, Customer_Key, Store_Key, Quantity_Sold, Total_Sale_Amount)
SELECT 
    ts.Transaction_ID AS Sale_ID,
    dd.Date_Key,                    -- Surrogate key from Date_Dimension
    pd.Product_Key,                 -- Surrogate key from Product_Dimension (latest version)
    cd.Customer_Key,                -- Surrogate key from Customer_Dimension (latest version)
    sd.Store_Key,                   -- Surrogate key from Store_Dimension (latest version)
    ts.Quantity AS Quantity_Sold,
    ts.Sale_Amount AS Total_Sale_Amount
FROM 
    Transaction_Sales ts
JOIN 
    Date_Dimension dd ON dd.Date = ts.Transaction_Date
JOIN 
    (SELECT Product_Key, Product_ID 
     FROM Product_Dimension 
     WHERE Valid_To IS NULL) pd 
ON pd.Product_ID = ts.Product_ID
JOIN 
    (SELECT Customer_Key, Customer_ID 
     FROM Customer_Dimension 
     WHERE Valid_To IS NULL) cd 
ON cd.Customer_ID = ts.Customer_ID
JOIN 
    (SELECT Store_Key, Store_ID 
     FROM Store_Dimension 
     WHERE Valid_To IS NULL) sd 
ON sd.Store_ID = ts.Store_ID;





-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- another useful code                                                                                                                          ||||||||SIBBIR SIHAN COPYRIGHT|||||||
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO Sales_Fact (Sale_ID, Date_Key, Product_Key, Customer_Key, Store_Key, Quantity_Sold, Total_Sale_Amount)
SELECT 
    ts.Transaction_ID AS Sale_ID,
    dd.Date_Key,                    -- Surrogate key from Date_Dimension
    pd.Product_Key,                 -- Surrogate key from Product_Dimension
    cd.Customer_Key,                -- Surrogate key from Customer_Dimension
    sd.Store_Key,                   -- Surrogate key from Store_Dimension
    ts.Quantity AS Quantity_Sold,
    ts.Sale_Amount AS Total_Sale_Amount
FROM 
    Transaction_Sales ts
JOIN 
    Date_Dimension dd ON dd.Date = ts.Transaction_Date
JOIN 
    Product_Dimension pd ON pd.Product_ID = ts.Product_ID
    AND ts.Transaction_Date BETWEEN pd.Valid_From AND COALESCE(pd.Valid_To, '9999-12-31')
JOIN 
    Customer_Dimension cd 
        ON cd.Customer_ID = ts.Customer_ID 
        AND ts.Transaction_Date BETWEEN cd.Valid_From AND COALESCE(cd.Valid_To, '9999-12-31')
JOIN 
    Store_Dimension sd ON sd.Store_ID = ts.Store_ID
    AND ts.Transaction_Date BETWEEN sd.Valid_From AND COALESCE(sd.Valid_To, '9999-12-31')
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM Sales_Fact sf
        WHERE sf.Sale_ID = ts.Transaction_ID
          AND sf.Date_Key = dd.Date_Key
          AND sf.Product_Key = pd.Product_Key
          AND sf.Customer_Key = cd.Customer_Key
          AND sf.Store_Key = sd.Store_Key
    );



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DOING IT USING @LASTLOADDATE                                                                          ||||||||SIBBIR SIHAN COPYRIGHT|||||||
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DECLARE @LastLoadDate DATETIME;

SELECT @LastLoadDate = Last_Load_Timestamp
FROM Load_Control
WHERE Table_Name = 'Sales_Fact';

INSERT INTO Sales_Fact (Sale_ID, Date_Key, Product_Key, Customer_Key, Store_Key, Quantity_Sold, Total_Sale_Amount)
SELECT 
    ts.Transaction_ID AS Sale_ID,
    dd.Date_Key,
    pd.Product_Key,
    cd.Customer_Key,
    sd.Store_Key,
    ts.Quantity,
    ts.Sale_Amount
FROM 
    Transaction_Sales ts
JOIN 
    Date_Dimension dd ON dd.Date = ts.Transaction_Date
JOIN 
    Product_Dimension pd ON pd.Product_ID = ts.Product_ID
JOIN 
    Customer_Dimension cd 
        ON cd.Customer_ID = ts.Customer_ID 
JOIN 
    Store_Dimension sd ON sd.Store_ID = ts.Store_ID
WHERE 
    ts.Transaction_Date > @LastLoadDate;
    
UPDATE Load_Control
SET Last_Load_Timestamp = GETDATE()
WHERE Table_Name = 'Sales_Fact';





-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- another useful code                                                                                                                          ||||||||SIBBIR SIHAN COPYRIGHT|||||||
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE for Customer Dimension with SCD Type 2 logic
WITH Customer_CTE AS (
    SELECT 
        cd.Customer_Key,
        cd.Customer_ID,
        cd.Valid_From,
        cd.Valid_To,
        ROW_NUMBER() OVER (
            PARTITION BY cd.Customer_ID
            ORDER BY cd.Valid_From DESC  -- Latest version for each Customer_ID
        ) AS rn
    FROM 
        Customer_Dimension cd
),

-- CTE for Product Dimension with SCD Type 2 logic
Product_CTE AS (
    SELECT 
        pd.Product_Key,
        pd.Product_ID,
        pd.Valid_From,
        pd.Valid_To,
        ROW_NUMBER() OVER (
            PARTITION BY pd.Product_ID
            ORDER BY pd.Valid_From DESC  -- Latest version for each Product_ID
        ) AS rn
    FROM 
        Product_Dimension pd
)

-- Insert new or updated records into Sales_Fact
INSERT INTO Sales_Fact (Sale_ID, Date_Key, Product_Key, Customer_Key, Store_Key, Quantity_Sold, Total_Sale_Amount)
SELECT 
    ts.Transaction_ID AS Sale_ID,
    dd.Date_Key,
    pcte.Product_Key,
    ccte.Customer_Key,
    sd.Store_Key,
    ts.Quantity,
    ts.Sale_Amount
FROM 
    Transaction_Sales ts
JOIN 
    Date_Dimension dd ON dd.Date = ts.Transaction_Date
JOIN 
    Product_CTE pcte ON pcte.Product_ID = ts.Product_ID
    AND ts.Transaction_Date BETWEEN pcte.Valid_From AND COALESCE(pcte.Valid_To, '9999-12-31')
    AND pcte.rn = 1  -- Get the latest version for each Product_ID
JOIN 
    Customer_CTE ccte ON ccte.Customer_ID = ts.Customer_ID
    AND ts.Transaction_Date BETWEEN ccte.Valid_From AND COALESCE(ccte.Valid_To, '9999-12-31')
    AND ccte.rn = 1  -- Get the latest version for each Customer_ID
JOIN 
    Store_Dimension sd ON sd.Store_ID = ts.Store_ID;



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Incremental Fact Table load with Hasing                                                                                                       ||||||||SIBBIR SIHAN COPYRIGHT|||||||
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- step 1:  Add a Hash Column to Sales_Fact

ALTER TABLE Sales_Fact 
ADD Record_Hash BINARY(32);  -- Assuming a binary hash like MD5 (or similar)

-- step 2:  Generate the Hash for Each Incoming Record
WITH TransactionDataWithHash AS (
    SELECT 
        ts.Transaction_ID AS Sale_ID,
        dd.Date_Key,                    -- Surrogate key from Date_Dimension
        pd.Product_Key,                 -- Surrogate key from Product_Dimension
        cd.Customer_Key,                -- Surrogate key from Customer_Dimension
        sd.Store_Key,                   -- Surrogate key from Store_Dimension
        ts.Quantity AS Quantity_Sold,
        ts.Sale_Amount AS Total_Sale_Amount,
        
        -- Generate hash for the incoming record (adjust fields as needed)
        HASHBYTES('SHA2_256', 
            CAST(ts.Transaction_ID AS VARCHAR(50)) + 
            CAST(dd.Date_Key AS VARCHAR(50)) + 
            CAST(pd.Product_Key AS VARCHAR(50)) + 
            CAST(cd.Customer_Key AS VARCHAR(50)) + 
            CAST(sd.Store_Key AS VARCHAR(50)) + 
            CAST(ts.Quantity AS VARCHAR(50)) + 
            CAST(ts.Sale_Amount AS VARCHAR(50))
        ) AS Record_Hash
        
    FROM 
        Transaction_Sales ts
    JOIN 
        Date_Dimension dd ON dd.Date = ts.Transaction_Date
    JOIN 
        Product_Dimension pd ON pd.Product_ID = ts.Product_ID
        AND ts.Transaction_Date BETWEEN pd.Valid_From AND COALESCE(pd.Valid_To, '9999-12-31')
    JOIN 
        Customer_Dimension cd ON cd.Customer_ID = ts.Customer_ID
        AND ts.Transaction_Date BETWEEN cd.Valid_From AND COALESCE(cd.Valid_To, '9999-12-31')
    JOIN 
        Store_Dimension sd ON sd.Store_ID = ts.Store_ID
        AND ts.Transaction_Date BETWEEN sd.Valid_From AND COALESCE(sd.Valid_To, '9999-12-31')
)

-- step 3:  Load Only New or Changed Records Based on the Hash
INSERT INTO Sales_Fact (Sale_ID, Date_Key, Product_Key, Customer_Key, Store_Key, Quantity_Sold, Total_Sale_Amount, Record_Hash)
SELECT 
    twh.Sale_ID,
    twh.Date_Key,
    twh.Product_Key,
    twh.Customer_Key,
    twh.Store_Key,
    twh.Quantity_Sold,
    twh.Total_Sale_Amount,
    twh.Record_Hash
FROM 
    TransactionDataWithHash twh
LEFT JOIN 
    Sales_Fact sf ON sf.Sale_ID = twh.Sale_ID
WHERE 
    sf.Sale_ID IS NULL                -- New record (doesn’t exist in fact table)
    OR sf.Record_Hash <> twh.Record_Hash;  -- Updated record (hash has changed)
