# How to use this code to bring in or update data of the latest dropped files in Azure ADLS Gen 2

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp, current_date, input_file_name, max
from pyspark.sql.types import (
    StructType, StructField,
    StringType, DateType, IntegerType,
    TimestampType, DoubleType
)
from delta.tables import DeltaTable
import os

#Setting the ETL starttime
etl_starttime = current_timestamp()

# Enabling change delta feed
set spark.databricks.delta.properties.defaults.enableChangeDataFeed = true;

# Initialize Spark session with Azure configurations (we wont need it in the fabric notebook as we by default get a sparksession there)
spark = SparkSession.builder \
    .appName("ADLS to Fabric Bronze Layer") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()

# Configure ADLS authentication
# Use service principal or managed identity as appropriate
storage_account = "your_storage_account"
container = "your_container"
folder_path = "your/folder/path"
abfs_path = f"abfss://{container}@{storage_account}.dfs.core.windows.net/{folder_path}"

# Path to your bronze table in Fabric lakehouse
bronze_table_path = "/lakehouse/default/Tables/bronze_table"

# Path to metadata table tracking processed files
processed_files_table_path = "/lakehouse/default/Tables/processed_files"


def last_processed_file(processed_files_table_path, AnotherArgument):
    ptdf = DeltaTable.forPath(spark, processed_files_table_path)

    last_processed_file = ptdf.agg({"file_name":"max"}).collect()[0][0]

    return last_processed_file


# Getting all the new files using the notebookutis api package for fabric
def identify_new_files(abfs_path, last_processed_file):
    files = notebookutils.fs.ls(abfs_path)
    # Convert filenames to integers for accurate comparison
    file_list = [
        f"{abfs_path}{file.name}"
        for file in files
        if file.isFile and int(file.name[:8]) > int(last_processed_file[:8])
    ]
    Col = ["file_name"]
    new_files_df = spark.CreateDataframe(file_list, Col)
    return new_files_df








# Function to check if metadata tracking table exists, create if not
def initialize_tracking_table():
    if not DeltaTable.isDeltaTable(spark, processed_files_table_path):
        empty_df = spark.createDataFrame([], "file_path STRING, processed_timestamp TIMESTAMP")
        empty_df.write.format("delta").save(processed_files_table_path)
    return DeltaTable.forPath(spark, processed_files_table_path)

# Creating Bronze Table Schema
custom_schema_bronze = StructType([
    StructField("file_path", StringType(), True),
    StructField("processed_timestamp", TimestampType(), True),
    StructField("upload_date", DateType(), True),
    StructField("year", IntegerType(), True),
    StructField("month", IntegerType(), True),
    StructField("record_count", IntegerType(), True),
    StructField("error_rate", DoubleType(), True)
])

# Function to check if existing bronze table exists, create if not
def initialize_bronze_table():
    if not DeltaTable.isDeltaTable(spark, bronze_table_path):
        empty_bronze_df = spark.createDataFrame([], custom_schema_bronze)
        empty_bronze_df.write.format("delta").save(bronze_table_path)
    return DeltaTable.forPath(spark, bronze_table_path)


# Get all files from the ADLS folder
def list_all_files():
    return spark.read.format("csv") \
        .option("recursiveFileLookup", "true") \
        .option("pathGlobFilter", "*.csv") \
        .load(abfs_path) \
        .select(input_file_name().alias("file_path")) \
        .distinct()

# Get list of files that have been processed already
def get_processed_files(tracking_table):
    return tracking_table.toDF().select("file_path")

# Identify new files by comparing with processed files
def identify_new_files(all_files_df, processed_files_df):
    return all_files_df.join(processed_files_df, "file_path", "leftanti")

# Process new files and add to bronze table
def process_new_files(new_files_df):
    if new_files_df.count() > 0:
        # Extract just the file paths as a list
        file_list = [row.file_path for row in new_files_df.collect()]
        
        # Read and process new CSV files
        new_data = spark.read.format("csv") \
            .option("header", "true") \
            .option("inferSchema", "true") \
            .load(file_list) \
            .withColumn("source_file", input_file_name()) \
            .withColumn("ingestion_timestamp", current_timestamp())
            
        # Write to bronze table in append mode
        new_data.write.format("delta").mode("append").save(bronze_table_path)
        
        # Return processed files with timestamp for tracking
        return new_files_df.withColumn("processed_timestamp", current_timestamp())
    else:
        return spark.createDataFrame([], "file_path STRING, processed_timestamp TIMESTAMP")

