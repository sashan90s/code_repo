-- left join with ON and AND with WHERE clause

-- if you notice, there are two querries
-- first one applies the condition on the entire returned table
-- second one applies the codition on the table from where we will
-- bring the column AKA before applying the condition. 

--restrict the query to orders over 5
--This method removes the other products
SELECT P.ProductID, P.Name, SOD.OrderQty
FROM Production.Product AS P 
LEFT OUTER JOIN Sales.SalesOrderDetail AS SOD 
	ON P.ProductID = SOD.ProductID
WHERE SOD.OrderQty > 5;

--By moving the restriction to ON, the products don't drop out
SELECT P.ProductID, P.Name, SOD.OrderQty
FROM Production.Product AS P 
LEFT OUTER JOIN Sales.SalesOrderDetail AS SOD 
	ON P.ProductID = SOD.ProductID
	AND SOD.OrderQty > 5;
