-- ============================================================================
-- SKRIPTA 4_z6: Kreiranje klijentskih API pogleda i dodela prava
-- ============================================================================
-- uloge su vec kreirane u skripti 1 valjda
USE [ProjektniSistem];


GO
-- Brisanje klijentskih pogleda ako vec postoje
IF OBJECT_ID('api_pm.VW_ZADATAK', 'V') IS NOT NULL
    DROP VIEW api_pm.VW_ZADATAK;

IF OBJECT_ID('api_pm.VW_CLAN_ZADACI', 'V') IS NOT NULL
    DROP VIEW api_pm.VW_CLAN_ZADACI;

IF OBJECT_ID('api_dev.VW_ZADATAK', 'V') IS NOT NULL
    DROP VIEW api_dev.VW_ZADATAK;


GO
-- 1. KLIJENTSKI POGLEDI ZA PROJECT MANAGER SHEMU
-- ============================================================================
CREATE VIEW api_pm.VW_ZADATAK
AS
SELECT * -- ZadatakId, OpisZadatka, DatumRoka, StatusZad, Prioritet, NazivProjekta
FROM   spec.vw_ZADATAK;


GO
CREATE VIEW api_pm.VW_CLAN_ZADACI
AS
SELECT * --ImeClana, UlogaClana, OpisZadatka, NazivProjekta, DatumDodeljivan
FROM   spec.vw_CLAN_ZADACI;


GO
-- 2. KLIJENTSKI POGLEDI ZA DEVELOPER SHEMU
-- ============================================================================
-- Promjena: Naziv pogleda prebacen u UPPER_CASE prema zahtjevu 8
CREATE VIEW api_dev.VW_ZADATAK
AS
SELECT * -- ZadatakId, OpisZadatka, DatumRoka, StatusZad, Prioritet, NazivProjekta
FROM   spec.vw_ZADATAK;


GO
-- 3. Dodela prava nad klijentskim pogledima
-- ============================================================================
-- Promjena: Prava dodijeljena na UPPER_CASE nazive pogleda
GRANT SELECT
    ON api_pm.VW_ZADATAK TO DataProviderPM;

GRANT SELECT
    ON api_pm.VW_CLAN_ZADACI TO DataProviderPM;

GRANT SELECT
    ON api_dev.VW_ZADATAK TO DataProviderDEV;


GO
-- 4. TEST
-- ============================================================================
PRINT 'TEST 1: Provera da li se podaci uspesno citaju iz klijentskog PM pogleda';

BEGIN TRY
    SELECT *
    FROM   api_pm.VW_ZADATAK;
END TRY
BEGIN CATCH
    PRINT 'Greska u Testu 1: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT 'TEST 2: Provera da li se podaci uspesno citaju iz klijentskog DEV pogleda';

BEGIN TRY
    SELECT *
    FROM   api_dev.VW_ZADATAK;
END TRY
BEGIN CATCH
    PRINT 'Greska u Testu 2: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT 'TEST 3: Provera izolacije (da li dev moze da pristupi pogledu za pm)';

BEGIN TRY
    EXECUTE sys.sp_setapprole @rolename = 'DataProviderDEV', @password = 'ja_sam_dev'; --GO
    SELECT *
    FROM   api_pm.VW_ZADATAK; --GO
END TRY
BEGIN CATCH
    PRINT 'Greska (test 3): ' + ERROR_MESSAGE();
END CATCH