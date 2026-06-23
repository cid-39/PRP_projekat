-- ============================================================================
-- SKRIPTA 1: Kreiranje baze podataka, shema i aplikacionih uloga
-- ============================================================================
-- Prebacivanje na sistemsku bazu (resava problem sa ponovnim pokretanjem skripte)
USE master;


GO
-- Dodatak: kreiranje sql auth jer to nije isto sto i role lmao?
IF NOT EXISTS (SELECT name
               FROM   sys.server_principals
               WHERE  name = 'ZajednickiKorisnik')
    BEGIN
        CREATE LOGIN ZajednickiKorisnik
            WITH PASSWORD = 'SifraZaBazu123!';
    END


GO
--
-- 1. KREIRANJE BAZE PODATAKA SA ĆIRILIČNOM KOLACIJOM
-- ============================================================================
-- brisanje baze ako postoji
IF EXISTS (SELECT name
           FROM   sys.databases
           WHERE  name = N'ProjektniSistem')
    BEGIN
        ALTER DATABASE [ProjektniSistem]
            SET SINGLE_USER 
            WITH ROLLBACK IMMEDIATE;
        DROP DATABASE [ProjektniSistem];
    END


GO
-- kreiranje baze sa kolacijom
CREATE DATABASE [ProjektniSistem] COLLATE Serbian_Cyrillic_100_CI_AS;


GO
USE [ProjektniSistem];


GO
-- 2. KREIRANJE TROSLOJNE ARHITEKTURE SHEMA
-- ============================================================================
-- impl: Privatna shema za fizicku implementaciju
CREATE SCHEMA impl;


GO
-- spec: Javna shema za specifikaciju
CREATE SCHEMA spec;


GO
-- api_pm: Klijentska shema za PM
CREATE SCHEMA api_pm;


GO
-- api_dev: Klijentska shema za DEV
CREATE SCHEMA api_dev;


GO
-- 3. KREIRANJE ULOGA
-- ============================================================================
-- Kreiranje uloge za Project Manager interfejs uz originalnu lozinku
CREATE APPLICATION ROLE DataProviderPM
    WITH PASSWORD = 'ja_sam_pm';


GO
-- Kreiranje uloge za Developer interfejs uz originalniju lozinku
CREATE APPLICATION ROLE DataProviderDEV
    WITH PASSWORD = 'ja_sam_dev';


GO
-- Drugi deo dodatka
CREATE USER ZajednickiKorisnikUser FOR LOGIN ZajednickiKorisnik;

GRANT CONNECT TO ZajednickiKorisnikUser;


GO
--
-- 4. KONTROLA PRISTUPA I ENKAPSULACIJA (DODELA PRAVA NAD SHEMAMA)
-- ============================================================================
-- DataProviderPM dobija puni pristup svojoj API shemi (citanje plana, XML eksport, itd)
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE
    ON SCHEMA::api_pm TO DataProviderPM;


GO
-- DataProviderDEV dobija pristup svojoj API shemi (pregled dodeljenih zadataka, promena statusa)
GRANT SELECT, EXECUTE
    ON SCHEMA::api_dev TO DataProviderDEV;


GO
PRINT 'Skripta 1 je usepsno izvsena. Baza, sheme i uloge su kreirane.';