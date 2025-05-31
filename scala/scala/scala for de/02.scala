// Lab - Group By and Visualizations

display(df.groupBy(df("Operationname")).count())

%scala

display(df.groupBy(df("Operationname")).
count().alias("Count").
filter(col("Count")>100))

