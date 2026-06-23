using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class UserDefinedFunctions
{
    // DataAccessKind.Read jer funkcija mora da cita podatke iz tabele
    [Microsoft.SqlServer.Server.SqlFunction(DataAccess = DataAccessKind.Read)]
    public static SqlInt32 FnsKasnjenjeDana(SqlInt32 idZadatka)
    {
        if (idZadatka.IsNull)
        {
            return new SqlInt32(0);
        }

        int kasnjenje = 0;

        using (SqlConnection conn = new SqlConnection("context connection=true"))
        {
            conn.Open();

            string query = "SELECT DatumRoka, StatusZad FROM impl.tblZadatak WHERE Id = @IdZadatka";

            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                cmd.Parameters.Add(new SqlParameter("@IdZadatka", SqlDbType.Int) { Value = idZadatka.Value });

                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        // Proveravamo da li DatumRoka nije NULL u bazi
                        if (!reader.IsDBNull(0))
                        {
                            DateTime datumRoka = reader.GetDateTime(0);
                            string statusZad = reader.GetString(1);

                            if (statusZad != "Завршено" && DateTime.Today > datumRoka)
                            {
                                TimeSpan razlika = DateTime.Today - datumRoka;
                                kasnjenje = razlika.Days;
                            }
                        }
                    }
                }
            }
        }

        return new SqlInt32(kasnjenje);
    }
}