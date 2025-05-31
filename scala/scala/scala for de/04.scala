// Lab - Filtering on NULL values

import org.apache.spark.sql.functions._
val dfNull=df.filter(col("Resourcegroup").isNull)
dfNull.count()


val dfNotNull=df.filter(col("Resourcegroup").isNotNull)
dfNotNull.count()
