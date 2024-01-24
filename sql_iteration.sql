-- Create a table variable to store the results
DECLARE @Results TABLE (
    Column1 INT,
    Column2 VARCHAR(50)
);

DECLARE @Counter INT = 1;  -- Declare and initialize variable inside BEGIN block

-- Loop to execute the code block with different parameters
WHILE @Counter <= 24
BEGIN
    -- Declare and use additional variables inside the loop
    DECLARE @SomeValue INT = @Counter * 2;

    -- Your statements to generate results for the current iteration
    INSERT INTO @Results (Column1, Column2)
    SELECT @Counter, 'Iteration ' + CAST(@Counter AS VARCHAR(10)) + ', SomeValue ' + CAST(@SomeValue AS VARCHAR(10));

    -- Increment the counter
    SET @Counter = @Counter + 1;
END;

-- Select the final results from the table variable
SELECT Column1, Column2 FROM @Results;
