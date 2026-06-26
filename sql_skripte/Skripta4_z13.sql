-- ============================================================================
-- SKRIPTA 4_z13: Inline TVF i CROSS APPLY za aktivne clanove projekta
-- ============================================================================
USE [ProjektniSistem];


GO
-- Brisanje objekata ako vec postoje
IF OBJECT_ID('spec.fnt_AktivniClanovi', 'IF') IS NOT NULL
    DROP FUNCTION spec.fnt_AktivniClanovi;


GO
IF OBJECT_ID('api_pm.uprPrikazAktivnihClanovaPoProjektu', 'P') IS NOT NULL
    DROP PROCEDURE api_pm.uprPrikazAktivnihClanovaPoProjektu;


GO
-- 1. KREIRANJE INLINE TVF: spec.fnt_AktivniClanovi
-- ============================================================================
-- Funkcija vraca clanove koji rade na zadacima zadatog projekta, a koji nisu zavrseni
CREATE FUNCTION spec.fnt_AktivniClanovi
(@idProjekta INT)
RETURNS TABLE 
WITH ENCRYPTION
AS
RETURN 
    (SELECT DISTINCT c.Id AS [ClanId],
                     c.Ime AS [ClanIme],
                     c.Uloga AS [ClanUloga]
     FROM   impl.tblClan AS c
            INNER JOIN
            impl.tblRad AS r
            ON c.Id = r.IdClana
            INNER JOIN
            impl.tblZadatak AS z
            ON r.IdZadatka = z.Id
     WHERE  z.IdProjekta = @idProjekta
            AND z.StatusZad IN (N'Ново', N'ТокуИзради'))



GO
-- 2. KREIRANJE PROCEDURE: spec.uprPrikazAktivnihClanovaPoProjektu
-- ============================================================================
CREATE PROCEDURE spec.uprPrikazAktivnihClanovaPoProjektu
@idProjekta INT=NULL
WITH ENCRYPTION
AS
BEGIN
    BEGIN TRY
        SELECT p.Id AS [ProjekatId],
               p.Naziv AS [ProjekatNaziv],
               ac.ClanId AS [AktivniClanId],
               ac.ClanIme AS [AktivniClanIme],
               ac.ClanUloga AS [AktivniClanUloga]
        FROM   impl.tblProjekat AS p -- CROSS APPLY poziva inline funkciju za svaki red iz tabele projekata
        CROSS APPLY spec.fnt_AktivniClanovi(p.Id) AS ac
        WHERE  (@idProjekta IS NULL
                OR p.Id = @idProjekta);
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
-- 3. WRAPPER I DODELA PRAVA ROLE-U DataProviderPM
-- ============================================================================
CREATE PROCEDURE api_pm.uprPrikazAktivnihClanovaPoProjektu
@idProjekta INT=NULL
AS
BEGIN
    BEGIN TRY
        EXECUTE spec.uprPrikazAktivnihClanovaPoProjektu @idProjekta = @idProjekta;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END

GRANT EXECUTE
    ON api_pm.uprPrikazAktivnihClanovaPoProjektu TO DataProviderPM;


GO
-- 4. TEST
-- ============================================================================
PRINT N'ТЕСТ 1: Приказ свих пројеката и њихових активних чланова (Параметар је NULL)';

BEGIN TRY
    EXECUTE api_pm.uprPrikazAktivnihClanovaPoProjektu @idProjekta = NULL;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 1: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT N'ТЕСТ 2: Приказ активних чланова искључиво за Пројекат са ИД = 1';

BEGIN TRY
    EXECUTE api_pm.uprPrikazAktivnihClanovaPoProjektu @idProjekta = 1;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 2: ' + ERROR_MESSAGE();
END CATCH