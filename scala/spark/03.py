# Lab - Spark Pool - Load data
# Lab - Spark Pool - Grouping your results

# When it comes to accessing Azure Data Lake , we are going to use the abfs protocol
# This is the Azure Blob File System driver that is also part of Apache Hadoop
# structure of the URI - abfs[s]://file_system@account_name.dfs.core.windows.net/<path>/<path>/<file_name>


# spark.read is a method that can be used to read data from various file formats - Parquet,Avro etc
df = spark.read.load('abfss://parquet@datalake244434.dfs.core.windows.net/Log.parquet', format='parquet')
display(df)

# Only projecting certain columns
from pyspark.sql.functions import col
newdf=df.select(col("Correlationid"),col("Operationname"),col("Resourcegroup"))
display(newdf)

# Show rows where Resource Group is NULL
from pyspark.sql.functions import col
nulldf=df.filter(col("ResourceGroup").isNull())
display(nulldf)

# Displaying the count of rows
# Using f allows for formatted string literals
rows=nulldf.count()
print(f"The number of rows : {rows}")

# Using group by
summaryRows=df.groupBy("ResourceGroup").count()
display(summaryRows)

