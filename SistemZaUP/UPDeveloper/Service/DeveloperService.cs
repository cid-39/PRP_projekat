using Microsoft.Data.SqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using UPCommon.Connection;

namespace UPDeveloper.Service
{
    public class DeveloperService
    {
        private readonly DatabaseConnection _dbConnection;

        // Konstruktor prima instancu konekcije
        public DeveloperService(DatabaseConnection dbConnection)
        {
            _dbConnection = dbConnection;
        }

        // 1. Pregled zadataka preko pogleda api_dev.VW_ZADATAK
        public void PrikaziZadatke()
        {
            try
            {
                string query = "SELECT * FROM api_dev.VW_ZADATAK";
                DataTable dt = _dbConnection.ExecuteReader(query, CommandType.Text);

                if (dt.Rows.Count == 0)
                {
                    Console.WriteLine("Нема додељених задатака за приказ.");
                    return;
                }

                Console.WriteLine("\n--- ПРЕГЛЕД ДОДЕЛЈЕНИХ ЗАДАТАКА ---");
                Console.WriteLine($"{"ИД",-5} | {"Опис задатка",-35} | {"Рок",-12} | {"Статус",-12} | {"Приоритет",-10} | {"КашњењеДана",-12}");
                Console.WriteLine(new string('-', 85));

                foreach (DataRow row in dt.Rows)
                {
                    string id = row["ZadatakId"].ToString();
                    string opis = row["OpisZadatka"].ToString();
                    string rok = Convert.ToDateTime(row["DatumRoka"]).ToString("dd.MM.yyyy");
                    string status = row["StatusZad"].ToString();
                    string prioritet = row["Prioritet"].ToString();
                    string daniKasnjenja = row["KasnjenjeDana"].ToString();

                    Console.WriteLine($"{id,-5} | {opis,-35} | {rok,-12} | {status,-12} | {prioritet,-10} | {daniKasnjenja,-12}");
                }
            }
            catch (SqlException ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Грешка при учитавању задатака: {ex.Message}");
                Console.ResetColor();
            }
        }

        // 2. Azuriranje statusa zadatka pozivom procedure api_dev.upr_PromeniStatus
        public void AzurirajStatusZadatka(long idZadatka, string noviStatus)
        {
            try
            {
                SqlParameter[] parameters = new SqlParameter[]
                {
                    new SqlParameter("@IdZadatka", SqlDbType.BigInt) { Value = idZadatka },
                    new SqlParameter("@NoviStatus", SqlDbType.NVarChar, 20) { Value = noviStatus }
                };

                _dbConnection.ExecuteNonQueryProcedure("api_dev.upr_PromeniStatus", parameters);

                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("Статус задатка је успешно промењен!");
                Console.ResetColor();
            }
            catch (SqlException ex)
            {
                // Ovde hvatamo greske ako programer pokusa da postavi nedozvoljen status
                // ili ako procedura proveri neko poslovno pravilo koje je prekrseno
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Грешка при промени статуса: {ex.Message}");
                Console.ResetColor();
            }
        }
    }
}