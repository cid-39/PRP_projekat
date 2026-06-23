-- ============================================================================
-- SKRIPTA 3: Unos demo podataka sa verifikacionim testovima
-- ============================================================================
USE [ProjektniSistem];


GO
-- 1. UNOS DEMO PODATAKA
-- ============================================================================
-- Brisanje prethodnih podataka unazad zbog radi ReFeReCnIjAlNi InTeGrItEt
DELETE impl.tblRad;

DELETE impl.tblZadatak;

DELETE impl.tblClan;

DELETE impl.tblProjekat;


GO
IF IDENT_CURRENT('impl.tblProjekat') > 1
    DBCC CHECKIDENT ('impl.tblProjekat', RESEED, 0);

IF IDENT_CURRENT('impl.tblZadatak') > 1
    DBCC CHECKIDENT ('impl.tblZadatak', RESEED, 0);

IF IDENT_CURRENT('impl.tblClan') > 1
    DBCC CHECKIDENT ('impl.tblClan', RESEED, 0);

PRINT 'Prethodni podaci iz tabela obrisani.'; -- A. Unos u tabelu Projekat 

INSERT  INTO impl.tblProjekat (Naziv, DatumPocetka, DatumZavrsetka, StatusProj)
VALUES                       (N'ERP Систем', '2024-01-15', '2025-06-30', N'Активан'),
(N'Мобилна апликација', '2024-06-01', NULL, N'Активан'),
(N'Портал за клијенте', '2023-03-01', '2024-12-31', N'Завршен');


GO
-- B. Unos u tabelu Zadatak 
INSERT  INTO impl.tblZadatak (IdProjekta, Opis, DatumRoka, StatusZad, Prioritet)
VALUES                      (1, N'Анализа захтева', '2024-02-28', N'Завршено', 1),
(1, N'Дизајн базе података', '2024-04-30', N'Завршено', 1),
(1, N'Backend API', '2025-03-31', N'ТокуИзради', 2),
(2, N'UI прототип', '2024-09-30', N'Завршено', 1),
(2, N'Интеграција АΡΙ', '2025-05-31', N'ТокуИзради', 2);


GO
-- C. Unos u tabelu Clan
INSERT  INTO impl.tblClan (Ime, Uloga)
VALUES                   (N'Марко Петровић', N'Backend Developer'),
(N'Ана Николић', N'Frontend Developer'),
(N'Стефан Јовановић', N'Project Manager');


GO
-- D. Unos u tabelu Rad
INSERT  INTO impl.tblRad (IdClana, IdZadatka, DatumDodeljivan)
VALUES                  (3, 1, '2024-01-16'),
(1, 2, '2024-03-01'),
(1, 3, '2024-05-01'),
(2, 4, '2024-06-15'),
(2, 5, '2024-10-01');


GO
-- 2. VERIFIKACIONI PRIKAZI
-- ============================================================================
SELECT Naziv,
       DatumPocetka,
       DatumZavrsetka,
       StatusProj
FROM   impl.tblProjekat;

SELECT IdProjekta,
       Opis,
       DatumRoka,
       StatusZad,
       Prioritet
FROM   impl.tblZadatak;

SELECT Ime,
       Uloga
FROM   impl.tblClan;

PRINT 'Skripta 3 je uspesno izvrsena. Demo podaci su ubaceni i prikazani.';