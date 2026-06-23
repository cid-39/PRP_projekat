-- ============================================================================
-- SKRIPTA 2: Kreiranje tabela sa svim ograničenjima (Implementacioni sloj)
-- ============================================================================
USE [ProjektniSistem];


GO
-- 1. KREIRANJE FIZICKIH TABELA
-- ============================================================================
-- Kreiranje tabele Projekat
CREATE TABLE impl.tblProjekat (
    Id             BIGINT         IDENTITY (1, 1) NOT NULL,
    Naziv          NVARCHAR (200) NOT NULL,
    DatumPocetka   DATE           NOT NULL,
    DatumZavrsetka DATE           NULL,
    StatusProj     NVARCHAR (20)  NOT NULL,
    -- Primarni kljuc i provera
CONSTRAINT PK_tblProjekat PRIMARY KEY (Id),
    CONSTRAINT CHK_Projekat_Id CHECK (Id > 0),
    -- Naziv ne sme biti prazan string ili samo razmaci
CONSTRAINT CHK_Projekat_Naziv CHECK (LEN(TRIM(Naziv)) > 0),
    -- Datum pocetka nmz biti u buducnosti
CONSTRAINT CHK_Projekat_DatumPocetka CHECK (DatumPocetka <= GETDATE()),
    -- Datum zavrsetka mora biti posle datuma pocetka ako je definisan
CONSTRAINT CHK_Projekat_Datumi CHECK (DatumZavrsetka IS NULL
                                      OR DatumZavrsetka > DatumPocetka),
    -- Dozvoljene vrednosti statusa projekta
CONSTRAINT CHK_Projekat_StatusProj CHECK (StatusProj IN (N'Активан', N'Завршен', N'Отказан'))
);


GO
-- Kreiranje tabele Zadatak
CREATE TABLE impl.tblZadatak (
    Id         BIGINT         IDENTITY (1, 1) NOT NULL,
    Opis       NVARCHAR (500) NOT NULL,
    DatumRoka  DATE           NOT NULL,
    StatusZad  NVARCHAR (20)  NOT NULL,
    Prioritet  INT            NOT NULL,
    IdProjekta BIGINT         NOT NULL,
    -- Primarni kljuc i provera
CONSTRAINT PK_tblZadatak PRIMARY KEY (Id),
    CONSTRAINT CHK_Zadatak_Id CHECK (Id > 0),
    -- Opis ne sme biti prazan string
CONSTRAINT CHK_Zadatak_Opis CHECK (LEN(TRIM(Opis)) > 0),
    -- Dozvoljene vrednosti statusa zadatka
CONSTRAINT CHK_Zadatak_StatusZad CHECK (StatusZad IN (N'Ново', N'ТокуИзради', N'Завршено')),
    -- who tf said ТокуИзради bro? put the fries...
-- Prioritet moze biti u opsegu od 1 do 5 (1 je najvisi lol)
CONSTRAINT CHK_Zadatak_Prioritet CHECK (Prioritet BETWEEN 1 AND 5),
    -- Osnovna provera za kolonu koja ce postati strani kljuc
CONSTRAINT CHK_Zadatak_IdProjekta CHECK (IdProjekta > 0)
);


GO
-- Kreiranje tabele Clan
CREATE TABLE impl.tblClan (
    Id    BIGINT         IDENTITY (1, 1) NOT NULL,
    Ime   NVARCHAR (100) NOT NULL,
    Uloga NVARCHAR (100) NOT NULL,
    -- Primarni kljuc i provera
CONSTRAINT PK_tblClan PRIMARY KEY (Id),
    CONSTRAINT CHK_Clan_Id CHECK (Id > 0),
    -- Ime clana mora početi velikim ćiriličnim slovom i ne sme biti prazno
CONSTRAINT CHK_Clan_Ime CHECK (Ime LIKE N'[А-Ш]%'
                               AND LEN(TRIM(Ime)) > 0),
    -- Uloga ne sme biti prazan string
CONSTRAINT CHK_Clan_Uloga CHECK (LEN(TRIM(Uloga)) > 0)
);


GO
-- Kreiranje tabele Rad
CREATE TABLE impl.tblRad (
    IdClana         BIGINT NOT NULL,
    IdZadatka       BIGINT NOT NULL,
    DatumDodeljivan DATE   NOT NULL,
    -- Slozeni primarni kljuc automarski garantuje i UNIQUE(IdClana, IdZadatka)
CONSTRAINT PK_tblRad PRIMARY KEY (IdClana, IdZadatka),
    -- Datum dodeljivanja clana na zadatak ne moze biti u buducnosti
CONSTRAINT CHK_Rad_DatumDodeljivan CHECK (DatumDodeljivan <= GETDATE()),
    -- Osnovne provere stranih kljuceva
CONSTRAINT CHK_Rad_IdClana CHECK (IdClana > 0),
    -- Unique check radi reda i guess
CONSTRAINT UQ_Rad_ClanZadatak UNIQUE (IdClana, IdZadatka),
    CONSTRAINT CHK_Rad_IdZadatka CHECK (IdZadatka > 0)
);


GO
-- 2. REFERENCIJALNI INTEGRITET
-- ============================================================================
-- Veza: tblZadatak -> tblProjekat (jedan projekat ima vise zadataka)
-- Pravilo: Brisanje projekta je RESTRICT
ALTER TABLE impl.tblZadatak
    ADD CONSTRAINT FK_tblZadatak_tblProjekat FOREIGN KEY (IdProjekta) REFERENCES impl.tblProjekat (Id) ON DELETE NO ACTION ON UPDATE NO ACTION;


GO
-- Veza: tblRad -> tblClan
-- Pravilo: Brisanjem clana sledi akcija CASCADE
ALTER TABLE impl.tblRad
    ADD CONSTRAINT FK_tblRad_tblClan FOREIGN KEY (IdClana) REFERENCES impl.tblClan (Id) ON DELETE CASCADE ON UPDATE NO ACTION;


GO
-- Veza: tblRad -> tblZadatak (Desna strana M:N veze)
-- Pravilo: Brisanjem zadatka sledi akcija CASCADE (uklanjaju se sva angažovanja)
ALTER TABLE impl.tblRad
    ADD CONSTRAINT FK_tblRad_tblZadatak FOREIGN KEY (IdZadatka) REFERENCES impl.tblZadatak (Id) ON DELETE CASCADE ON UPDATE NO ACTION;


GO
PRINT 'Skripta 2 je uspešno izvrsena. Tabele i ogranicenja su kreirani u impl shemi.';