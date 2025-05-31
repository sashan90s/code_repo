
// Lab - Streaming from Azure Event Hub - Implementation

import org.apache.spark.eventhubs._

val eventHubConnectionString = ConnectionStringBuilder("Endpoint=sb://datanamespace55343.servicebus.windows.net/;SharedAccessKeyName=webhub-policy;SharedAccessKey=xcwTuzrbApc0MQcO0GntgndQv1FZRiGTp+AEhMqjkpw=;EntityPath=webhub")
  .build

val eventHubConfiguration = EventHubsConf(eventHubConnectionString)  

var webhubDF = 
  spark.readStream
    .format("eventhubs")
    .options(eventHubConfiguration.toMap)
    .load()
  
  
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

val recordsDF=webhubDF
.select(get_json_object(($"body").cast("string"), "$.records").alias("records"))

val maxMetrics = 30 
val jsonElements = (0 until maxMetrics)
                     .map(i => get_json_object($"records", s"$$[$i]"))

val  expandedDF= recordsDF
  .withColumn("records", explode(array(jsonElements: _*))) 
  .where(!isnull($"records")) 

val dataSchema = new StructType()
        .add("count", LongType)
        .add("total", LongType)
        .add("minimum", LongType)
        .add("maximum", LongType)
        .add("resourceId", StringType)
        .add("time", DataTypes.DateType)
        .add("metricName", StringType)
        .add("timeGrain", StringType)
        .add("average", LongType)

val jsondf=expandedDF.withColumn("records",from_json(col("records"),dataSchema))

val finalDF=jsondf.select(col("records.*"))

display(finalDF)
