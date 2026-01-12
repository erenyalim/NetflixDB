CREATE DATABASE NetflixDB;
USE netflixdb;

CREATE TABLE Subscription_Plan(
	PlanID INT PRIMARY KEY AUTO_INCREMENT,
    PlanName VARCHAR(50) NOT NULL,
    Price DECIMAL (10,2) NOT NULL,
    MaxProfiles INT NOT NULL,
    Resolution ENUM ('720p (HD)', '1080p (Full HD)', '4K (Ultra HD)') NOT NULL
);

CREATE TABLE Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL, 
    LastName VARCHAR(50) NOT NULL,   
    Email VARCHAR(100) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    BirthdayDate DATE NOT NULL,
    Job VARCHAR(100),
    Gender ENUM('M', 'F'),
    BillingAddress VARCHAR(255) NOT NULL,
    PlanID INT NOT NULL,

    FOREIGN KEY (PlanID) REFERENCES Subscription_Plan(PlanID)
);

CREATE TABLE Content (
    ContentID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(150) NOT NULL,
    ReleaseYear YEAR NOT NULL,
    AgeRating ENUM('0+', '7+', '13+', '16+', '18+') NOT NULL,
    Synopsis TEXT NOT NULL,
    ContentType ENUM('Movie', 'Series') NOT NULL,
    
    AverageScore DECIMAL(4,2) DEFAULT 0.0           
);

CREATE TABLE Movie (
    ContentID INT PRIMARY KEY,
    Duration INT NOT NULL CHECK (Duration > 0), 
    BoxOfficeRevenue DECIMAL(15,2) CHECK (BoxOfficeRevenue >= 0),
    FOREIGN KEY (ContentID) 
		REFERENCES Content(ContentID) 
		ON DELETE CASCADE
);

CREATE TABLE Series (
    ContentID INT PRIMARY KEY,
    TotalSeasons INT,
    FOREIGN KEY (ContentID) 
    REFERENCES Content(ContentID) 
    ON DELETE CASCADE
);

CREATE TABLE Episode (
    EpisodeID INT PRIMARY KEY AUTO_INCREMENT,
    SeasonNumber INT NOT NULL,
    EpisodeNumber INT NOT NULL,
    Title VARCHAR(150) NOT NULL,
    Duration INT NOT NULL,
	SeriesID INT NOT NULL,

    FOREIGN KEY (SeriesID) REFERENCES Series(ContentID) ON DELETE CASCADE,
    
    UNIQUE (SeriesID, SeasonNumber, EpisodeNumber) 
);

CREATE TABLE Profile (
	ProfileID INT PRIMARY KEY AUTO_INCREMENT,
    ProfileName VARCHAR(50) NOT NULL,
    ProfileType ENUM('Kid', 'Adult') NOT NULL DEFAULT 'Adult',
	UserID INT NOT NULL,
     
    FOREIGN KEY (UserID) 
        REFERENCES Users(UserID) 
        ON DELETE CASCADE
);

CREATE TABLE Subscription_History (
    HistoryID INT PRIMARY KEY AUTO_INCREMENT,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL ,
    Status BOOLEAN DEFAULT TRUE, 
    UserID INT NOT NULL,
    PlanID INT NOT NULL,
    
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (PlanID) REFERENCES Subscription_Plan(PlanID)
);

CREATE TABLE Payment_Transaction (
    TransactionID INT PRIMARY KEY AUTO_INCREMENT,
    PaymentDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod ENUM('Credit Card', 'PayPal', 'Gift Card') NOT NULL,
    
	HistoryID INT NOT NULL,
    FOREIGN KEY (HistoryID) REFERENCES Subscription_History(HistoryID) ON DELETE CASCADE
);

CREATE TABLE Person (
    PersonID INT PRIMARY KEY AUTO_INCREMENT,
    FullName VARCHAR(100) NOT NULL,
    BirthDate DATE
);

