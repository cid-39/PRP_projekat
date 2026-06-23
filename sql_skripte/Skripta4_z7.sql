-- ============================================================================
-- SKRIPTA 4_z7: Generisanje XML projektnog plana i kreiranje API pogleda
-- ============================================================================
USE [ProjektniSistem];


GO
-- Brisanje pogleda ako vec postoji
IF OBJECT_ID('spec.vw_PLAN_XML', 'V') IS NOT NULL
    DROP VIEW spec.vw_PLAN_XML;


GO
-- 1. KREIRANJE POGLEDA: spec.vw_PLAN_XML 
-- ============================================================================
-- kreiramo ga u spec nasuprot dokumentaciji (jer mislim da je greska?)
CREATE VIEW spec.vw_PLAN_XML
WITH ENCRYPTION
AS
SELECT (SELECT p.Id AS [@Id],
               p.Naziv AS [Naziv],
               p.DatumPocetka AS [DatumPocetka],
               p.DatumZavrsetka AS [DatumZavrsetka],
               p.StatusProj AS [Status],
               (-- Podupit za ugnjezdeni XML sa zadacima projekta
                SELECT z.Id AS [@Id],
                       z.Opis AS [Opis],
                       z.DatumRoka AS [DatumRoka],
                       z.StatusZad AS [Status],
                       z.Prioritet AS [Prioritet],
                       (-- Podupit za u-ugnjezdeni XML sa clanovima na zadatku
                        SELECT c.Id AS [@Id],
                               c.Ime AS [Ime],
                               c.Uloga AS [Uloga],
                               r.DatumDodeljivan AS [DatumDodele]
                        FROM   impl.tblRad AS r
                               INNER JOIN
                               impl.tblClan AS c
                               ON r.IdClana = c.Id
                        WHERE  r.IdZadatka = z.Id
                        FOR    XML PATH ('Clan'), TYPE) AS [Clanovi]
                FROM   impl.tblZadatak AS z
                WHERE  z.IdProjekta = p.Id
                FOR    XML PATH ('Zadatak'), TYPE) AS [Zadaci]
        FROM   impl.tblProjekat AS p
        FOR    XML PATH ('Projekat'), ROOT ('ProjektniPlan'), TYPE) AS [ProjektniPlan]; -- oce xml da ima naziv kolone pa to ti je


GO
-- 2. KREIRANJE POGLEDA: api_pm.VW_PLAN_XML
-- ============================================================================
CREATE VIEW api_pm.VW_PLAN_XML
AS
SELECT [ProjektniPlan]
FROM   spec.vw_PLAN_XML;


GO
-- 3. Dodela prava role-u DataProviderPM
-- ============================================================================
GRANT SELECT
    ON api_pm.VW_PLAN_XML TO DataProviderPM;


GO
-- 4. TEST
-- ============================================================================
PRINT N'ТЕСТ 1: Провера читања и структуре XML-а из погледа VW_PLAN_XML';

BEGIN TRY
    SELECT *
    FROM   api_pm.VW_PLAN_XML;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 1: ' + ERROR_MESSAGE();
END CATCH