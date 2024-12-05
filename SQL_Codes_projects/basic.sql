CREATE TABLE Customer(
	CustomerId bigint NOT NULL PRIMARY KEY,
	FirstName varchar(50) NOT NULL,
	LastName varchar(50) NOT NULL,
	CustomerRanking varchar(50) NULL)


CREATE TABLE OrderHeader(
	OrderHeaderId bigint NOT NULL, 
	CustomerId bigint NOT NULL,
	OrderTotal Money NOT NULL
)

ALTER TABLE OrderHeader ADD CONSTRAINT FK_OrderHeader_Customer 
FOREIGN KEY(CustomerId) REFERENCES Customer(CustomerId)  

-- Add a few customers
INSERT INTO Customer (CustomerId, FirstName, LastName, CustomerRanking) VALUES
    (1, 'Lukas', 'Keller', NULL),
    (2, 'Jeff', 'Hay', 'Good'),
    (3, 'Keith', 'Harris', 'So-So'),
    (4, 'Simon', 'Pearson', 'A+'),
    (5, 'Matt', 'Hink', 'Stellar'),
    (6, 'April', 'Reagan', '');

-- Add a few orders
INSERT INTO OrderHeader (OrderHeaderId, CustomerId, OrderTotal) VALUES
    (1, 2, 28.58), -- Jeff's order
    (2, 2, 169.08), -- Jeff's order
    (3, 3, 12.99), -- Keith's order
    (4, 4, 785.75), -- Simon's order
    (5, 5, 4250.00), -- Matt's order
    (6, 6, 18.58), -- April's order
    (7, 6, 10.00), -- April's order
    (8, 6, 18.08); -- April's order



    CREATE VIEW vwCustomerOrderSummary AS
    SELECT c.CustomerId, c.FirstName, c.LastName, c.CustomerRanking,
    ISNULL(SUM(oh.OrderTotal),0)  AS OrderTotal
    FROM dbo.Customer as c
    LEFT OUTER JOIN dbo.OrderHeader AS oh ON c.CustomerId = oh.CustomerId
    GROUP BY c.CustomerId, c.FirstName, c.LastName, c.CustomerRanking