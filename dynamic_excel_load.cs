using System.Data.OleDb;
using System.Data.SqlClient;
using System.IO;

	    string currentdatetime = DateTime.Now.ToString("yyyyMMddHHmmss");
            string LogFolder = @"D:\Files\Logs";

            try
            {
                    string FilePath = @"D:\Files\Email.xlsx";
                    string FileName = Path.GetFileName(FilePath);
                    string TableName = "";
                    TableName = Path.GetFileNameWithoutExtension(FilePath);
                    TableName ="Stg_"+ TableName ;

                    string ConStr;
                    string HDR;
                    HDR = "YES";
                    ConStr = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" + FilePath + ";Extended Properties=\"Excel 12.0;HDR=" + HDR + ";IMEX=1\"";
                    OleDbConnection cnn = new OleDbConnection(ConStr);
                    string sqlconnectionstring = @"data source=DESKTOP-EKJ1P64\SQL2019;initial catalog = School; persist security info = True;Integrated Security = SSPI;";

                    cnn.Open();
                    System.Data.DataTable Sheet = cnn.GetOleDbSchemaTable(OleDbSchemaGuid.Tables, null);
                    string sheetname;
                    sheetname = "";
                    foreach (DataRow DrSheet in Sheet.Rows)
                    {
                        if (DrSheet["TABLE_NAME"].ToString().Contains("$"))
                        {
                            sheetname = DrSheet["TABLE_NAME"].ToString();

                            OleDbCommand oconn = new OleDbCommand("select * from [" + sheetname + "]", cnn);
                            OleDbDataAdapter adp = new OleDbDataAdapter(oconn);
                            System.Data.DataTable dt = new System.Data.DataTable();
                            adp.Fill(dt);

                            sheetname = sheetname.Replace("$", "");

                            string tableDDL = "";
                            tableDDL += "IF EXISTS (SELECT * FROM sys.objects WHERE object_id = ";
                            tableDDL += "OBJECT_ID(N'[dbo].[" + TableName + "]') AND type in (N'U'))";
                            tableDDL += "Drop Table [dbo].[" + TableName + "]";
                            tableDDL += "Create table [" + TableName + "]";
                            tableDDL += "(";
                            for (int i = 0; i < dt.Columns.Count; i++)
                            {
                                if (i != dt.Columns.Count - 1)
                                    tableDDL += "[" + dt.Columns[i].ColumnName + "] " + "NVarchar(max)" + ",";
                                else
                                    tableDDL += "[" + dt.Columns[i].ColumnName + "] " + "NVarchar(max)";
                            }
                            tableDDL += ")";


                            SqlConnection sqlCon = new SqlConnection(sqlconnectionstring);
                            sqlCon.Open();

                            SqlCommand command = new SqlCommand(tableDDL, sqlCon);
                            command.CommandTimeout = 0;
                            command.ExecuteNonQuery();

                            SqlBulkCopy blk = new SqlBulkCopy(sqlCon);
                            blk.DestinationTableName = "[" + TableName + "]";
                            blk.WriteToServer(dt);
                            sqlCon.Close();
                        }
                        break;
                    }
                }
            
            catch (Exception exception)
            {
                using (StreamWriter sw = File.CreateText(LogFolder + "\\" + "ErrorLog_" + currentdatetime + ".log"))
                {
                    sw.WriteLine(exception.ToString());
                }

            }
