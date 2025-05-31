// Lab - Saving to a table

%scala
df.write.saveAsTable("logdata")

%sql
SELECT * FROM logdata