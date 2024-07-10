// Lab - Spark Pool - Write data to Azure Synapse

import org.apache.spark.sql.types._
import org.apache.spark.sql.functions._


val dataSchema = StructType(Array(    
    StructField("Correlationid", StringType, true),
    StructField("Operationname", StringType, true),
    StructField("Status", StringType, true),
    StructField("Eventcategory", StringType, true),
    StructField("Level", StringType, true),
    StructField("Time", TimestampType, true),
    StructField("Subscription", StringType, true),
    StructField("Eventinitiatedby", StringType, true),
    StructField("Resourcetype", StringType, true),
    StructField("Resourcegroup", StringType, true),
    StructField("Resource", StringType, true)))


val df = spark.read.format("csv").option("header","true").schema(dataSchema).load("abfss://csv@datalake244434.dfs.core.windows.net/Log.csv")

display(df)



val writeOptionsWithBasicAuth:Map[String, String] = Map(Constants.SERVER -> "dataworkspace2000939.sql.azuresynapse.net",
                                           Constants.USER -> "sqladminuser",
                                           Constants.PASSWORD -> "sqlpassword@123",
                                           Constants.DATA_SOURCE -> "pooldb",                                    
                                           Constants.TEMP_FOLDER -> "abfss://staging@datalake244434.dfs.core.windows.net",
                                           Constants.STAGING_STORAGE_ACCOUNT_KEY -> "dilbGv2rof6G4emB0qWgVwAOOexu/bIpvJiUnfal7+klHqCsKLB+JkQzMfRlgu0fm14iUFNHXPeU+AStZZXK2w==")

// Also given the Storage Blob Contributor role for the storage account
import org.apache.spark.sql.SaveMode
import com.microsoft.spark.sqlanalytics.utils.Constants
import org.apache.spark.sql.SqlAnalyticsConnector._

df.
    write.    
    options(writeOptionsWithBasicAuth).
    mode(SaveMode.Overwrite).    
    synapsesql(tableName = "pooldb.dbo.logdata_parquet",                 
                tableType = Constants.INTERNAL,                 
                location = None
                )

