// Lab - Specifying the schema

%sql

DROP TABLE DimCustomer

%sql

CREATE TABLE DimCustomer(
    CustomerID INT,
    CompanyName STRING,
	SalesPerson STRING
)

%scala
spark.conf.set(
    "fs.azure.account.key.datalake244434.dfs.core.windows.net",
    "dilbGv2rof6G4emB0qWgVwAOOexu/bIpvJiUnfal7+klHqCsKLB+JkQzMfRlgu0fm14iUFNHXPeU+AStZZXK2w==")


val path="abfss://csv@datalake244434.dfs.core.windows.net/DimCustomer/"
val checkpointPath="abfss://checkpoint@datalake244434.dfs.core.windows.net/"

%scala
val dataSchema = StructType(Array(    
    StructField("CustomerID", IntegerType, true),
    StructField("CompanyName", StringType, true),
    StructField("SalesPerson", StringType, true)))


%scala
val dfDimCustomer=(spark.readStream.format("cloudfiles")
    .schema(dataSchema)    
    .option("cloudFiles.format","csv")
    .option("header",true)
    .load(path))

dfDimCustomer.writeStream.format("delta")
.option("checkpointLocation",checkpointPath)
.option("mergeSchema", "true")
.table("DimCustomer")