using System.Globalization;
using UPCommon.Connection;
using UPProjectManager.Service;

namespace ApplicationPM
{
    class Program
    {
        static void Main(string[] args)
        {
            string connectionString = "Server=(localdb)\\MSSQLLocalDB;Database=ProjektniSistem;User Id=ZajednickiKorisnik;Password=SifraZaBazu123!;TrustServerCertificate=True;Pooling=False;";

            DatabaseConnection dbConnection = new DatabaseConnection(connectionString, "DataProviderPM", "ja_sam_pm");
            ProjectManagerService pmService = new ProjectManagerService(dbConnection);

            Console.OutputEncoding = System.Text.Encoding.UTF8;

            // Provera konekcije na samom pocetku
            if (!dbConnection.TestConnection())
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("ГРЕШКА: Није могуће повезати се на базу података!");
                Console.ResetColor();
                Console.WriteLine("Притисните било који тастер за излаз...");
                Console.ReadKey();
                return;
            }

            bool kraj = false;
            while (!kraj)
            {
                Console.Clear();
                Console.WriteLine("==================================================");
                Console.WriteLine("   СИСТЕМ ЗА УПРАВЉАЊЕ ПРОЈЕКТИМА - ПМ АПЛИКАЦИЈА     ");
                Console.WriteLine("==================================================");
                Console.WriteLine("1. Преглед свих задатака и пројеката");
                Console.WriteLine("2. Креирање новог задатка");
                Console.WriteLine("3. Додела члана тима на задатак");
                Console.WriteLine("4. Промена статуса задатка");
                Console.WriteLine("5. Генерисање и приказ XML плана пројекта");
                Console.WriteLine("6. Приказ напредне статистике пројеката");
                Console.WriteLine("0. Излаз из апликације");
                Console.WriteLine("==================================================");
                Console.Write("Изаберите опцију (0-6): ");

                string unos = Console.ReadLine();

                switch (unos)
                {
                    case "1":
                        Console.Clear();
                        pmService.PrikaziSveZadatkeIProjekte();
                        PritisniTasterZaNastavak();
                        break;

                    case "2":
                        Console.Clear();
                        IzvrsiUnosNovogZadatka(pmService);
                        PritisniTasterZaNastavak();
                        break;

                    case "3":
                        Console.Clear();
                        IzvrsiDodeluClana(pmService);
                        PritisniTasterZaNastavak();
                        break;

                    case "4":
                        Console.Clear();
                        IzvrsiIzmenuStatusa(pmService);
                        PritisniTasterZaNastavak();
                        break;

                    case "5":
                        Console.Clear();
                        pmService.PrikaziXmlPlanProjekta();
                        PritisniTasterZaNastavak();
                        break;

                    case "6":
                        Console.Clear();
                        pmService.PrikaziStatistikuProjekata();
                        PritisniTasterZaNastavak();
                        break;

                    case "0":
                        kraj = true;
                        Console.WriteLine("\nХвала на коришћењу апликације. Пријатан дан!");
                        break;

                    default:
                        Console.ForegroundColor = ConsoleColor.Yellow;
                        Console.WriteLine("\nНеисправна опција! Покушајте поново.");
                        Console.ResetColor();
                        PritisniTasterZaNastavak();
                        break;
                }
            }
        }

        // Pomocna metoda za pauziranje ekrana
        static void PritisniTasterZaNastavak()
        {
            Console.WriteLine("\nПритисните било који тастер за повратак на мени...");
            Console.ReadKey();
        }

        // Pomocna metoda za unos i validaciju podataka za novi zadatak
        static void IzvrsiUnosNovogZadatka(ProjectManagerService pmService)
        {
            Console.WriteLine("--- КРЕИРАЊЕ НОВОГ ЗАДАТКА ---");

            Console.Write("Унесите опис задатка: ");
            string opis = Console.ReadLine();
            if (string.IsNullOrWhiteSpace(opis))
            {
                Console.WriteLine("Опис не сме бити празан!");
                return;
            }

            Console.Write("Унесите рок за задатак (формат DD.MM.YYYY): ");
            if (!DateTime.TryParseExact(Console.ReadLine(), "dd.MM.yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTime datumRoka))
            {
                Console.WriteLine("Неисправан формат датума!");
                return;
            }

            Console.Write("Унесите приоритет задатка (1-5): ");
            if (!int.TryParse(Console.ReadLine(), out int prioritet) || prioritet < 1 || prioritet > 5)
            {
                Console.WriteLine("Приоритет мора бити цео број између 1 и 5!");
                return;
            }

            Console.Write("Унесите ИД пројекта коме задатак припада: ");
            if (!long.TryParse(Console.ReadLine(), out long idProjekta))
            {
                Console.WriteLine("Неисправан ИД пројекта!");
                return;
            }

            pmService.KreirajNoviZadatak(opis, datumRoka, prioritet, idProjekta);
        }

        // Pomocna metoda za dodelu clana tima na zadatak
        static void IzvrsiDodeluClana(ProjectManagerService pmService)
        {
            Console.WriteLine("--- ДОДЕЛА ЧЛАНА ТИМА НА ЗАДАТАК ---");

            Console.Write("Унесите ИД члана тима: ");
            if (!long.TryParse(Console.ReadLine(), out long idClana))
            {
                Console.WriteLine("Неисправан ИД члана!");
                return;
            }

            Console.Write("Унесите ИД задатка: ");
            if (!long.TryParse(Console.ReadLine(), out long idZadatka))
            {
                Console.WriteLine("Неисправан ИД задатка!");
                return;
            }

            pmService.DodeliClanaNaZadatak(idClana, idZadatka);
        }

        // Pomocna metoda za izmenu statusa zadatka
        static void IzvrsiIzmenuStatusa(ProjectManagerService pmService)
        {
            Console.WriteLine("--- ИЗМЕНА СТАТУСА ЗАДАТКА ---");

            Console.Write("Унесите ИД задатка: ");
            if (!long.TryParse(Console.ReadLine(), out long idZadatka))
            {
                Console.WriteLine("Неисправан ИД задатка!");
                return;
            }

            Console.WriteLine("Изаберите нови статус:");
            Console.WriteLine("1. Ново");
            Console.WriteLine("2. ТокуИзради");
            Console.WriteLine("3. Завршено");
            Console.Write("Унос (1-3): ");
            string izborStatusa = Console.ReadLine();

            string noviStatus = "";
            if (izborStatusa == "1") noviStatus = "Ново";
            else if (izborStatusa == "2") noviStatus = "ТокуИзради";
            else if (izborStatusa == "3") noviStatus = "Завршено";
            else
            {
                Console.WriteLine("Неисправан избор статуса!");
                return;
            }

            pmService.PromeniStatusZadatka(idZadatka, noviStatus);
        }
    }
}