// Lab - Writing data to Azure Synapse SQL Dedicated Pool

CREATE TABLE [dbo].[DimCustomer](    
	[CustomerID] [int] NOT NULL,
    [CompanyName] varchar(200) NOT NULL,
	[SalesPerson] varchar(300) NOT NULL
)
    WITH  
(   
    DISTRIBUTION = REPLICATE
)		


%scala
import org.apache.spark.sql.types._

val path="abfss://csv@datalake244434.dfs.core.windows.net/DimCustomer/"
val checkpointPath="abfss://checkpoint@datalake244434.dfs.core.windows.net/"

val dataSchema = StructType(Array(    
    StructField("CustomerID", IntegerType, true),
    StructField("CompanyName", StringType, true),
    StructField("SalesPerson", StringType, true)))


%scala
spark.conf.set(
    "fs.azure.account.key.datalake244434.dfs.core.windows.net",
    "dilbGv2rof6G4emB0qWgVwAOOexu/bIpvJiUnfal7+klHqCsKLB+JkQzMfRlgu0fm14iUFNHXPeU+AStZZXK2w==")

val dfDimCustomer=(spark.readStream.format("cloudfiles")
    .schema(dataSchema)    
    .option("cloudFiles.format","csv")
    .option("header",true)
    .load(path))

dfDimCustomer.writeStream
  .format("com.databricks.spark.sqldw")
  .option("url", "jdbc:sqlserver://dataworkspace2000939.sql.azuresynapse.net:1433;database=pooldb")
  .option("user","sqladminuser")
  .option("password","sqlpassword@123")
  .option("tempDir", "abfss://staging@datalake244434.dfs.core.windows.net/databricks")  
  .option("forwardSparkAzureStorageCredentials", "true")
  .option("dbTable", "DimCustomer") 
  .option("checkpointLocation", checkpointPath) 
  .start()

