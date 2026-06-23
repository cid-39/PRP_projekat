-- ============================================================================
-- SKRIPTA 4_z11: Running Total za zavrsene zadatke
-- ============================================================================
USE [ProjektniSistem];


GO
-- Brisanje procedure ako vec postoji
IF OBJECT_ID('api_pm.uprTekuciZbirZavrsenihZadataka', 'P') IS NOT NULL
    DROP PROCEDURE api_pm.uprTekuciZbirZavrsenihZadataka;


GO
IF OBJECT_ID('spec.uprTekuciZbirZavrsenihZadataka', 'P') IS NOT NULL
    DROP PROCEDURE spec.uprTekuciZbirZavrsenihZadataka;


GO
-- 1. KREIRANJE PROCEDURE: spec.uprTekuciZbirZavrsenihZadataka
-- ============================================================================
CREATE PROCEDURE spec.uprTekuciZbirZavrsenihZadataka
@idProjekta INT=NULL
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Selektovanje podataka sa kumulativnom sumom
        SELECT p.Naziv AS [ProjekatNaziv],
               z.Id AS [ZadatakId],
               z.Opis AS [ZadatakOpis],
               z.DatumRoka AS [DatumRoka],
               z.StatusZad AS [ZadatakStatus],
               -- SUM malo nema smisla ovde primeniti, COUNT je logicniji?
        COUNT(z.Id) OVER (PARTITION BY z.IdProjekta ORDER BY z.DatumRoka ASC, z.Id ASC ROWS UNBOUNDED PRECEDING) AS [TekuciZbirZavrsenih]
        FROM   impl.tblZadatak AS z
               INNER JOIN
               impl.tblProjekat AS p
               ON z.IdProjekta = p.Id
        WHERE  z.StatusZad = N'Завршено'
               AND (@idProjekta IS NULL
                    OR z.IdProjekta = @idProjekta);
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
-- 2. WRAPPER I DODELA PRAVA ROLE-U DataProviderPM
-- ============================================================================
CREATE PROCEDURE api_pm.uprTekuciZbirZavrsenihZadataka
@idProjekta INT=NULL
AS
BEGIN
    BEGIN TRY
        EXECUTE spec.uprTekuciZbirZavrsenihZadataka @idProjekta = @idProjekta;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
GRANT EXECUTE
    ON api_pm.uprTekuciZbirZavrsenihZadataka TO DataProviderPM;


GO
-- 3. TESTIRANJE
-- ============================================================================
PRINT N'ТЕСТ 1: Приказ текућег збира завршених задатака за све пројекте';

BEGIN TRY
    EXECUTE api_pm.uprTekuciZbirZavrsenihZadataka @idProjekta = NULL;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 1: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT N'ТЕСТ 2: Приказ текућег збира искључиво за Пројекат са ИД = 1';

BEGIN TRY
    EXECUTE api_pm.uprTekuciZbirZavrsenihZadataka @idProjekta = 1;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 2: ' + ERROR_MESSAGE();
END CATCH