// Lab - Spark Pool - Starting out with Notebooks

val dataValues = Array(20, 34, 44, 23, 34)
val dataSet = sc.parallelize(dataValues)

val maxValue=dataSet.max
maxValue