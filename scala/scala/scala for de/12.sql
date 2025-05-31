-- Lab - Versioning of tables

%sql
USE appdb

%sql
SELECT * FROM dimcustomer

%sql
DESCRIBE HISTORY dimcustomer

%sql
SELECT * FROM dimcustomer VERSION AS OF 3