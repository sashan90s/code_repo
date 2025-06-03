

## Databricks Compute Types

There are two kinds of compute in Databricks:
- With Unity Catalog
- Without Unity Catalog

---

## Metastore Overview

- Every Databricks workspace has one metastore by default.
- Previously, each database was tied to a specific workspace (e.g., `db1` to `workspace1`, `db2` to `workspace2`), requiring separate metastores for each workspace.

### With Unity Catalog

- Unity Catalog introduces a single, unified metastore.
- All workspace metastore information is consolidated under one Unity Metastore.
- The Unity Metastore is assigned a central storage container.

---

## Setting Up Unity Catalog

1. **Create a Storage Account and Container**  
    Set up a storage account and create a container inside it.

2. **Create an Access Connector**  
    - Create an Access Connector for Databricks in the same resource group.
    - Go to Storage Account > Access Control > Add > Storage Blob Contributor.
    - Add a role assignment and select members (managed identity). Search for the access connector.

3. **Assign Access Connector to Databricks**  
    - Visit [accounts.azuredatabricks.net/data](https://accounts.azuredatabricks.net/data).
    - Create a catalog and assign the metastore to Databricks workspaces.

---

## Additional Notes

- When you create a cluster, Databricks creates a VM in the backend in your Azure subscription.
- You can create folders in the workspace to organize your notebooks.

> **Workspace folders hold my scripts,  
> Catalogs hold my data bits.**

> **Folders = notebooks and workflows.  
> Catalogs = schemas and tables (my actual data).**

---

## Catalogs and External Data

- Go to **Catalog > External Data > Credentials**.
- Use the access connector you created earlier.
- After that, create an **External Location**.

---

## Managed Tables

- Managed tables are stored in the metastore container attached to your workspace.

---

## Deletion Vectors

- Enable deletion vectors for Delta tables:

```sql
CREATE TABLE <table-name> [options] TBLPROPERTIES ('delta.enableDeletionVectors' = true);

ALTER TABLE <table-name> SET TBLPROPERTIES ('delta.enableDeletionVectors' = true);
```

- View table history:

```sql
DESCRIBE HISTORY my_table;
```

### Use Case: ETL Logging Table for Lakehouse Architecture (OLAP)

You can use a Delta table with deletion vectors enabled for ETL logging or configuration purposes. For example:

```sql
CREATE TABLE etl_logging (
  id STRING,
  job_name STRING,
  status STRING,
  timestamp TIMESTAMP
) TBLPROPERTIES ('delta.enableDeletionVectors' = true);
```

This table can track ETL job runs, statuses, and timestamps, supporting audit and troubleshooting scenarios.

---

## Deep Clone vs Shallow Clone

- **Deep Clone:** Copies both metadata and data at a specific version. Changes to the original table do not affect the cloned table.

```sql
CREATE TABLE man_cata.man_schema.deepclonetbl
DEEP CLONE man_cata.man_schema.deltatbl;
```

- **Shallow Clone:** Only works with managed tables and does not copy data for external tables.

---


## VACCUM

VACCUM YOURTABLENAME;
BY DEAFULT 7 DAYS DATA CAN BE REMOVED FROM THE CACHE LOG.
but now you can change that option manually.

SET spark.databricks.delta.retentionDurationCheck.enabled = false;
VACUUM your_table_name RETAIN 48 HOURS;

## Optimize, Zorder, 


### Optimize and Z-Order in Delta Lake

- **OPTIMIZE:** Compacts small files into larger ones for faster reads.

```sql
OPTIMIZE my_table;
```

- **ZORDER:** Improves data skipping by co-locating related information in the same set of files. Useful for columns often used in filters.

```sql
OPTIMIZE my_table
ZORDER BY (column1, column2);

- Use `ZORDER` on columns that are frequently used in WHERE clauses to speed up queries.

## Liquid Clustering

```sql
-- Create an empty table
CREATE TABLE table1(col0 int, col1 string) CLUSTER BY (col0);
```

```sql
-- Using a CTAS statement
CREATE EXTERNAL TABLE table2 CLUSTER BY (col0)  -- specify clustering after table name, not in subquery
LOCATION 'table_location'
AS SELECT * FROM table1;
```

```sql
-- Using a LIKE statement to copy configurations
CREATE TABLE table3 LIKE table1;
```


##Schema Evolution

-- When writing data, enable schema evolution
ALTER TABLE my_table
SET TBLPROPERTIES ('delta.schema.autoMerge.enabled' = 'true');

-- Now, you can append data with new columns
INSERT INTO my_table
SELECT * FROM another_data_source;


## Delta Live Table

1. Create a Streaming view of Source Data
2. Create a Streaming Table of Streaming View
3. Create Materialized View of Gold Layer

Only the Materialised view will have data read stats at the end, 
becz two tables before only reads delta data meaning append only data..

Another Scene
New DLT Pipeline

Source 1       Strm Table
            >              >  Mat View    > Strm Table
Source 2 >     Strm Table


## Delta Live Table Example: Bronze Streaming Table

Below is an example of a DLT Python pipeline that creates a Bronze streaming table for customer data. This uses the `@dlt.table` decorator to define a streaming table.

```python
import dlt
from pyspark.sql.functions import col

# streaming table - dlt.table + readStream
# Mat View - dlt.tab;e + read
# 
# You cannot create streaming table of Mat View
# streaming table
@dlt.table(
    name="bronze_customers",
    comment="Bronze streaming table for raw customer data."
)
def bronze_customers():
        # Read from a Databricks catalog source table (sample path: catalog.schema.table)
        df = spark.readStream.table("main.bronze.customers")
        return df

@dlt.table(
    name="bronze_customers_new",
    comment="Bronze streaming table for raw customer data."
)
def bronze_customers():
        # Read from a Databricks catalog source table (sample path: catalog.schema.table)
        df = spark.readStream.table("main.bronze.customers_new")
        return df


#Materialized View - silver table

@dlt.table(
    name="silver_customers_union",
    comment="Silver materialized view combining both bronze customer tables."
)
def silver_customers():
    df1 = spark.read.table("LIVE.bronze_customers")
    df2 = spark.read.table("LIVE.bronze_customers_new")
    # Union the two bronze tables and drop duplicates if needed
    df = df1.unionByName(df2)
    return df

# Materialized View - Gold View

@dlt.table(
    name="gold_customers",
    comment="Silver materialized view combining both bronze customer tables."
)
def silver_customers():

    df = spark.read.table("LIVE.silver_customers")
    return df


```

- Replace the path `/mnt/source-data/customers/` with your actual data location.
- This table ingests raw customer data as a streaming source into the Bronze layer.
- You can use this as the first step in your medallion architecture pipeline.



## SCIM Provisioning

(Provide details or steps for SCIM provisioning here.)