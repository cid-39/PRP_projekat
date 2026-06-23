-- ============================================================================
-- SKRIPTA 4_z12: Multistatement TVF za statistiku projekata
-- ============================================================================
USE [ProjektniSistem];


GO
-- Brisanje funkcije ako vec postoji
IF OBJECT_ID('spec.fnt_StatistikaProjekata', 'TF') IS NOT NULL
    DROP FUNCTION spec.fnt_StatistikaProjekata;


GO
-- 1. KREIRANJE FUNKCIJE: spec.fnt_StatistikaProjekata
-- ============================================================================
CREATE FUNCTION spec.fnt_StatistikaProjekata
( )
RETURNS 
    @Statistika TABLE (
        ProjekatId     INT            NOT NULL,
        ProjekatNaziv  NVARCHAR (200) NOT NULL,
        UkupnoZadataka INT            NOT NULL,
        Zavrseno       INT            NOT NULL,
        UToku          INT            NOT NULL,
        Prekoraceno    INT            NOT NULL,
        PRIMARY KEY (ProjekatId))
WITH ENCRYPTION
AS
BEGIN
    INSERT INTO @Statistika (ProjekatId, ProjekatNaziv, UkupnoZadataka, Zavrseno, UToku, Prekoraceno)
    SELECT   p.Id AS [ProjekatId],
             p.Naziv AS [ProjekatNaziv],
             COUNT(z.Id) AS [UkupnoZadataka],
             -- zavrseni zad
    SUM(CASE WHEN z.StatusZad = N'Завршено' THEN 1 ELSE 0 END) AS [Zavrseno],
             -- nezavrseni zad
    SUM(CASE WHEN z.StatusZad IN (N'Ново', N'ТокуИзради') THEN 1 ELSE 0 END) AS [UToku],
             -- prekoraceni zad
    SUM(CASE WHEN spec.FnsKasnjenjeDana(z.Id) > 0 THEN 1 ELSE 0 END) AS [Prekoraceno]
    FROM     impl.tblProjekat AS p
             LEFT OUTER JOIN
             impl.tblZadatak AS z
             ON p.Id = z.IdProjekta
    GROUP BY p.Id, p.Naziv;
    RETURN;
END


GO
-- 2. DODELA PRAVA ROLE-U DataProviderPM (preko pogleda)
-- ============================================================================
-- kreira se wrapper pogled u api_pm koji izlaze podatke ove funkcije
IF OBJECT_ID('api_pm.VW_STATISTIKA_PROJEKATA', 'V') IS NOT NULL
    DROP VIEW api_pm.VW_STATISTIKA_PROJEKATA;


GO
CREATE VIEW api_pm.VW_STATISTIKA_PROJEKATA
AS
SELECT ProjekatId,
       ProjekatNaziv,
       UkupnoZadataka,
       Zavrseno,
       UToku,
       Prekoraceno
FROM   spec.fnt_StatistikaProjekata();


GO
GRANT SELECT
    ON api_pm.VW_STATISTIKA_PROJEKATA TO DataProviderPM;


GO
-- 3. TEST
-- ============================================================================
PRINT N'ТЕСТ 1: Приказ комплетне статистике свих пројеката кроз АПИ поглед';

BEGIN TRY
    SELECT ProjekatId AS [ИД Пројекта],
           ProjekatNaziv AS [Назив Пројекта],
           UkupnoZadataka AS [Укупно задатака],
           Zavrseno AS [Завршено],
           UToku AS [У току],
           Prekoraceno AS [Прекорачено]
    FROM   api_pm.VW_STATISTIKA_PROJEKATA;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 1: ' + ERROR_MESSAGE();
END CATCH


GO
PRINT N'ТЕСТ 2: Издвајање само оних пројеката који имају прекорачене задатке';

BEGIN TRY
    SELECT ProjekatNaziv AS [Пројекат са кашњењем],
           Prekoraceno AS [Број прекорачених задатака]
    FROM   api_pm.VW_STATISTIKA_PROJEKATA
    WHERE  Prekoraceno > 0;
END TRY
BEGIN CATCH
    PRINT N'Грешка у Тесту 2: ' + ERROR_MESSAGE();
END CATCH