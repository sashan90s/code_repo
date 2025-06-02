# How to use this code to bring in or update data of the latest dropped files in Azure ADLS Gen 2

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp, input_file_name
from pyspark.sql.types import (
    StructType, StructField,
    StringType, DateType, IntegerType,
    TimestampType, DoubleType
)
from delta.tables import DeltaTable
import os

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
merge_condition = "existing.uid = updates.uid"

update_condition = "updates.record_status = 'C' AND updates.extract_timestamp >= existing.extract_timestamp"

delete_condition = "updates.record_status = 'D' AND updates.extract_timestamp >= existing.extract_timestamp"

insert_condition = "updates.record_status = 'A'"

# Assuming delta_table is already defined as a DeltaTable and df is your incoming DataFrame
delta_table.alias("existing").merge(
    source=df.alias("updates"),
    condition=merge_condition
).whenMatchedUpdateAll(
    condition=update_condition
).whenMatchedDelete(
    condition=delete_condition
).whenNotMatchedInsertAll(
    condition=insert_condition
).execute()
