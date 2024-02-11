--SELECT INTO creates and populates the
--table in one step
SELECT BusinessEntityID, FirstName, LastName
INTO #SNames
FROM Person.Person;

--Update names
UPDATE #Names 
SET LastName = 'SMITH', FirstName = 'ABC'
WHERE LastName = 'Smith';

--Only update the rows that join to Customer
--Only updating customers with 
UPDATE N
SET LastName = 'ABC'
FROM #Names AS N 
INNER JOIN Sales.Customer C 
ON N.BusinessEntityID = C.PersonID;

--calculate aggregate in a CTE
;WITH totals AS(
	SELECT SUM(TotalDue) Total, CustomerID 
	FROM Sales.SalesOrderHeader
	GROUP BY CustomerID)
UPDATE N 
SET Total = totals.Total 
FROM #Names AS N 
JOIN Sales.Customer AS C ON N.BusinessEntityID = C.PersonID
JOIN totals ON C.CustomerID = totals.CustomerID;
