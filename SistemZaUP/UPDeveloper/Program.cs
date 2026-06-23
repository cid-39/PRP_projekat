using System;
using UPCommon.Connection;
using UPDeveloper.Service;

namespace ApplicationDEV
{
    class Program
    {
        static void Main(string[] args)
        {
            string connectionString = "Server=(localdb)\\MSSQLLocalDB;Database=ProjektniSistem;User Id=ZajednickiKorisnik;Password=SifraZaBazu123!;TrustServerCertificate=True;Pooling=False;";

            DatabaseConnection dbConnection = new DatabaseConnection(connectionString, "DataProviderDEV", "ja_sam_dev");
            DeveloperService devService = new DeveloperService(dbConnection);

            Console.OutputEncoding = System.Text.Encoding.UTF8;

            // Provera konekcije sa DEV akreditivima
            if (!dbConnection.TestConnection())
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("ГРЕШКА: Није могуће повезати се на базу података са ДЕВ акредитивима!");
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
                Console.WriteLine("   СИСТЕМ ЗА УПРАВЉАЊЕ ПРОЈЕКТИМА - ДЕВ МОДУЛ    ");
                Console.WriteLine("==================================================");
                Console.WriteLine("1. Преглед задатака");
                Console.WriteLine("2. Ажурирање статуса задатка");
                Console.WriteLine("0. Излаз из апликације");
                Console.WriteLine("==================================================");
                Console.Write("Изаберите опцију (0-2): ");

                string unos = Console.ReadLine();

                switch (unos)
                {
                    case "1":
                        Console.Clear();
                        devService.PrikaziZadatke();
                        PritisniTasterZaNastavak();
                        break;

                    case "2":
                        Console.Clear();
                        IzvrsiIzmenuStatusa(devService);
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

        // Pomocna metoda za izmenu statusa od strane programera
        static void IzvrsiIzmenuStatusa(DeveloperService devService)
        {
            Console.WriteLine("--- АЖУРИРАЊЕ СТАТУСА ЗАДАТКА ---");

            Console.Write("Унесите ИД задатка: ");
            if (!long.TryParse(Console.ReadLine(), out long idZadatka))
            {
                Console.WriteLine("Неисправан ИД задатка!");
                return;
            }

            Console.WriteLine("Изаберите нови статус:");
            Console.WriteLine("1. ТокуИзради");
            Console.WriteLine("2. Завршено");
            Console.Write("Унос (1-2): ");
            string izborStatusa = Console.ReadLine();

            string noviStatus = "";
            if (izborStatusa == "1") noviStatus = "ТокуИзради";
            else if (izborStatusa == "2") noviStatus = "Завршено";
            else
            {
                Console.WriteLine("Неисправан избор статуса!");
                return;
            }

            devService.AzurirajStatusZadatka(idZadatka, noviStatus);
        }
    }
}