Ecreate view vw_Product
with schemabinding
as
select a.ProductID, a.Name, a.ProductNumber, b.SalesOrderID, b.SalesOrderDetailID, b.CarrierTrackingNumber
from [Production]. [Product] a inner join [Sales]. [SalesOrderDetail] b on a.ProductID b.ProductID
go
Ecreate unique clustered index ix_pk on vw_Product(ProductID,SalesOrderDetailID)

select * from vw_Product