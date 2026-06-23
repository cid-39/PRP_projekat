using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using System.Xml.Linq;
using Microsoft.Data.SqlClient;
using UPCommon.Connection;

namespace UPProjectManager.Service
{
    public class ProjectManagerService
    {
        private readonly DatabaseConnection _dbConnection;

        // Konstruktor prima instancu konekcije sa kojom radi
        public ProjectManagerService(DatabaseConnection dbConnection)
        {
            _dbConnection = dbConnection;
        }

        // 1. Pregled svih zadataka i projekata preko pogleda api_pm.VW_ZADATAK
        public void PrikaziSveZadatkeIProjekte()
        {
            try
            {
                string query = "SELECT * FROM api_pm.VW_ZADATAK";
                DataTable dt = _dbConnection.ExecuteReader(query, CommandType.Text);

                if (dt.Rows.Count == 0)
                {
                    Console.WriteLine("Нема пронађених података о задацима.");
                    return;
                }

                Console.WriteLine("\n--- ПРЕГЛЕД ЗАДАТАКА И ПРОЈЕКАТА ---");
                // Formatiran ispis kolona u konzoli
                Console.WriteLine($"{"ИД",-5} | {"Опис задатка",-30} | {"Рок",-12} | {"Статус",-12} | {"Приоритет",-10} | {"Пројекат",-25} | { "КашњењеДана", -12}");
                Console.WriteLine(new string('-', 105));

                foreach (DataRow row in dt.Rows)
                {
                    string id = row["ZadatakId"].ToString();
                    string opis = row["OpisZadatka"].ToString();
                    string rok = Convert.ToDateTime(row["DatumRoka"]).ToString("dd.MM.yyyy");
                    string status = row["StatusZad"].ToString();
                    string prioritet = row["Prioritet"].ToString();
                    string projekat = row["NazivProjekta"].ToString();
                    string daniKasnjenja = row["KasnjenjeDana"].ToString();

                    Console.WriteLine($"{id,-5} | {opis,-30} | {rok,-12} | {status,-12} | {prioritet,-10} | {projekat,-25} | {daniKasnjenja,-12}");
                }
            }
            catch (SqlException ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Грешка из базе података: {ex.Message}");
                Console.ResetColor();
            }
        }

        // 2. Kreiranje novog zadatka pozivom procedure api_pm.upr_KreirajZadatak
        public void KreirajNoviZadatak(string opis, DateTime datumRoka, int prioritet, long idProjekta)
        {
            try
            {
                SqlParameter[] parameters = new SqlParameter[]
                {
                    new SqlParameter("@Opis", SqlDbType.NVarChar, 500) { Value = opis },
                    new SqlParameter("@DatumRoka", SqlDbType.Date) { Value = datumRoka },
                    new SqlParameter("@Prioritet", SqlDbType.Int) { Value = prioritet },
                    new SqlParameter("@IdProjekta", SqlDbType.BigInt) { Value = idProjekta }
                };

                _dbConnection.ExecuteNonQueryProcedure("api_pm.upr_KreirajZadatak", parameters);

                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("Успешно креиран нови задатак!");
                Console.ResetColor();
            }
            catch (SqlException ex)
            {
                // Ovde se hvataju greske koje baci triger ili procedura (npr. ako rok prekoraci kraj projekta)
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Грешка при креирању задатка: {ex.Message}");
                Console.ResetColor();
            }
        }

        // 3. Dodela clana tima na zadatak pozivom procedure api_pm.upr_DodeliClana
        public void DodeliClanaNaZadatak(long idClana, long idZadatka)
        {
            try
            {
                SqlParameter[] parameters = new SqlParameter[]
                {
                    new SqlParameter("@IdClana", SqlDbType.BigInt) { Value = idClana },
                    new SqlParameter("@IdZadatka", SqlDbType.BigInt) { Value = idZadatka }
                };

                _dbConnection.ExecuteNonQueryProcedure("api_pm.upr_DodeliClana", parameters);

                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("Члан тима је успешно додељен на задатак!");
                Console.ResetColor();
            }
            catch (SqlException ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Грешка при додели члана: {ex.Message}");
                Console.ResetColor();
            }
        }

