# Azure Synapse link

 df = spark.read \
    .format("cosmos.olap") \
    .option("spark.synapse.linkedService", "appaccount355353") \
    .option("spark.cosmos.container", "orders") \
    .load()

display(df)


