-- ============================================================================
-- SKRIPTA 4_z5: Kreiranje pogleda u spec shemi
-- ============================================================================
USE [ProjektniSistem];


GO
-- Brisanje pogleda ako vec postoje
IF OBJECT_ID('spec.vw_ZADATAK', 'V') IS NOT NULL
    DROP VIEW spec.vw_ZADATAK;

IF OBJECT_ID('spec.vw_CLAN_ZADACI', 'V') IS NOT NULL
    DROP VIEW spec.vw_CLAN_ZADACI;


GO
-- 1. POGLED: spec.vw_ZADATAK
-- ============================================================================
CREATE VIEW spec.vw_ZADATAK
WITH ENCRYPTION
AS
SELECT z.Id AS ZadatakId,
       z.Opis AS OpisZadatka,
       z.DatumRoka,
       z.StatusZad,
       z.Prioritet,
       p.Id AS ProjekatId,
       p.Naziv AS NazivProjekta,
       p.StatusProj,
       c.Ime AS ImeClana
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
-- 2. POGLED: spec.vw_CLAN_ZADACI
-- ============================================================================
CREATE VIEW spec.vw_CLAN_ZADACI
WITH ENCRYPTION
AS
SELECT c.Id AS ClanId,
       c.Ime AS ImeClana,
       c.Uloga AS UlogaClana,
       z.Id AS ZadatakId,
       z.Opis AS OpisZadatka,
       p.Naziv AS NazivProjekta,
       r.DatumDodeljivan
FROM   impl.tblRad AS r
       INNER JOIN
       impl.tblClan AS c
       ON r.IdClana = c.Id
       INNER JOIN
       impl.tblZadatak AS z
       ON r.IdZadatka = z.Id
       INNER JOIN
       impl.tblProjekat AS p
       ON z.IdProjekta = p.Id;


GO
-- 3. TEST
-- ============================================================================
PRINT 'TEST 1: Provera citanja podataka iz pogleda vw_ZADATAK';

BEGIN TRY
    SELECT *
    FROM   spec.vw_ZADATAK;
END TRY
BEGIN CATCH
    PRINT 'Greska u Testu 1: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT 'TEST 2: Provera citanja podataka iz pogleda vw_CLAN_ZADACI';

BEGIN TRY
    SELECT *
    FROM   spec.vw_CLAN_ZADACI;
END TRY
BEGIN CATCH
    PRINT 'Greska u Testu 2: ' + ERROR_MESSAGE();
END CATCH