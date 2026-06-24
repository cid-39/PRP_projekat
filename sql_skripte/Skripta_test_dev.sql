-- ============================================================================
-- SKRIPTA test_dev: Prikazivanje mogucnosti pristupa za DataProviderDEV
-- ============================================================================
USE [ProjektniSistem];

-- Podesavamo role za DataProviderDEV kako bi simulirali aplikacionu konekciju
EXECUTE sys.sp_setapprole @rolename = 'DataProviderDEV', @password = 'ja_sam_dev';
GO

-- 1. Prikaz previdjenog pristupa (pogeled ZADATAK i promena statusa)
-- ============================================================================
SELECT * FROM api_dev.VW_ZADATAK;
GO

EXECUTE api_dev.upr_PromeniStatus @idZadatka = 2, @NoviStatus = 'Ново';
GO

-- 2. Prikaz pokusaja pristupa api_pm shemi
-- ============================================================================
SELECT * FROM api_pm.VW_ZADATAK;
GO

SELECT * FROM api_pm.VW_PLAN_XML;
GO

EXECUTE api_pm.upr_KreirajZadatak @IdProjekta = 1, @Opis = 'Opisa nema', @DatumRoka = '2025-03-31', @Prioritet = 5;
GO

-- 2. Prikaz pokusaja pristupa impl i spec shemama
-- ============================================================================
SELECT * FROM impl.tblProjekat;

SELECT * FROM spec.vw_PLAN_XML;