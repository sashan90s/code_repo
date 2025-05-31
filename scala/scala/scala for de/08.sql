-- Lab - Using the COPY INTO command

%sql
CREATE DATABASE appdb

%sql
USE appdb

%sql
CREATE TABLE logdata


spark.conf.set(
    "fs.azure.account.key.datalake244434.dfs.core.windows.net",
    "dilbGv2rof6G4emB0qWgVwAOOexu/bIpvJiUnfal7+klHqCsKLB+JkQzMfRlgu0fm14iUFNHXPeU+AStZZXK2w==")

%sql
COPY INTO logdata
FROM 'abfss://parquet@datalake244434.dfs.core.windows.net/Log.parquet'
FILEFORMAT = PARQUET,
COPY_OPTIONS ('mergeSchema' = 'true');