CREATE TABLE Credited (
    ContentID INT,
    PersonID INT,
    RoleType ENUM('Director', 'Actor', 'Screenwriter', 'Producer') NOT NULL,
    CharacterName VARCHAR(100), 

    PRIMARY KEY (ContentID, PersonID, RoleType),
    
    FOREIGN KEY (ContentID) REFERENCES Content(ContentID) ON DELETE CASCADE,
    FOREIGN KEY (PersonID) REFERENCES Person(PersonID) ON DELETE CASCADE
);

CREATE TABLE Watch_Session (
    SessionID INT PRIMARY KEY AUTO_INCREMENT,
    SessionStart DATETIME DEFAULT CURRENT_TIMESTAMP,
    SessionEnd DATETIME,
    DurationSeconds INT DEFAULT 0, 
    DeviceType VARCHAR(50),   
    
	ProfileID INT NOT NULL,
    MovieID INT, 
    EpisodeID INT,
    
    FOREIGN KEY (ProfileID) REFERENCES Profile(ProfileID) ON DELETE CASCADE,
    FOREIGN KEY (MovieID) REFERENCES Movie(ContentID) ON DELETE CASCADE,
    FOREIGN KEY (EpisodeID) REFERENCES Episode(EpisodeID) ON DELETE CASCADE,
    

    CONSTRAINT chk_content_type CHECK (
        (MovieID IS NOT NULL AND EpisodeID IS NULL) OR 
        (MovieID IS NULL AND EpisodeID IS NOT NULL)
    )
);


CREATE TABLE Progress_Update (
    UpdateID INT PRIMARY KEY AUTO_INCREMENT,
    SessionID INT NOT NULL,
    LogTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    ProgressSeconds INT NOT NULL, 
    
    FOREIGN KEY (SessionID) REFERENCES Watch_Session(SessionID) ON DELETE CASCADE
);

CREATE TABLE Content_Tag (
    TagID INT PRIMARY KEY AUTO_INCREMENT,
    TagName VARCHAR(50) UNIQUE NOT NULL 
);

CREATE TABLE Content_Tag_Map (
    ContentID INT,
    TagID INT,
    
    PRIMARY KEY (ContentID, TagID),
    FOREIGN KEY (ContentID) REFERENCES Content(ContentID) ON DELETE CASCADE,
    FOREIGN KEY (TagID) REFERENCES Content_Tag(TagID) ON DELETE CASCADE
);

CREATE TABLE MyList (
    ProfileID INT,
    ContentID INT,
    AddedDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (ProfileID, ContentID), 
    FOREIGN KEY (ProfileID) REFERENCES Profile(ProfileID) ON DELETE CASCADE,
    FOREIGN KEY (ContentID) REFERENCES Content(ContentID) ON DELETE CASCADE
);

CREATE TABLE Rating (
    ProfileID INT,
    ContentID INT,
    Score INT NOT NULL CHECK (Score BETWEEN 1 AND 10), 
    RatingDate DATETIME DEFAULT CURRENT_TIMESTAMP,
  
    
    PRIMARY KEY (ProfileID, ContentID), 
    FOREIGN KEY (ProfileID) REFERENCES Profile(ProfileID) ON DELETE CASCADE,
    FOREIGN KEY (ContentID) REFERENCES Content(ContentID) ON DELETE CASCADE
);

CREATE TABLE Languages (
    LanguageID INT PRIMARY KEY AUTO_INCREMENT,
    LanguageName VARCHAR(50) UNIQUE NOT NULL 
);

CREATE TABLE Content_Audio (
    ContentID INT,
    LanguageID INT,
    PRIMARY KEY (ContentID, LanguageID), 
    
    FOREIGN KEY (ContentID) REFERENCES Content(ContentID) ON DELETE CASCADE,
    FOREIGN KEY (LanguageID) REFERENCES Languages(LanguageID) ON DELETE CASCADE
);
CREATE TABLE Content_Subtitle (
    ContentID INT,
    LanguageID INT,
    PRIMARY KEY (ContentID, LanguageID),
    FOREIGN KEY (ContentID) REFERENCES Content(ContentID) ON DELETE CASCADE,
    FOREIGN KEY (LanguageID) REFERENCES Languages(LanguageID) ON DELETE CASCADE
);

