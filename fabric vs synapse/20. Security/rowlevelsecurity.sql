-- STEP 1 Create Schema (optional)
CREATE SCHEMA Security;

-- STEP 2: CREATE table-valued FUNCTION
CREATE FUNCTION Security.f_FilterRowsForLoggedInUser(@SalesRep AS varchar(100))
RETURNS TABLE
WITH SCHEMABINDING
AS

WHERE @SalesRep = USER_NAME();
GO;

-- STEP 3: CreateSecurity Policy (tying the function to a specific table)
CREATE SECURITY POLICY SalesRowFilterPolicy
ADD FILTER PREDICATE Security.f_FilterRowsForLoggedInUser(SalesRep)
ON Sales.Orders
WITH (STATE = ON);

RETURN SELECT 1 AS f_FilterResult