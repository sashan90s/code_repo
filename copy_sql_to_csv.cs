using System;
using System.Data;
using Microsoft.SqlServer.Dts.Runtime;
using System.Windows.Forms;
using System.Data.SqlClient;
using System.IO;

public void Main()
		{
            // TODO: Add your code here

            ExportData();

            Dts.TaskResult = (int)ScriptResults.Success;
		}

 private static void ExportData()
        {

            string connectionString = @"Server = DESKTOP-EKJ1P64\SQL2019; Database = Work; Trusted_Connection = True; ";
            SqlConnection sqlCon = new SqlConnection(connectionString);
            sqlCon.Open();

            SqlCommand sqlCmd = new SqlCommand(@"SELECT * FROM [Customer]", sqlCon);
            SqlDataReader reader = sqlCmd.ExecuteReader();

            string fileName = @"D:\Files\Export_Customer.csv";
            StreamWriter sw = new StreamWriter(fileName);
            object[] output = new object[reader.FieldCount];

            for (int i = 0; i < reader.FieldCount; i++)
                output[i] = reader.GetName(i);

            sw.WriteLine(string.Join("|", output));

            while (reader.Read())
            {
                reader.GetValues(output);
                sw.WriteLine(string.Join("|", output));
            }

            sw.Close();
            reader.Close();
            sqlCon.Close();

        }
