
// Lab - Streaming data using Azure Databricks

%sql
CREATE TABLE DimCustomer(
    CustomerID STRING,
    CompanyName STRING,
	SalesPerson STRING
)

%scala
spark.conf.set(
    "fs.azure.account.key.datalake244434.dfs.core.windows.net",
    "dilbGv2rof6G4emB0qWgVwAOOexu/bIpvJiUnfal7+klHqCsKLB+JkQzMfRlgu0fm14iUFNHXPeU+AStZZXK2w==")


val path="abfss://csv@datalake244434.dfs.core.windows.net/DimCustomer/"
val checkpointPath="abfss://checkpoint@datalake244434.dfs.core.windows.net/"
val schemaLocation="abfss://schema@datalake244434.dfs.core.windows.net/"

// We need to have atleast one file in the location
%scala
val dfDimCustomer=(spark.readStream.format("cloudfiles")
    .option("cloudFiles.schemaLocation", schemaLocation)
    .option("cloudFiles.format","csv")
    .load(path))

dfDimCustomer.writeStream.format("delta")
.option("checkpointLocation",checkpointPath)
.option("mergeSchema", "true")
.table("DimCustomer")