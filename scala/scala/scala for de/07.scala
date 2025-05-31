// Lab - JSON-based files

val dfjson = spark.read.format("json").load("/FileStore/tables/json/customer_arr.json")

// Here you will see the array elements are being shown as one data item
display(dfjson)

// Use the explode function

val newjson=dfjson.select(col("customerid"),col("customername"),col("registered"),explode(col("courses")))

display(newjson)

val dfobj = spark.read.format("json").load("/FileStore/tables/json/customer_obj.json")
// Here we are showing how to access elements of a nested JSON object
display(dfobj.select(col("customerid"),col("customername"),col("registered"),(col("details.city")),(col("details.mobile")),explode(col("courses")).alias("Courses")))
