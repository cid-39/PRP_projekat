-- ============================================================================
-- SKRIPTA 4_z9: Registracija CLR sklopa i kreiranje funkcije FnsKasnjenjeDana 
-- ============================================================================
USE [ProjektniSistem];


GO
-- Brisanje objekata ako vec postoje
IF OBJECT_ID('spec.FnsKasnjenjeDana', 'FS') IS NOT NULL
    DROP FUNCTION spec.FnsKasnjenjeDana;

IF EXISTS (SELECT *
           FROM   sys.assemblies
           WHERE  name = 'ProjektniSistemClrAssembly')
    DROP ASSEMBLY ProjektniSistemClrAssembly;


GO
-- 1. OMOGUCAVANJE CLR INTEGRACIJE 
-- ============================================================================
EXECUTE sp_configure 'show advanced options', 1;

RECONFIGURE;

EXECUTE sp_configure 'clr enabled', 1;

RECONFIGURE;


GO
-- Postavljanje baze u TRUSTWORTHY mod kako bi dozvolila SAFE assebly
ALTER DATABASE [ProjektniSistem]
    SET TRUSTWORTHY ON;


GO
-- 2. REGISTRACIJA NET ASSEMBLY U BAZI PODATAKA
-- ============================================================================
CREATE ASSEMBLY ProjektniSistemClrAssembly
    FROM 'C:\Users\Skully\source\repos\SUP_z9\bin\Debug\SUP_z9.dll' -- !!! MENJAJ OVU PUTANJU NA ODBRANI ALOU!!!
    WITH PERMISSION_SET = SAFE;


GO
-- 3. KREIRANJE FUNKCIJE 
-- ============================================================================
CREATE FUNCTION spec.FnsKasnjenjeDana
(@idZadatka INT)
RETURNS INT
WITH EXECUTE AS OWNER   -- zasto se CLR IZVRSAVA SA APPLICATION ROLE-OM?!?!?!?!?!?
AS
 EXTERNAL NAME ProjektniSistemClrAssembly.UserDefinedFunctions.FnsKasnjenjeDana


GO
-- 4. Izmena pogleda
-- ============================================================================
ALTER VIEW spec.vw_ZADATAK
AS
SELECT z.Id AS ZadatakId,
       z.Opis AS OpisZadatka,
       z.DatumRoka,
       z.StatusZad,
       z.Prioritet,
       p.Id AS ProjekatId,
       p.Naziv AS NazivProjekta,
       p.StatusProj,
       c.Ime AS ImeClana,
       -- Dodavanje CLR funkcije
       spec.FnsKasnjenjeDana(z.Id) AS KasnjenjeDana
FROM   impl.tblZadatak AS z
       INNER JOIN
       impl.tblProjekat AS p
       ON z.IdProjekta = p.Id
       LEFT OUTER JOIN
       impl.tblRad AS r
       ON z.Id = r.IdZadatka
       LEFT OUTER JOIN
       impl.tblClan AS c
       ON r.IdClana = c.Id;
GO

ALTER VIEW api_pm.VW_ZADATAK
AS
SELECT * -- ZadatakId, OpisZadatka, DatumRoka, StatusZad, Prioritet, NazivProjekta
FROM   spec.vw_ZADATAK;
GO

ALTER VIEW api_dev.VW_ZADATAK
AS
SELECT * -- ZadatakId, OpisZadatka, DatumRoka, StatusZad, Prioritet, NazivProjekta
FROM   spec.vw_ZADATAK;
GO
-- 4. DODELA PRAVA ROLE-U DataProviderPM
-- ============================================================================
-- GRANT EXECUTE ON spec.FnsKasnjenjeDana TO DataProviderPM;
-- GO
-- 5. TEST
-- ============================================================================
PRINT N'ТЕСТ 1: Провера рада функције са NULL вредношћу (очекује се 0)';

BEGIN TRY
    SELECT spec.FnsKasnjenjeDana(NULL) AS TestNullOk;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 1: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT N'ТЕСТ 2: Провера кашњења за конкретне задатке из базе који нису завршени';

BEGIN TRY
    SELECT Id,
           DatumRoka,
           StatusZad,
           spec.FnsKasnjenjeDana(Id) AS DanaKasnjenja
    FROM   impl.tblZadatak
    WHERE  StatusZad <> N'Завршено';
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 2: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT N'ТЕСТ 3: Симулација и позив funkcije unutar selekta za sve zadatke';

BEGIN TRY
    SELECT Id,
           StatusZad,
           spec.FnsKasnjenjeDana(Id) AS IzracunatoKasnjenje
    FROM   impl.tblZadatak;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 3: ' + ERROR_MESSAGE();
END CATCH