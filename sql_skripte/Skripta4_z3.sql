-- ============================================================================
-- SKRIPTA 4_z3: Kreiranje DML trigera impl.trgProveraRoka i testiranje
-- ============================================================================
USE [ProjektniSistem];


GO
-- Brisanje trigera ukoliko vec postoji
IF OBJECT_ID('impl.trgProveraRoka', 'TR') IS NOT NULL
    BEGIN
        DROP TRIGGER impl.trgProveraRoka;
    END


GO
-- 1. KREIRANJE TRIGERA
-- ============================================================================
CREATE TRIGGER impl.trgProveraRoka
    ON impl.tblZadatak
    WITH ENCRYPTION
    AFTER INSERT, UPDATE
    AS BEGIN
           -- Provera da ima li ijedan zadatak sa rokom posle roka projekta
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             impl.tblProjekat AS p
                             ON i.IdProjekta = p.Id
                      WHERE  p.DatumZavrsetka IS NOT NULL
                             AND i.DatumRoka > p.DatumZavrsetka)
               BEGIN
                   -- Ponistavanje transakcije
                   ROLLBACK;
                   RAISERROR (N'Грешка: Рок задатка не сме прелазити датум завршетка пројекта!', 16, 1);
                   RETURN;
               END
       END


GO
-- 2. TESTIRANJE
-- ============================================================================
PRINT 'TEST 1: Unosa zadatka sa rokom posle kraja projekta';


GO
BEGIN TRY
    -- Projekat 1 se završava 2025-06-30 
    -- Unesemo zadatak sa rokom 2025-08-15
    INSERT  INTO impl.tblZadatak (IdProjekta, Opis, DatumRoka, StatusZad, Prioritet)
    VALUES                      (1, N'Невалидан тест задатак', '2025-08-15', N'Ново', 3);
    PRINT 'Greska: Test je prosao, a triger NIJE blokirao nevalidan unos!';
END TRY
BEGIN CATCH
    -- Prikazujemo poruku koju je triger bacio
    PRINT ERROR_MESSAGE();
END CATCH


GO
PRINT 'TEST 2: Unos validnog zadatka';


GO
BEGIN TRY
    -- Unos zadatka sa rokom 2025-05-20
    INSERT  INTO impl.tblZadatak (IdProjekta, Opis, DatumRoka, StatusZad, Prioritet)
    VALUES                      (1, N'Валидан тест задатак', '2025-05-20', N'Ново', 3);
    PRINT 'Uspeh: Validni zadatak je uspesno unesen, triger je dozvolio akciju.'; -- Brisanje testnog podatka
    DELETE impl.tblZadatak
    WHERE  Opis = N'Валидан тест задатак';
END TRY
BEGIN CATCH
    PRINT 'Greska: Triger je greskom blokirao validan unos! Poruka: ' + ERROR_MESSAGE();
END CATCH