# Update tracking table with newly processed files
def update_tracking_table(tracking_table, processed_files_df):
    if processed_files_df.count() > 0:
        tracking_table.alias("tracking") \
            .merge(processed_files_df.alias("updates"), "tracking.file_path = updates.file_path") \
            .whenNotMatchedInsertAll() \
            .execute()

# Main pipeline execution
def run_incremental_load():
    # Initialize tracking table
    tracking_table = initialize_tracking_table()
    
    # Get all files and previously processed files
    all_files_df = list_all_files()
    processed_files_df = get_processed_files(tracking_table)
    
    # Identify new files
    new_files_df = identify_new_files(all_files_df, processed_files_df)
    print(f"Found {new_files_df.count()} new files to process")
    
    # Process new files and update tracking table
    newly_processed_df = process_new_files(new_files_df)
    update_tracking_table(tracking_table, newly_processed_df)
    
    print("Incremental load complete")

# Execute the pipeline
if __name__ == "__main__":
    run_incremental_load()











#This block of the code establishes just the logic for inserting recently updated data
from delta.tables import DeltaTable

# Get the existing delta_table 

# Define conditions
from delta.tables import *

deltaTablePeople = DeltaTable.forName(spark, "people10m")
deltaTablePeopleUpdates = DeltaTable.forName(spark, "people10mupdates")

dfUpdates = deltaTablePeopleUpdates.toDF()

deltaTablePeople.alias('people') \
  .merge(
    dfUpdates.alias('updates'),
    'people.id = updates.id'
  ) \
  .whenMatchedUpdate(
    condition="""
      people.firstName != updates.firstName OR
      people.middleName != updates.middleName OR
      people.lastName != updates.lastName OR
      people.gender != updates.gender OR
      people.birthDate != updates.birthDate OR
      people.ssn != updates.ssn OR
      people.salary != updates.salary
    """,
    set={
      "id": "updates.id",
      "firstName": "updates.firstName",
      "middleName": "updates.middleName",
      "lastName": "updates.lastName",
      "gender": "updates.gender",
      "birthDate": "updates.birthDate",
      "ssn": "updates.ssn",
      "salary": "updates.salary"
    }
  ) \
  .whenNotMatchedInsert(values={
      "id": "updates.id",
      "firstName": "updates.firstName",
      "middleName": "updates.middleName",
      "lastName": "updates.lastName",
      "gender": "updates.gender",
      "birthDate": "updates.birthDate",
      "ssn": "updates.ssn",
      "salary": "updates.salary"
    }
  ) \
  .execute()


# Another way of updatingfrom delta.tables import DeltaTable

deltaTable = DeltaTable.forName(spark, "myschema.mytable")

deltaTable.alias("target").merge(
    df_source.alias("source"),
    "target.id = source.id"
).whenMatchedUpdate(set={"target.name": "source.name"}) \
 .whenNotMatchedInsert(values={"id": "source.id", "name": "source.name"}) \
 .execute()

# a third way to do this
targetDF
  .merge(sourceDF, "source.key = target.key")
  .whenMatchedUpdate(
    set = {"target.lastSeen": "source.timestamp"}
  )
  .whenNotMatchedInsert(
    values = {
      "target.key": "source.key",
      "target.lastSeen": "source.timestamp",
      "target.status": "'active'"
    }
  )
  .whenNotMatchedBySourceUpdate(
    condition="target.lastSeen >= (current_date() - INTERVAL '5' DAY)",
    set = {"target.status": "'inactive'"}
  )
  .execute()
)



### Getting the latest version to get the total insert, update and delete count
_commit_timestamp


from delta.tables import DeltaTable

# Get latest version
delta_tbl = DeltaTable.forName(spark, "myDeltaTable")
latest_version = delta_tbl.history(1).select("version").collect()[0][0]

# Read just the latest changes
latest_changes_df = spark.read.format("delta") \
    .option("readChangeFeed", "true") \
    .option("startingVersion", latest_version - 1) \
    .option("endingVersion", latest_version) \
    .table("myDeltaTable")

# Filter and count inserts
insert_count = latest_changes_df.filter("_change_type = 'insert'").count()

print(f"Number of inserts in version {latest_version}: {insert_count}")
