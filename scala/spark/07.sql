-- Lake databases


-- Data types - https://docs.microsoft.com/en-us/azure/synapse-analytics/metadata/table#expose-a-spark-table-in-sql

CREATE DATABASE internaldb

USE internaldb

CREATE TABLE internaldb.customer(Id int,name varchar(200)) USING Parquet


INSERT INTO internaldb.customer VALUES(1,'UserA')

SELECT * FROM internaldb.customer


-- If you want to load data from the log.csv file and then save to a table

%%pyspark
df = spark.read.load('abfss://csv@datalake244434.dfs.core.windows.net/Log.csv', format='csv'
, header=True
)
df.write.mode("overwrite").saveAsTable("internaldb.logdatanew")


SELECT * FROM internaldb.logdatanew