        // 4. Promena statusa zadatka pozivom procedure api_pm.upr_PromeniStatus
        public void PromeniStatusZadatka(long idZadatka, string noviStatus)
        {
            try
            {
                SqlParameter[] parameters = new SqlParameter[]
                {
                    new SqlParameter("@IdZadatka", SqlDbType.BigInt) { Value = idZadatka },
                    new SqlParameter("@NoviStatus", SqlDbType.NVarChar, 20) { Value = noviStatus }
                };

                _dbConnection.ExecuteNonQueryProcedure("api_pm.upr_PromeniStatus", parameters);

                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("Статус задатка је успешно ажуриран!");
                Console.ResetColor();
            }
            catch (SqlException ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Грешка при измени статуса: {ex.Message}");
                Console.ResetColor();
            }
        }

        // 5. Generisanje i prikaz XML plana projekta iz pogleda api_pm.vw_PLAN_XML
        public void PrikaziXmlPlanProjekta()
        {
            try
            {
                // Posto pogled vraca xml tip, koristimo ExecuteScalar da izvucemo ceo xml kao string
                string query = "SELECT TOP 1 * FROM api_pm.vw_PLAN_XML";
                object result = _dbConnection.ExecuteScalar(query, CommandType.Text);

                if (result == null || result == DBNull.Value)
                {
                    Console.WriteLine("Нема генерисаних података за XML план.");
                    return;
                }

                Console.WriteLine("\n--- ГЕНЕРИСАНИ XML ПЛАН ПРОЈЕКТА ---");
                try
                {
                    XDocument parsedXml = XDocument.Parse(result.ToString());
                    Console.WriteLine(parsedXml.ToString());
                }
                catch (Exception)
                {
                    // Ako iz nekog razloga parsiranje pukne (npr. nevalidan XML), 
                    // ispisujemo sirovi tekst da aplikacija ne bi pala
                    Console.WriteLine(result.ToString());
                }
                Console.WriteLine("------------------------------------\n");
            }
            catch (SqlException ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Грешка при читању XML-а: {ex.Message}");
                Console.ResetColor();
            }
        }

        // 6. Prikaz napredne statistike projekata pozivom funkcije api_pm.VW_STATISTIKA_PROJEKATA
        public void PrikaziStatistikuProjekata()
        {
            try
            {
                string query = "SELECT * FROM api_pm.VW_STATISTIKA_PROJEKATA";
                DataTable dt = _dbConnection.ExecuteReader(query, CommandType.Text);

                if (dt.Rows.Count == 0)
                {
                    Console.WriteLine("Нема доступне статистике за пројекте.");
                    return;
                }

                Console.WriteLine("\n--- НАПРЕДНА СТАТИСТИКА ПРОЈЕКАТА ---");
                Console.WriteLine($"{"Пројекат",-25} | {"Укупно задатака",-16} | {"Завршено",-10} | {"У току",-10} | {"Прекорачено",-12}");
                Console.WriteLine(new string('-', 85));

                foreach (DataRow row in dt.Rows)
                {
                    string naziv = row["ProjekatNaziv"].ToString();
                    string ukupno = row["UkupnoZadataka"].ToString();
                    string zavrseno = row["Zavrseno"].ToString();
                    string uToku = row["UToku"].ToString();
                    string prekoraceno = row["Prekoraceno"].ToString();

                    Console.WriteLine($"{naziv,-25} | {ukupno,-16} | {zavrseno,-10} | {uToku,-10} | {prekoraceno,-12}");
                }
            }
            catch (SqlException ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Грешка при учитавању статистике: {ex.Message}");
                Console.ResetColor();
            }
        }
    }
}