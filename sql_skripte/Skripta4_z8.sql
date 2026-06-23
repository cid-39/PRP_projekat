-- ============================================================================
-- SKRIPTA 4_z8: Skladistenje, kreiranje indexa, i modifikacija XML dokumenta 
-- ============================================================================
-- XML skraceno za X-can't M-do L-it do it anymore
-- u redu 53 bitan komentar, ovo je sve za izmenu jednog statusa!!!
USE [ProjektniSistem];


GO
-- Brisanje objekata ako vec postoje
IF OBJECT_ID('impl.trg_SinhronizacijaXmlZadataka', 'TR') IS NOT NULL
    DROP TRIGGER impl.trg_SinhronizacijaXmlZadataka;

IF OBJECT_ID('impl.tblProjektniPlanoviXml', 'U') IS NOT NULL
    DROP TABLE impl.tblProjektniPlanoviXml;

IF OBJECT_ID('api_pm.upr_PromeniStatusZadatkaXml', 'P') IS NOT NULL
    DROP PROCEDURE api_pm.upr_PromeniStatusZadatkaXml;


GO
-- 1. KREIRANJE TABELE ZA SKLADISTENJE XML DOKUMENATA I INSERT PODATAKA
-- ============================================================================
CREATE TABLE impl.tblProjektniPlanoviXml (
    Id               INT      IDENTITY (1, 1) CONSTRAINT PK_ProjektniPlanovi PRIMARY KEY CLUSTERED,
    DatumArhiviranja DATETIME CONSTRAINT DF_DatumArhiviranja DEFAULT GETDATE(),
    DokumentPlana    XML      NOT NULL
);


GO
-- Ubacivanje podataka (uzimamo pogled napravljen u 4_z7)
INSERT INTO impl.tblProjektniPlanoviXml (DokumentPlana)
SELECT ProjektniPlan
FROM   spec.vw_PLAN_XML;


GO
-- 2. KREIRANJE PRIMARNOG XML INDEKSA
-- ============================================================================
CREATE PRIMARY XML INDEX PXI_ProjektniPlanovi_DokumentPlana
    ON impl.tblProjektniPlanoviXml(DokumentPlana);


GO
-- 3. TRIGER ZA SINHRONIZACIJU PODATAKA IZ XML TABELE U tblZadatak
-- ============================================================================
CREATE TRIGGER impl.trg_SinhronizacijaXmlZadataka
    ON impl.tblProjektniPlanoviXml
    WITH ENCRYPTION
    AFTER UPDATE
    AS BEGIN
           BEGIN TRY
               -- Proveravamo da li je azurirana XML kolona
               IF UPDATE (DokumentPlana)
                   BEGIN
                       DECLARE @IdZadatka AS INT;
                       DECLARE @NoviStatus AS NVARCHAR (20); -- Uzima se modifikovan XML iz inserted 
                       -- Koristimo CROSS APPLY i .nodes() kako bismo procitali promenjene podatke 
                       -- !!! Ovaj triger je osnovna ideja za kad se menja samo jedan status !!!!
                       SELECT TOP 1 @IdZadatka = xmlNode.value('(@Id)[1]', 'INT'),
                                    @NoviStatus = xmlNode.value('(Status/text())[1]', 'NVARCHAR(20)')
                       FROM   inserted AS i CROSS APPLY i.DokumentPlana.nodes('/ProjektniPlan/Projekat/Zadaci/Zadatak') AS T(xmlNode); -- Poziv procedure iz spec seme da se azurira u tabeli 
                       IF @IdZadatka IS NOT NULL
                          AND @NoviStatus IS NOT NULL
                           BEGIN
                               EXECUTE spec.upr_PromeniStatus @IdZadatka = @IdZadatka, @NoviStatus = @NoviStatus;
                           END
                   END
           END TRY
           BEGIN CATCH
               DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
               RAISERROR (@ErrorMessage, 16, 1);
           END CATCH
       END


GO
-- 4. PROCEDURA: api_pm.upr_PromeniStatusZadatkaXml 
-- ============================================================================
-- Ova procedura radi ozloglaseni modify sa "replace value of"
CREATE PROCEDURE api_pm.upr_PromeniStatusZadatkaXml
@IdXml INT, @IdZadatka INT, @NoviStatus NVARCHAR (20)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION; -- Azuriranje statusa zadatka na specificnom id-u koristeci replace value of unutar modify-ja
        UPDATE impl.tblProjektniPlanoviXml
        SET    DokumentPlana.modify('
            replace value of (/ProjektniPlan/Projekat/Zadaci/Zadatak[@Id=sql:variable("@IdZadatka")]/Status/text())[1]
            with sql:variable("@NoviStatus")
        ')
        WHERE  Id = @IdXml;
        COMMIT TRANSACTION;
        PRINT N'Успех: Статус задатка је успешно промењен директно у XML-у (а преко тригера и у бази).';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        DECLARE @ErrorMessage AS NVARCHAR (4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END


GO
-- 5. Dodela prava role-u DataProviderPM
-- ============================================================================
GRANT EXECUTE
    ON api_pm.upr_PromeniStatusZadatkaXml TO DataProviderPM;


GO
-- 6. TEST
-- ============================================================================
PRINT N'ТЕСТ 1: Провера стања задатка (ИД = 1) пре измене';

BEGIN TRY
    SELECT *
    FROM   impl.tblZadatak
    WHERE  Id = 1;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 1: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT N'ТЕСТ 2: Покретање процедуре за XML модификацију (Мењамо статус задатка 1 у "Завршено")';

BEGIN TRY
    -- Pretpostavljamo da smo u tabeli promenili najmanje 1 slog, id 1 ce se uvek naci tu u testu
    EXECUTE api_pm.upr_PromeniStatusZadatkaXml @IdXml = 1, @IdZadatka = 1, @NoviStatus = N'ТокуИзради';
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 2: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT N'ТЕСТ 3: Провера стања задатка (ИД = 1) након измене - треба да буде ТокуИзради';

BEGIN TRY
    SELECT *
    FROM   impl.tblZadatak
    WHERE  Id = 1;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 3: ' + ERROR_MESSAGE();
END CATCH


-- topla preporuka samo pokrenuti opet skriptu 3 jer me mrzi da ovde dodajem i vracanje na originalno stanje