CREATE TABLE Genre (
    GenreID INT PRIMARY KEY AUTO_INCREMENT,
    GenreName VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Content_Genre (
    ContentID INT,
    GenreID INT,
    PRIMARY KEY (ContentID, GenreID),
    FOREIGN KEY (ContentID) REFERENCES Content(ContentID) ON DELETE CASCADE,
    FOREIGN KEY (GenreID) REFERENCES Genre(GenreID) ON DELETE CASCADE
);

-- TRIGGERS

DELIMITER $$
CREATE TRIGGER trg_movie_check
BEFORE INSERT ON Movie
FOR EACH ROW
BEGIN
    IF (SELECT ContentType 
        FROM Content 
        WHERE ContentID = NEW.ContentID) <> 'Movie' THEN
        
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Movie tablosuna sadece Movie eklenebilir';
    END IF;
END$$

DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_series_check
BEFORE INSERT ON SERIES 
FOR EACH ROW
BEGIN
	IF( SELECT ContentType 
		FROM Content
        WHERE ContentID = NEW.ContentID) <> 'Series' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Hata: Series tablosuna sadece Series tipindeki içerikler eklenebilir!';
    END IF;
END$$
DELIMITER ;


DELIMITER $$

CREATE TRIGGER trg_profile_limit
BEFORE INSERT ON Profile
FOR EACH ROW
BEGIN
    DECLARE max_profiles INT;
    DECLARE current_profiles INT;

    SELECT sp.MaxProfiles
    INTO max_profiles
    FROM Users u
    JOIN Subscription_Plan sp ON u.PlanID = sp.PlanID
    WHERE u.UserID = NEW.UserID;

    SELECT COUNT(*)
    INTO current_profiles
    FROM Profile
    WHERE UserID = NEW.UserID;

    IF current_profiles >= max_profiles THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bu abonelik planı için maksimum profil sayısına ulaşıldı';
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE TRIGGER trg_check_age_restriction
BEFORE INSERT ON Watch_Session
FOR EACH ROW
BEGIN
    DECLARE content_rating_val ENUM('0+', '7+', '13+', '16+', '18+');
    DECLARE profile_type_val ENUM('Kid', 'Adult');
    DECLARE target_content_id INT;

    IF NEW.MovieID IS NOT NULL THEN
        SET target_content_id = NEW.MovieID;
    ELSE
        SELECT SeriesID INTO target_content_id 
        FROM Episode 
        WHERE EpisodeID = NEW.EpisodeID;
    END IF;

    SELECT AgeRating INTO content_rating_val 
    FROM Content 
    WHERE ContentID = target_content_id;
    
    SELECT ProfileType INTO profile_type_val 
    FROM Profile 
    WHERE ProfileID = NEW.ProfileID;

    IF profile_type_val = 'Kid' AND content_rating_val IN ('16+', '18+') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'HATA: Çocuk profili ile yetişkin içeriği (+16/18) izlenemez!';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_update_average_score
AFTER INSERT ON Rating
FOR EACH ROW
BEGIN
    UPDATE Content 
    SET AverageScore = (
        SELECT AVG(Score) 
        FROM Rating 
        WHERE ContentID = NEW.ContentID
    )
    WHERE ContentID = NEW.ContentID;
END$$

DELIMITER ;


#INSERT DATAS

INSERT INTO subscription_plan (PlanName, Price, MaxProfiles, Resolution) VALUES 
('Temel', 69.99, 1, '720p (HD)' ),
('Standart', 109.99, 2, '1080p (Full HD)' ),
('Özel', 149.99, 4, '4K (Ultra HD)' );

INSERT INTO Users (FirstName, LastName, Email, PasswordHash, BirthdayDate, Job, Gender, BillingAddress, PlanID) VALUES 
('Eren', 'Yalım', 'eren@hotmail.com', 'hasheren', '2005-07-21', 'Yazılımcı', 'M', 'Beylikdüzü,İstanbul', 3),
('İlknur', 'Karadaş', 'ilknur@hotmail.com', 'hashilknur', '1979-06-30', 'Bankacı', 'F', 'Sarıyer,İstanbul', 2),
('Elif', 'Uçal', 'elif@hotmail.com', 'hashelif', '1955-04-12', 'Emekli', 'F', 'Çankaya, Ankara', 2),
('Hamza', 'Eryetli', 'hamza@hotmail.com', 'hashhamza', '2003-09-15', 'Öğrenci', 'M', 'Bornova, İzmir', 1),
('Kaan', 'Seyman', 'kaan@hotmail.com', 'hashkaan', '1995-03-13', 'Mühendis', 'M', 'Bodrum, Muğla', 3),
('Tuğçe', 'Üstün', 'tugce@hotmail.com', 'hashtugce', '2000-01-01', NULL, 'F', 'Kaş, Antalya', 1),
('Cem', 'Üstün', 'cem@hotmail.com', 'hashcem', '1980-10-10', 'Pilot', 'M', 'Kaş, Antalya', 3);

INSERT INTO Profile (ProfileName, ProfileType, UserID) VALUES 
('ErenMain', 'Adult', 1),
('Eren2', 'Adult', 1),
('Eren3', 'Adult', 1),
('ErenKid', 'Kid', 1),
('İlknurMain', 'Adult', 2),
('İlknur2', 'Adult', 2),
('ElifMain', 'Adult', 3),
('HamzaMain', 'Adult', 4),
('KaanMain', 'Adult', 5),
('KaanKid', 'Kid', 5),
('TuğçeMain', 'Adult', 6),
('CemMain', 'Adult', 7);

INSERT INTO Content (Title, ReleaseYear, AgeRating, Synopsis, ContentType, AverageScore) VALUES 
('The Godfather', 1972, '18+', 'Bir mafya babası ailesinde en küçük oğul suç imparatorluğunda adım adım yükselir.', 'Movie', 0),
('Toy Story', 1995, '0+', 'Oyuncakların sahibi Andy yokken yaşadığı gizli hayat.', 'Movie', 0),
('Sonic', 2020, '7+', 'Hızlı Sonic kendisini yakalamaya çalışanlardan kaçar.', 'Movie', 0),
('Interstellar', 2014, '13+', 'Bir grup astronot başka bir gezegen bulmak amacıyla tehlikeli bir yolculuğa çıkar.', 'Movie', 0),
('Breaking Bad', 2008, '18+', 'Bir kimya öğretmeninin uyuşturucu baronuna dönüşmesi.', 'Series', 0),
('Lupin', 2023, '16+', 'Kibar bir hırsız soygunlar planlar.', 'Series', 0);

INSERT INTO Movie (ContentID, Duration, BoxOfficeRevenue) VALUES 
(1, 175, 246000000.00), 
(2, 81, 373000000.00),  
(3, 99, 319700000.00),  
(4, 169, 701700000.00);  
INSERT INTO Series (ContentID, TotalSeasons) VALUES 
(5, 5), 
(6, 3); 

INSERT INTO Episode (SeriesID, SeasonNumber, EpisodeNumber, Title, Duration) VALUES 
-- Breaking Bad (ID: 5)
(5, 1, 1, 'Pilot', 58),
(5, 1, 2, 'Yazı Tura', 48),
-- Lupin (ID: 6)
(6, 1, 1, 'Bölüm 1', 45),
(6, 1, 2, 'Bölüm 2', 42),
(5, 2, 1, 'Seven Thirty-Seven', 47);

INSERT INTO Person (FullName, BirthDate) VALUES 
('Al Pacino', '1940-04-25'),         -- ID: 1 (Godfather)
('Tom Hanks', '1956-07-09'),         -- ID: 2 (Toy Story)
('Jim Carrey', '1962-01-17'),        -- ID: 3 (Sonic - Dr. Robotnik)
('Matthew McConaughey', '1969-11-04'),-- ID: 4 (Interstellar)
('Bryan Cranston', '1956-03-07'),    -- ID: 5 (Breaking Bad)
('Omar Sy', '1978-01-20'),           -- ID: 6 (Lupin)
('Christopher Nolan', '1970-07-30'); -- ID: 7 (Yönetmen - Interstellar)

INSERT INTO Credited (ContentID, PersonID, RoleType, CharacterName) VALUES 
(1, 1, 'Actor', 'Michael Corleone'),   -- Al Pacino -> Godfather
(2, 2, 'Actor', 'Woody (Ses)'),        -- Tom Hanks -> Toy Story
(3, 3, 'Actor', 'Dr. Robotnik'),       -- Jim Carrey -> Sonic
(4, 4, 'Actor', 'Cooper'),             -- Matthew M. -> Interstellar
(4, 7, 'Director', 'Nolan'),              -- Nolan -> Interstellar (Yönetmen)
(5, 5, 'Actor', 'Walter White'),       -- Bryan Cranston -> Breaking Bad
(6, 6, 'Actor', 'Assane Diop');        -- Omar Sy -> Lupin

INSERT INTO Genre (GenreName) VALUES ('Suç'), ('Animasyon'), ('Aksiyon'), ('Bilim Kurgu'), ('Drama'), ('Aile');

INSERT INTO Content_Genre (ContentID, GenreID) VALUES 
(1, 1), (1, 5), -- Godfather: Suç, Drama
(2, 2), (2, 6), -- Toy Story: Animasyon, Aile
(3, 3), (3, 6), -- Sonic: Aksiyon, Aile
(4, 4), (4, 5), -- Interstellar: Bilim Kurgu, Drama
(5, 1), (5, 5), -- Breaking Bad: Suç, Drama
(6, 1), (6, 3); -- Lupin: Suç, Aksiyon

INSERT INTO Subscription_History (StartDate, EndDate, Status, UserID, PlanID) VALUES 
-- --- GEÇMİŞ DÖNEM (2025 - Hepsi FALSE / Ayrılanlar veya Süresi Dolanlar) ---
('2025-01-01', '2025-02-01', FALSE, 1, 3), -- Eren (Eski)
('2025-02-15', '2025-03-15', FALSE, 2, 2), -- İlknur (Eski)
('2025-03-10', '2025-04-10', FALSE, 3, 2), -- Elif (Eski - BIRAKTI)
('2025-05-20', '2025-06-20', FALSE, 4, 1), -- Hamza (Eski)
('2025-06-01', '2025-07-01', FALSE, 5, 3), -- Kaan (Eski)
('2025-07-01', '2025-08-01', FALSE, 6, 1), -- Tuğçe (Eski)
('2025-08-01', '2025-09-01', FALSE, 7, 3), -- Cem (Eski - BIRAKTI)
-- --- GÜNCEL DÖNEM (2026 - AKTİF ÜYELER - TRUE) ---
('2026-01-01', '2026-02-01', TRUE, 1, 3), -- Eren (Yeniledi - AKTİF)
('2026-01-05', '2026-02-05', TRUE, 5, 3), -- Kaan (Yeniledi - AKTİF)
('2026-01-10', '2026-02-10', TRUE, 2, 2), -- İlknur (Geri Döndü - AKTİF)
('2026-01-12', '2026-02-12', TRUE, 4, 1), -- Hamza (Geri Döndü - AKTİF)
('2026-01-15', '2026-02-15', TRUE, 6, 1); -- Tuğçe (Geri Döndü - AKTİF)

INSERT INTO Payment_Transaction (PaymentDate, Amount, PaymentMethod, HistoryID) VALUES 
-- 2025 Ödemeleri (Geçmiş)
('2025-01-01 10:00:00', 149.99, 'Credit Card', 1),
('2025-02-15 14:30:00', 109.99, 'Credit Card', 2),
('2025-03-10 09:15:00', 109.99, 'Gift Card', 3),
('2025-05-20 11:00:00', 69.99, 'PayPal', 4),
('2025-06-01 16:45:00', 149.99, 'Credit Card', 5),
('2025-07-01 12:00:00', 69.99, 'Credit Card', 6),
('2025-08-01 08:30:00', 149.99, 'PayPal', 7),
-- 2026 Ödemeleri (YENİ - CİRO ARTIRAN KISIM)
('2026-01-01 09:00:00', 149.99, 'Credit Card', 8),  -- Eren (Ocak 2026)
('2026-01-05 14:00:00', 149.99, 'Credit Card', 9),  -- Kaan (Ocak 2026)
('2026-01-10 10:30:00', 109.99, 'Credit Card', 10), -- İlknur (Ocak 2026)
('2026-01-12 11:15:00', 69.99, 'PayPal', 11),       -- Hamza (Ocak 2026)
('2026-01-15 16:20:00', 69.99, 'Credit Card', 12);  -- Tuğçe (Ocak 2026)

INSERT INTO Watch_Session (ProfileID, MovieID, EpisodeID, SessionStart, SessionEnd, DurationSeconds, DeviceType) VALUES 
(1, 1, NULL, '2025-01-10 20:00:00', '2025-01-10 22:55:00', 10500, 'Smart TV'),
(4, 2, NULL, '2025-01-12 18:00:00', '2025-01-12 20:30:00', 9000, 'iPad'),
(7, 4, NULL, '2025-03-15 21:00:00', '2025-03-15 23:30:00', 9000, 'Laptop'),
(10, 2, NULL, '2025-06-05 14:00:00', '2025-06-05 15:20:00', 4800, 'Smart TV'),
(9, NULL, 1, '2025-06-10 20:00:00', '2025-06-10 20:58:00', 3480, 'Smart TV'),
(9, NULL, 2, '2025-06-10 21:00:00', '2025-06-10 21:48:00', 2880, 'Smart TV'),
(5, 4, NULL, '2025-02-20 10:00:00', '2025-02-20 10:15:00', 900, 'Tablet'),
(1, 3, NULL, '2026-01-02 20:00:00', '2026-01-02 21:40:00', 6000, 'Smart TV'),
(5, NULL, 3, '2026-01-11 21:00:00', '2026-01-11 23:00:00', 7200, 'Laptop'),
(8, 2, NULL, '2026-01-13 14:00:00', '2026-01-13 15:21:00', 4860, 'Phone'),
(11, NULL, 1, '2026-01-16 22:00:00', '2026-01-16 23:00:00', 3600, 'Tablet');

INSERT INTO Progress_Update (SessionID, ProgressSeconds) VALUES 
(1, 3600), -- Eren, Godfather'ın 1. saatinde
(1, 7200), -- Eren, Godfather'ın 2. saatinde
(5, 1500), -- Kaan, Breaking Bad izlerken 25. dakikada
(7, 900),  -- İlknur, Interstellar'ı 15. dakikada kapatmış (Yarım bırakan)
(11, 120); -- Tuğçe, Breaking Bad'e yeni başlamış (2. dakika)

INSERT INTO MyList (ProfileID, ContentID) VALUES 
(1, 2), -- Eren (ID:1) -> Toy Story'yi listeye aldı
(1, 5), -- Eren (ID:1) -> Breaking Bad'i listeye aldı
(5, 4), -- İlknur (ID:5) -> Interstellar
(9, 6), -- Kaan (ID:9) -> Lupin
(8, 1), -- Hamza (ID:8) -> Godfather (Yeni Aktif Üye)
(11, 3); -- Tuğçe (ID:11) -> Sonic (Yeni Aktif Üye)

INSERT INTO Rating (ProfileID, ContentID, Score) VALUES 
(1, 1, 10), -- Eren (ID:1) -> Godfather: 10 Puan
(4, 2, 9),  -- ErenKid (ID:4) -> Toy Story: 9 Puan
(9, 5, 10), -- Kaan (ID:9) -> Breaking Bad: 10 Puan
(7, 4, 8),  -- Elif (ID:7) -> Interstellar: 8 Puan
(5, 6, 9),  -- İlknur (ID:5) -> Lupin: 9 Puan (2026'da izledi ve beğendi)
(8, 2, 7);  -- Hamza (ID:8) -> Toy Story: 7 Puan

INSERT INTO Content_Tag (TagName) VALUES 
('Oscar Ödüllü'), ('Karanlık Atmosfer'), ('Eğlenceli'), ('Sürükleyici');

INSERT INTO Content_Tag_Map (ContentID, TagID) VALUES 
(1, 1), (1, 2), -- Godfather: Oscar, Karanlık
(2, 1), (2, 3), -- Toy Story: Oscar, Eğlenceli
(4, 1), (4, 4), -- Interstellar: Oscar, Sürükleyici
(5, 2), (5, 4); -- Breaking Bad: Karanlık, Sürükleyici

INSERT INTO Languages (LanguageName) VALUES 
('İngilizce'), 
('Türkçe'), 
('Fransızca'), 
('Almanca'), 
('İspanyolca');

INSERT INTO Content_Audio (ContentID, LanguageID) VALUES 
(1, 1), 
(1, 2),
(2, 1),
(2, 2), 
(3, 1),
(3, 2), 
(4, 1),
(4, 2), 
(5, 1),
(5, 2),
(5, 3),
(5, 4),
(5, 5),
(6, 1), 
(6, 2), 
(6, 3);

INSERT INTO content_subtitle (ContentID, LanguageID) VALUES 
(1, 1), 
(1, 2),
(2, 1),
(2, 2), 
(3, 1),
(3, 2), 
(4, 1),
(4, 2), 
(5, 1),
(5, 2),
(5, 3),
(5, 4),
(5, 5),
(6, 1), 
(6, 2), 
(6, 3);

#							#
#	SORGULAR VE TESTLER     #
#							#

-- Basic paketi olan biri 4 profil açabilir mi?
INSERT INTO Profile (ProfileName, ProfileType, UserID) 
VALUES ('HamzaNew', 'Adult', (SELECT UserID FROM Users WHERE Email='hamza@hotmail.com'));

-- Çocuk profili +18 film izleyebilir mi?
INSERT INTO Watch_Session (ProfileID, EpisodeID, SessionStart) 
VALUES (
    (SELECT ProfileID FROM Profile WHERE ProfileName='ErenKid'), 
    (SELECT EpisodeID FROM Episode WHERE Title='Bölüm 1' LIMIT 1), 
    NOW()
);

-- Movie tablosuna dizi ekleme HATA verir
INSERT INTO Content (Title, ReleaseYear, AgeRating, Synopsis, ContentType) 
VALUES ('Test Dizisi', 2024, '13+', 'Test', 'Series');

INSERT INTO Movie (ContentID, Duration, BoxOfficeRevenue) 
VALUES ((SELECT ContentID FROM Content WHERE Title = 'Test Dizisi' LIMIT 1), 120, 5000);

-- Hangi abone paketinden ne kadar ciro ? 
SELECT 
sp.PlanName AS "Plan Adı",
COUNT(DISTINCT u.UserID) AS "Abone Sayısı",
SUM(pt.amount) AS "Ciro"
FROM subscription_plan sp
JOIN USERS u ON sp.PlanID = u.PlanID
JOIN subscription_history sh ON u.UserID = sh.UserID
JOIN payment_transaction pt ON sh.HistoryID = pt.HistoryID
GROUP BY sp.PlanName
ORDER BY SUM(pt.amount) DESC;

-- Aktif üyeler ve ödediği ücretler
SELECT 
u.FirstName,
u.LastName,
sp.PlanName,
pt.Amount
FROM Users u
JOIN subscription_history sh ON u.UserID = sh.UserID
JOIN subscription_plan sp ON u.PlanID = sp.PlanID
JOIN payment_transaction pt ON sh.HistoryID = pt.HistoryID
WHERE sh.status = TRUE;

-- Filmin tüm detayları 
SELECT 
    c.Title AS 'Film',
    c.ReleaseYear AS 'Yıl',
    g.GenreName AS 'Tür',
    p.FullName AS 'Kişi',
    cr.RoleType AS 'Rolü',
    c.averagescore AS "Puan"
FROM Content c
JOIN Content_Genre cg ON c.ContentID = cg.ContentID
JOIN Genre g ON cg.GenreID = g.GenreID
JOIN Credited cr ON c.ContentID = cr.ContentID
JOIN Person p ON cr.PersonID = p.PersonID
JOIN rating r ON c.ContentID = r.ContentID
WHERE c.Title = 'Toy Story';

-- Dizi detayları ve Bölümleri
SELECT 
    c.Title AS 'Dizi Adı',
    c.ReleaseYear AS 'Yıl',
    c.AverageScore AS 'Puan',
    g.GenreName AS 'Tür',
    e.SeasonNumber AS 'Sezon',
    e.EpisodeNumber AS 'Bölüm',
    e.Title AS 'Bölüm Adı',
    e.Duration AS "Süre (dk)"
FROM Content c
JOIN Series s ON c.ContentID = s.ContentID
JOIN Episode e ON s.ContentID = e.SeriesID
JOIN Content_Genre cg ON c.ContentID = cg.ContentID
JOIN Genre g ON cg.GenreID = g.GenreID
ORDER BY c.Title, e.SeasonNumber, e.EpisodeNumber, g.GenreName;

-- Platformdaki en çok bölüme sahip olan dizi ve bölüm sayısı
SELECT 
    c.Title AS 'Dizi Adı',
    COUNT(e.EpisodeID) AS 'Toplam Bölüm Sayısı'
FROM Content c
JOIN Episode e ON c.ContentID = e.SeriesID
WHERE c.ContentType = 'Series'
GROUP BY c.Title
ORDER BY COUNT(e.EpisodeID) DESC
LIMIT 1;

-- Profilin listesine eklediği içerikler
SELECT 
p.ProfileName AS "Profile Adı",
c.Title AS "İçerik İsmi"
FROM profile p
JOIN mylist my ON p.ProfileID = my.ProfileID
JOIN content c ON c.ContentID = my.ContentID
WHERE p.profileName = "ErenMain";

-- Kim, ne, ne kadar izledi
SELECT 
p.ProfileName "Profil İsmi",
u.FirstName "Hesap Sahibi",
c.Title "Film İsmi",
e.Title"Bölüm İsmi",
SUM(ws.DurationSeconds) AS "Toplam İzleme"
FROM watch_session ws
JOIN Profile p ON ws.ProfileID = p.ProfileID
JOIN Users u ON u.UserID = p.UserID
LEFT JOIN Movie m ON ws.MovieID = m.ContentID
LEFT JOIN Content c ON m.ContentID = c.ContentID
LEFT JOIN  episode e ON ws.EpisodeID = e.EpisodeID
GROUP BY p.ProfileName, u.FirstName, c.Title, e.Title, ws.MovieID
ORDER BY SUM(ws.DurationSeconds) DESC;







