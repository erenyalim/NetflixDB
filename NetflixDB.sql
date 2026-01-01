CREATE DATABASE NetflixDB;
USE netflixdb;

#Bağımsızlar ÜST TABLOLAR
CREATE TABLE Subscription_Plan(
	PlanID INT PRIMARY KEY AUTO_INCREMENT,
    PlanName VARCHAR(50) NOT NULL,
    Price DECIMAL (10,2) NOT NULL,
    MaxProfiles INT NOT NULL,
    Resolution ENUM ('720p (HD)', '1080p (Full HD)', '4K (Ultra HD)') NOT NULL
);

CREATE TABLE Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    BirthdayDate DATE NOT NULL,
    Job VARCHAR(100),
    Gender ENUM('M', 'F'),
    BillingAddress VARCHAR(255) NOT NULL,
    PlanID INT NOT NULL,

    FOREIGN KEY (PlanID)
        REFERENCES Subscription_Plan(PlanID)
);

CREATE TABLE Content (
    ContentID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(150) NOT NULL,
    ReleaseYear YEAR NOT NULL,
	AgeRating ENUM('0+', '7+', '13+', '16+', '18+') NOT NULL,
    Synopsis TEXT NOT NULL,
    ContentType ENUM('Movie', 'Series') NOT NULL
);

#Bağımlı ALT TABLOLAR (contentten türeyen)
CREATE TABLE Movie (
    ContentID INT PRIMARY KEY,
    Duration INT NOT NULL CHECK (Duration > 0), 
    BoxOfficeRevenue DECIMAL(15,2) CHECK (BoxOfficeRevenue >= 0),
    FOREIGN KEY (ContentID) 
		REFERENCES Content(ContentID) 
		ON DELETE CASCADE
);

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

CREATE TABLE Series (
    ContentID INT PRIMARY KEY,
    TotalSeasons INT,
    FOREIGN KEY (ContentID) 
    REFERENCES Content(ContentID) 
    ON DELETE CASCADE
);
