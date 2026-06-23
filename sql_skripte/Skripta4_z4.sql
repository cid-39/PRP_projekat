-- ============================================================================
-- SKRIPTA 4_z4: Kreiranje uskladistenih procedura sa enkripcijom u spec shemi
-- ============================================================================
USE [ProjektniSistem];


GO
-- Brisanje procedura ako vec postoje
IF OBJECT_ID('spec.upr_KreirajZadatak', 'P') IS NOT NULL
    DROP PROCEDURE spec.upr_KreirajZadatak;

IF OBJECT_ID('spec.upr_PromeniStatus', 'P') IS NOT NULL
    DROP PROCEDURE spec.upr_PromeniStatus;

IF OBJECT_ID('spec.upr_DodeliClana', 'P') IS NOT NULL
    DROP PROCEDURE spec.upr_DodeliClana;


GO
-- 1. PROCEDURA: spec.upr_KreirajZadatak
-- ============================================================================
CREATE PROCEDURE spec.upr_KreirajZadatak
@IdProjekta INT, @Opis NVARCHAR (500), @DatumRoka DATE, @Prioritet INT
WITH ENCRYPTION
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION; -- Status se automatski postavlja na 'Ново' jer eto?
        INSERT  INTO impl.tblZadatak (IdProjekta, Opis, DatumRoka, StatusZad, Prioritet)
        VALUES                      (@IdProjekta, @Opis, @DatumRoka, N'Ново', @Prioritet);
        COMMIT TRANSACTION;
        PRINT N'Успех: Задатак је успешно креиран са почетним статусом Ново.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK; -- Prosledjivanje greske
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
-- kreiranje wrappera na api shemi
CREATE PROCEDURE api_pm.upr_KreirajZadatak
@IdProjekta INT, @Opis NVARCHAR (500), @DatumRoka DATE, @Prioritet INT
AS
BEGIN
    BEGIN TRY
        -- Prosledjivanje izvrsavanja baznoj proceduri iz spec seme
        EXECUTE spec.upr_KreirajZadatak @IdProjekta = @IdProjekta, @Opis = @Opis, @DatumRoka = @DatumRoka, @Prioritet = @Prioritet;
    END TRY
    BEGIN CATCH
        -- Hvatanje i ponovno podizanje greske iz bazne procedure
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
GRANT EXECUTE
    ON api_pm.upr_KreirajZadatak TO DataProviderPM;


GO
-- 2. PROCEDURA: spec.upr_PromeniStatus
-- ============================================================================
CREATE PROCEDURE spec.upr_PromeniStatus
@IdZadatka INT, @NoviStatus NVARCHAR (20)
WITH ENCRYPTION
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION; -- Provera da li zadatak uopste postoji u bazi
        IF NOT EXISTS (SELECT 1
                       FROM   impl.tblZadatak
                       WHERE  Id = @IdZadatka)
            BEGIN
                RAISERROR (N'Грешка: Задатак са датим ИД-ем не постоји!', 16, 1);
            END -- Validacija dozvoljenih statusa pre izmene
        IF @NoviStatus NOT IN (N'Ново', N'ТокуИзради', N'Завршено')
            BEGIN
                RAISERROR (N'Грешка: Унети статус није валидан!', 16, 1);
            END -- Azuriranje statusa zadatka
        UPDATE impl.tblZadatak
        SET    StatusZad = @NoviStatus
        WHERE  Id = @IdZadatka;
        COMMIT TRANSACTION;
        PRINT N'Успех: Статус задатка је успешно промењен.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
-- opet wrapper, ovog puta jos jedan za dev
CREATE PROCEDURE api_pm.upr_PromeniStatus
@IdZadatka INT, @NoviStatus NVARCHAR (20)
AS
BEGIN
    BEGIN TRY
        -- Prosledjivanje izvrsavanja baznoj proceduri iz spec seme
        EXECUTE spec.upr_PromeniStatus @IdZadatka = @IdZadatka, @NoviStatus = @NoviStatus;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
GRANT EXECUTE
    ON api_pm.upr_PromeniStatus TO DataProviderPM;


