

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

## SCIM Provisioning

(Provide details or steps for SCIM provisioning here.)