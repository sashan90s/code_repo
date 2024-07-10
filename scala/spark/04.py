# Lab - Creating a temporary view

df = spark.read.load('abfss://parquet@datalake244434.dfs.core.windows.net/Log.parquet', format='parquet')

df.createOrReplaceTempView("logdata")

sql_1=spark.sql("SELECT Operationname, count(Operationname) FROM logdata GROUP BY Operationname")
sql_1.show()

%%sql
SELECT Operationname, count(Operationname) FROM logdata GROUP BY Operationname