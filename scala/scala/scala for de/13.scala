
// Lab - Reading data from Azure Synapse

spark.conf.set(
    "fs.azure.account.key.datalake244434.dfs.core.windows.net",
    "dilbGv2rof6G4emB0qWgVwAOOexu/bIpvJiUnfal7+klHqCsKLB+JkQzMfRlgu0fm14iUFNHXPeU+AStZZXK2w==")

val df = spark.read
  .format("com.databricks.spark.sqldw")
  .option("url", "jdbc:sqlserver://dataworkspace2000939.sql.azuresynapse.net:1433;database=pooldb")
  .option("user","sqladminuser")
  .option("password","sqlpassword@123")
  .option("tempDir", "abfss://staging@datalake244434.dfs.core.windows.net/databricks")  
  .option("forwardSparkAzureStorageCredentials", "true")
  .option("dbTable", "BlobDiagnostics")
  .load()

display(df)

// The forwardSparkAzureStorageCredentials allows Spark to foward the Account key 
// specified in the configuration