// Lab - Removing duplicate rows

%sql
SELECT CustomerID,count(CustomerID)
FROM DimCustomer
GROUP BY CustomerID
HAVING count(CustomerID)>1

%scala
spark.conf.set(
    "fs.azure.account.key.datalake244434.dfs.core.windows.net",
    "dilbGv2rof6G4emB0qWgVwAOOexu/bIpvJiUnfal7+klHqCsKLB+JkQzMfRlgu0fm14iUFNHXPeU+AStZZXK2w==")

val df = spark.read.format("csv")
.options(Map("inferSchema"->"true","header"->"true"))
.load("abfss://csv@datalake244434.dfs.core.windows.net/DimCustomer/Customer01.csv")

display(df)

%scala

import org.apache.spark.sql.functions._
display(df.groupBy(df("CustomerID")).
        count().alias("Count").
        filter(col("Count")>1))

%scala
val finaldf=df.dropDuplicates("CustomerID")

display(finaldf.groupBy(df("CustomerID")).
        count().alias("Count").
        filter(col("Count")>1))