-- ============================================================================
-- SKRIPTA 4_z10: Rangiranje zadataka pomocu ROW_NUMBER() i RANK() funkcija
-- ============================================================================
USE [ProjektniSistem];


GO
-- Brisanje procedure ako vec postoji
IF OBJECT_ID('api_pm.uprRangiranjeZadatakaPoPrioritetu', 'P') IS NOT NULL
    DROP PROCEDURE api_pm.uprRangiranjeZadatakaPoPrioritetu;


GO
IF OBJECT_ID('spec.uprRangiranjeZadatakaPoPrioritetu', 'P') IS NOT NULL
    DROP PROCEDURE spec.uprRangiranjeZadatakaPoPrioritetu;


GO
-- 1. KREIRANJE PROCEDURE: spec.uprRangiranjeZadatakaPoPrioritetu
-- ============================================================================
CREATE PROCEDURE spec.uprRangiranjeZadatakaPoPrioritetu
@idProjekta INT=NULL -- opcioni param zbog radi ne znam eto
WITH ENCRYPTION
AS
BEGIN
    BEGIN TRY
        SELECT p.Naziv AS [ProjekatNaziv],
               z.Id AS [ZadatakId],
               z.Opis AS [ZadatakOpis],
               z.Prioritet AS [ZadatakPrioritet],
               z.StatusZad AS [ZadatakStatus],
               -- ROW_NUMBER dodeljuje strogo linearan redni broj unutar projekta
        ROW_NUMBER() OVER (PARTITION BY z.IdProjekta ORDER BY z.Prioritet ASC, z.Id ASC) AS [RowNumberUnutarProjekta],
               -- RANK prepoznaje deljenje mesta za identicne prioritete i preskace pozicije
        RANK() OVER (PARTITION BY z.IdProjekta ORDER BY z.Prioritet ASC) AS [RankUnutarProjekta]
        FROM   impl.tblZadatak AS z
               INNER JOIN
               impl.tblProjekat AS p
               ON z.IdProjekta = p.Id
        WHERE  (@idProjekta IS NULL
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
CREATE PROCEDURE api_pm.uprRangiranjeZadatakaPoPrioritetu
@idProjekta INT=NULL
AS
BEGIN
    BEGIN TRY
        EXECUTE spec.uprRangiranjeZadatakaPoPrioritetu @idProjekta = @idProjekta;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
GRANT EXECUTE
    ON api_pm.uprRangiranjeZadatakaPoPrioritetu TO DataProviderPM;


GO
-- 3. TESTIRANJE
-- ============================================================================
PRINT N'ТЕСТ 1: Приказ и рангирање задатака за све пројекте (Параметар је NULL)';

BEGIN TRY
    EXECUTE api_pm.uprRangiranjeZadatakaPoPrioritetu @idProjekta = NULL;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 1: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT N'ТЕСТ 2: Приказ и рангирање задатака искључиво за Пројекат са ИД = 1';

BEGIN TRY
    EXECUTE api_pm.uprRangiranjeZadatakaPoPrioritetu @idProjekta = 1;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 2: ' + ERROR_MESSAGE();
END CATCH