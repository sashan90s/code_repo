

-- loading into the dim tables



-- Step 1: Detect new records or changed records
MERGE dim_customers AS target
USING staging_customers AS source
ON target.customer_id = source.customer_id AND target.is_current = 1

-- Step 2: Update the current record in the dimension table to set end_date and is_current = 0
WHEN MATCHED AND (
        target.name <> source.name OR
        target.address <> source.address OR
        target.city <> source.city OR
        target.state <> source.state OR
        target.zip_code <> source.zip_code
    )
    THEN UPDATE SET 
        target.end_date = GETDATE(),
        target.is_current = 0

-- Step 3: Insert a new record into the dimension table (for new record or for changed record- we add a new record)
WHEN NOT MATCHED BY TARGET
    OR MATCHED AND (
        target.name <> source.name OR
        target.address <> source.address OR
        target.city <> source.city OR
        target.state <> source.state OR
        target.zip_code <> source.zip_code
    )
    THEN INSERT (customer_id, name, address, city, state, zip_code, start_date, end_date, is_current)
    VALUES (source.customer_id, source.name, source.address, source.city, source.state, source.zip_code, GETDATE(), NULL, 1);

-- Step 4: Handle any other logic if needed