GO
CREATE PROCEDURE api_dev.upr_PromeniStatus
@IdZadatka INT, @NoviStatus NVARCHAR (20)
AS
BEGIN
    BEGIN TRY
        -- Prosledjivanje izvrsavanja baznoj proceduri iz spec seme
        EXECUTE spec.upr_PromeniStatus @IdZadatka = @IdZadatka, @NoviStatus = @NoviStatus;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
GRANT EXECUTE
    ON api_dev.upr_PromeniStatus TO DataProviderDEV;


GO
-- 3. PROCEDURA: spec.upr_DodeliClana
-- ============================================================================
CREATE PROCEDURE spec.upr_DodeliClana
@IdClana INT, @IdZadatka INT
WITH ENCRYPTION
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION; -- Provera postojanja clana
        IF NOT EXISTS (SELECT 1
                       FROM   impl.tblClan
                       WHERE  Id = @IdClana)
            BEGIN
                RAISERROR (N'Грешка: Члан са датим ИД-ем не постоји!', 16, 1);
            END -- Provera postojanja zadatka
        IF NOT EXISTS (SELECT 1
                       FROM   impl.tblZadatak
                       WHERE  Id = @IdZadatka)
            BEGIN
                RAISERROR (N'Грешка: Задатак са датим ИД-ем не постоји!', 16, 1);
            END -- Unos u veznu tabelu, datum dodeljivanja je trenutni datum
        INSERT  INTO impl.tblRad (IdClana, IdZadatka, DatumDodeljivan)
        VALUES                  (@IdClana, @IdZadatka, CAST (GETDATE() AS DATE));
        COMMIT TRANSACTION;
        PRINT N'Успех: Члан је успешно додељен на задатак.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
CREATE PROCEDURE api_pm.upr_DodeliClana
@IdClana INT, @IdZadatka INT
AS
BEGIN
    BEGIN TRY
        -- Prosledjivanje izvrsavanja baznoj proceduri iz spec seme
        EXECUTE spec.upr_DodeliClana @IdClana = @IdClana, @IdZadatka = @IdZadatka;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
GRANT EXECUTE
    ON api_pm.upr_DodeliClana TO DataProviderPM;


GO
-- 4. TEST
-- ============================================================================
PRINT 'TEST 1: Kreiranje novog zadatka preko procedure';

BEGIN TRY
    -- Projekat 1 traje do 2025-06-30. Kreiramo zadatak sa rokom 2025-04-15
    EXECUTE spec.upr_KreirajZadatak @IdProjekta = 1, @Opis = N'Привремени тест задатак за процедуре', @DatumRoka = '2025-04-15', @Prioritet = 3;
END TRY
BEGIN CATCH
    PRINT 'Greska u Testu 1: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT 'TEST 2: Pokusaj izmene statusa na nepostojeci status';

BEGIN TRY
    -- Pokusavamo da stavimo nevalidan status
    EXECUTE spec.upr_PromeniStatus @IdZadatka = 1, @NoviStatus = N'не постојим';
END TRY
BEGIN CATCH
    PRINT 'Ocekivana greska uhvacena: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT 'TEST 3: uspesna dodela clana na zadatak i ciscenje';

BEGIN TRY
    -- Pronalazimo Id novokreiranog testnog zadatka da bismo radili sa njim
    DECLARE @TestZadatakId AS INT;
    SELECT @TestZadatakId = Id
    FROM   impl.tblZadatak
    WHERE  Opis = N'Привремени тест задатак за процедуре';
    IF @TestZadatakId IS NOT NULL
        BEGIN
            EXECUTE spec.upr_DodeliClana @IdClana = 2, @IdZadatka = @TestZadatakId; -- Brisanje test podataka
            DELETE impl.tblRad
            WHERE  IdZadatka = @TestZadatakId
                   AND IdClana = 2;
            DELETE impl.tblZadatak
            WHERE  Id = @TestZadatakId;
            PRINT 'Testni podaci su uspesno uklonjeni iz baze.';
        END
    ELSE
        BEGIN
            PRINT 'Greska: Testni zadatak nije pronadjen, brisanje preskoceno.';
        END
END TRY
BEGIN CATCH
    PRINT 'Greska u Testu 3 ili tokom ciscenja: ' + ERROR_MESSAGE();
END CATCH