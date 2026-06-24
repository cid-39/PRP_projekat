-- ============================================================================
-- SKRIPTA test_pm: Prikazivanje mogucnosti pristupa za DataProviderPM
-- ============================================================================
USE [ProjektniSistem];

-- Podesavamo role za DataProviderPM kako bi simulirali aplikacionu konekciju
EXECUTE sys.sp_setapprole @rolename = 'DataProviderPM', @password = 'ja_sam_pm';
GO

-- 1. Prikaz previdjenog pristupa
-- ============================================================================
SELECT * FROM api_pm.VW_ZADATAK;
GO

SELECT * FROM api_pm.VW_STATISTIKA_PROJEKATA;
GO

EXECUTE api_pm.upr_PromeniStatus @idZadatka = 3, @NoviStatus = 'Ново';
GO

EXECUTE api_pm.upr_PromeniStatusZadatkaXml @IdXml = 1, @IdZadatka = 3, @NoviStatus = N'ТокуИзради';
GO

-- 2. Prikaz pokusaja pristupa api_dev shemi
-- ============================================================================
SELECT * FROM api_dev.VW_ZADATAK;
GO

EXECUTE api_dev.upr_PromeniStatus @idZadatka = 2, @NoviStatus = 'Ново';
GO

-- 2. Prikaz pokusaja pristupa impl i spec shemama
-- ============================================================================
SELECT * FROM impl.tblProjekat;
GO

SELECT * FROM spec.vw_PLAN_XML;
GO