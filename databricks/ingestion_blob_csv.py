# ============================================================
# This document is used for ingestion of csv files from Azure Blob Storage
# Coder: Sibbir Sihan
# Date: 2024-06
# ============================================================

from azure.storage.blob import BlobServiceClient
from pyspark.sql.utils import AnalysisException

# ============================================================
# Helper functions (not user-facing)
# ============================================================

def _list_timestamp_folders(container, SourceDirectory="process/"):
    folders = set()
    for b in container.list_blobs(name_starts_with=SourceDirectory):
        parts = b.name.split("/")
        if "Archive" not in parts and "Holding" not in parts:     # Holding is used to hold files by data engineers manually                                                         # fix this later
            folders.add(parts[-2]) # second last part is the folder name which will return timestamp folders
    return sorted(list(folders))


def _list_files(container, prefix):
    return [
        b.name for b in container.list_blobs(name_starts_with=prefix)
        if b.name.lower().endswith(".csv")
    ]


def _archive_one(container, src_path):
    dest_path = src_path.replace("process/", "process/archive/", 1)
    print(f"Archiving {src_path} → {dest_path}")

    src = container.get_blob_client(src_path)
    dest = container.get_blob_client(dest_path)

    dest.start_copy_from_url(src.url)
    src.delete_blob()


def _process_one_file(spark, catalog, target_table, container_name, storage_account, blob_path):
    print(f"Processing file: {blob_path}")

    try:
        df = spark.read.csv(
            f"abfss://{container_name}@{storage_account}.dfs.core.windows.net/{blob_path}",
            header=True
        )
    except Exception as e:
        raise Exception(f"NOOO: Failed reading CSV {blob_path}: {e}")

    try:
        staging_table = f"{catalog}.stg.{target_table}"
        df.write.format("delta").mode("overwrite").saveAsTable(staging_table)
    except Exception as e:
        raise Exception(f"NOOO: Failed writing Delta table {staging_table}: {e}")

    print(f"OK: Successfully processed {blob_path}")


# ============================================================
# MAIN PUBLIC FUNCTION
# ============================================================

def run_ingestion_blob(spark, LoadDefinitionKey, storage_account, container_name, sas_token, catalog, target_table):
    """
    Main ingestion entry point.
    Controlled ingestion supporting:
    - SubFolder mode (timestamped folders)
    - Flat mode (direct files)
    - Strict sequential file-by-file processing
    - Immediate archiving per successful file
    - Stops if any file of blob container directory fails in sequential order
    """

    # Connect to Blob
    container = BlobServiceClient(
        account_url=f"https://{storage_account}.blob.core.windows.net",
        credential=sas_token
    ).get_container_client(container_name)

    # Fetch LoadDefinition config
    cfg = spark.sql(f"""
        SELECT SubFolder, ArchiveFiles
        FROM {catalog}.admin.LoadDefinition
        WHERE LoadDefinitionKey = {LoadDefinitionKey}
    """).collect()[0]

    SUBFOLDER  = cfg["SubFolder"] == 1
    ARCHIVE    = cfg["ArchiveFiles"] == 1
    SOURCEDIRECTORY = cfg["SourceDirectory"]


    print(f"Config → SubFolder={SUBFOLDER}, ArchiveFiles={ARCHIVE}")

    # --------------------------------------------------------
    # MODE 1: TIMESTAMPED FOLDERS
    # --------------------------------------------------------
    if SUBFOLDER:
        print("FOLDER Using TIMESTAMPED subfolders")

        folders = _list_timestamp_folders(container, SOURCEDIRECTORY)
        print(f"Found folders: {folders}")

        # Process folders IN ORDER until first failure
        for folder in folders:
            print(f"\n Processing folder: {folder}")

            files = _list_files(container, f"{SOURCEDIRECTORY}/{folder}/")
            print(f"Files: {files}")

            for blob_path in files:
                try:
                    _process_one_file(spark, catalog, target_table, container_name, storage_account, blob_path)

                    if ARCHIVE:
                        _archive_one(container, blob_path)

                except Exception as e:
                    print(f"Nooo ERROR: {e}")
                    print("Nooo STOPPING ingestion — not moving to next folder.")
                    raise e

            print(f"OK: Completed folder: {folder}")
        print("Amazing Sihan: All timestamp folders processed")
        return

    # --------------------------------------------------------
    # MODE 2: FLAT FILES
    # --------------------------------------------------------
    else:
        print("Single File:Using FLAT folder structure")

        files = _list_files(container, "process/")
        print(f"Files: {files}")

        for blob_path in files:
            try:
                _process_one_file(spark, catalog, target_table, container_name, storage_account, blob_path)

                if ARCHIVE:
                    _archive_one(container, blob_path)

            except Exception as e:
                print(f"Nooo ERROR: {e}")
                print("Nooo STOPPING ingestion.")
                raise e

        print("Amazing Sihan All flat files processed")
