/*
Family Recipe Book Database
Target: Microsoft SQL Server 2025
*/

SET NOCOUNT ON;
GO

IF DB_ID(N'FamilyRecipeBook') IS NULL
BEGIN
    CREATE DATABASE FamilyRecipeBook;
END;
GO

USE FamilyRecipeBook;
GO

/* Drop objects safely for repeatable local setup */
IF OBJECT_ID(N'dbo.RecipeRatings', N'U') IS NOT NULL DROP TABLE dbo.RecipeRatings;
IF OBJECT_ID(N'dbo.RecipePhotos', N'U') IS NOT NULL DROP TABLE dbo.RecipePhotos;
IF OBJECT_ID(N'dbo.RecipeTags', N'U') IS NOT NULL DROP TABLE dbo.RecipeTags;
IF OBJECT_ID(N'dbo.Tags', N'U') IS NOT NULL DROP TABLE dbo.Tags;
IF OBJECT_ID(N'dbo.RecipeSteps', N'U') IS NOT NULL DROP TABLE dbo.RecipeSteps;
IF OBJECT_ID(N'dbo.RecipeIngredients', N'U') IS NOT NULL DROP TABLE dbo.RecipeIngredients;
IF OBJECT_ID(N'dbo.Ingredients', N'U') IS NOT NULL DROP TABLE dbo.Ingredients;
IF OBJECT_ID(N'dbo.RecipeCategories', N'U') IS NOT NULL DROP TABLE dbo.RecipeCategories;
IF OBJECT_ID(N'dbo.Categories', N'U') IS NOT NULL DROP TABLE dbo.Categories;
IF OBJECT_ID(N'dbo.Recipes', N'U') IS NOT NULL DROP TABLE dbo.Recipes;
IF OBJECT_ID(N'dbo.FamilyMembers', N'U') IS NOT NULL DROP TABLE dbo.FamilyMembers;
GO

CREATE TABLE dbo.FamilyMembers
(
    FamilyMemberID   INT IDENTITY(1,1) PRIMARY KEY,
    DisplayName      NVARCHAR(100) NOT NULL,
    Email            NVARCHAR(255) NULL,
    CreatedAtUtc     DATETIME2(3) NOT NULL CONSTRAINT DF_FamilyMembers_CreatedAtUtc DEFAULT SYSUTCDATETIME()
);
GO

CREATE UNIQUE INDEX UX_FamilyMembers_Email
ON dbo.FamilyMembers(Email)
WHERE Email IS NOT NULL;
GO

CREATE TABLE dbo.Recipes
(
    RecipeID             INT IDENTITY(1,1) PRIMARY KEY,
    Title                NVARCHAR(200) NOT NULL,
    Description          NVARCHAR(1000) NULL,
    PrepMinutes          INT NOT NULL CONSTRAINT DF_Recipes_PrepMinutes DEFAULT 0,
    CookMinutes          INT NOT NULL CONSTRAINT DF_Recipes_CookMinutes DEFAULT 0,
    Servings             INT NULL,
    Source               NVARCHAR(300) NULL,
    IsFavorite           BIT NOT NULL CONSTRAINT DF_Recipes_IsFavorite DEFAULT 0,
    CreatedByMemberID    INT NULL,
    CreatedAtUtc         DATETIME2(3) NOT NULL CONSTRAINT DF_Recipes_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
    UpdatedAtUtc         DATETIME2(3) NOT NULL CONSTRAINT DF_Recipes_UpdatedAtUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Recipes_PrepMinutes CHECK (PrepMinutes >= 0),
    CONSTRAINT CK_Recipes_CookMinutes CHECK (CookMinutes >= 0),
    CONSTRAINT CK_Recipes_Servings CHECK (Servings IS NULL OR Servings > 0),
    CONSTRAINT FK_Recipes_FamilyMembers_CreatedBy
        FOREIGN KEY (CreatedByMemberID) REFERENCES dbo.FamilyMembers(FamilyMemberID)
);
GO

CREATE INDEX IX_Recipes_Title ON dbo.Recipes(Title);
CREATE INDEX IX_Recipes_IsFavorite ON dbo.Recipes(IsFavorite);
GO

CREATE TABLE dbo.Categories
(
    CategoryID     INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName   NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_Categories_CategoryName UNIQUE (CategoryName)
);
GO

CREATE TABLE dbo.RecipeCategories
(
    RecipeID      INT NOT NULL,
    CategoryID    INT NOT NULL,
    PRIMARY KEY (RecipeID, CategoryID),
    CONSTRAINT FK_RecipeCategories_Recipes
        FOREIGN KEY (RecipeID) REFERENCES dbo.Recipes(RecipeID) ON DELETE CASCADE,
    CONSTRAINT FK_RecipeCategories_Categories
        FOREIGN KEY (CategoryID) REFERENCES dbo.Categories(CategoryID) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.Ingredients
(
    IngredientID       INT IDENTITY(1,1) PRIMARY KEY,
    IngredientName     NVARCHAR(150) NOT NULL,
    CONSTRAINT UQ_Ingredients_IngredientName UNIQUE (IngredientName)
);
GO

CREATE TABLE dbo.RecipeIngredients
(
    RecipeIngredientID     INT IDENTITY(1,1) PRIMARY KEY,
    RecipeID               INT NOT NULL,
    IngredientID           INT NOT NULL,
    Quantity               DECIMAL(10,2) NULL,
    Unit                   NVARCHAR(50) NULL,
    PrepNote               NVARCHAR(200) NULL,
    SequenceNumber         INT NOT NULL,
    CONSTRAINT FK_RecipeIngredients_Recipes
        FOREIGN KEY (RecipeID) REFERENCES dbo.Recipes(RecipeID) ON DELETE CASCADE,
    CONSTRAINT FK_RecipeIngredients_Ingredients
        FOREIGN KEY (IngredientID) REFERENCES dbo.Ingredients(IngredientID),
    CONSTRAINT CK_RecipeIngredients_Quantity CHECK (Quantity IS NULL OR Quantity > 0),
    CONSTRAINT CK_RecipeIngredients_SequenceNumber CHECK (SequenceNumber > 0)
);
GO

CREATE UNIQUE INDEX UX_RecipeIngredients_Recipe_Sequence
ON dbo.RecipeIngredients(RecipeID, SequenceNumber);
GO

CREATE TABLE dbo.RecipeSteps
(
    RecipeStepID          INT IDENTITY(1,1) PRIMARY KEY,
    RecipeID              INT NOT NULL,
    StepNumber            INT NOT NULL,
    InstructionText       NVARCHAR(2000) NOT NULL,
    CONSTRAINT FK_RecipeSteps_Recipes
        FOREIGN KEY (RecipeID) REFERENCES dbo.Recipes(RecipeID) ON DELETE CASCADE,
    CONSTRAINT CK_RecipeSteps_StepNumber CHECK (StepNumber > 0)
);
GO

CREATE UNIQUE INDEX UX_RecipeSteps_Recipe_StepNumber
ON dbo.RecipeSteps(RecipeID, StepNumber);
GO

CREATE TABLE dbo.Tags
(
    TagID       INT IDENTITY(1,1) PRIMARY KEY,
    TagName     NVARCHAR(50) NOT NULL,
    CONSTRAINT UQ_Tags_TagName UNIQUE (TagName)
);
GO

CREATE TABLE dbo.RecipeTags
(
    RecipeID    INT NOT NULL,
    TagID       INT NOT NULL,
    PRIMARY KEY (RecipeID, TagID),
    CONSTRAINT FK_RecipeTags_Recipes
        FOREIGN KEY (RecipeID) REFERENCES dbo.Recipes(RecipeID) ON DELETE CASCADE,
    CONSTRAINT FK_RecipeTags_Tags
        FOREIGN KEY (TagID) REFERENCES dbo.Tags(TagID) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.RecipePhotos
(
    RecipePhotoID      INT IDENTITY(1,1) PRIMARY KEY,
    RecipeID           INT NOT NULL,
    PhotoUrl           NVARCHAR(500) NOT NULL,
    Caption            NVARCHAR(200) NULL,
    IsPrimary          BIT NOT NULL CONSTRAINT DF_RecipePhotos_IsPrimary DEFAULT 0,
    AddedAtUtc         DATETIME2(3) NOT NULL CONSTRAINT DF_RecipePhotos_AddedAtUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_RecipePhotos_Recipes
        FOREIGN KEY (RecipeID) REFERENCES dbo.Recipes(RecipeID) ON DELETE CASCADE
);
GO

CREATE INDEX IX_RecipePhotos_RecipeID ON dbo.RecipePhotos(RecipeID);
GO

CREATE TABLE dbo.RecipeRatings
(
    RecipeRatingID      INT IDENTITY(1,1) PRIMARY KEY,
    RecipeID            INT NOT NULL,
    FamilyMemberID      INT NOT NULL,
    Rating              TINYINT NOT NULL,
    ReviewText          NVARCHAR(1000) NULL,
    RatedAtUtc          DATETIME2(3) NOT NULL CONSTRAINT DF_RecipeRatings_RatedAtUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_RecipeRatings_Recipes
        FOREIGN KEY (RecipeID) REFERENCES dbo.Recipes(RecipeID) ON DELETE CASCADE,
    CONSTRAINT FK_RecipeRatings_FamilyMembers
        FOREIGN KEY (FamilyMemberID) REFERENCES dbo.FamilyMembers(FamilyMemberID) ON DELETE CASCADE,
    CONSTRAINT CK_RecipeRatings_Rating CHECK (Rating BETWEEN 1 AND 5),
    CONSTRAINT UQ_RecipeRatings_Recipe_Member UNIQUE (RecipeID, FamilyMemberID)
);
GO

/* Keep UpdatedAtUtc current on recipe edits */
CREATE OR ALTER TRIGGER dbo.TR_Recipes_SetUpdatedAtUtc
ON dbo.Recipes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE r
    SET UpdatedAtUtc = SYSUTCDATETIME()
    FROM dbo.Recipes r
    INNER JOIN inserted i ON i.RecipeID = r.RecipeID;
END;
GO

/* Seed basic lookup data */
INSERT INTO dbo.FamilyMembers (DisplayName, Email)
VALUES
(N'Grandma Rose', N'rose@example.com'),
(N'Alex', N'alex@example.com'),
(N'Jordan', N'jordan@example.com');

INSERT INTO dbo.Categories (CategoryName)
VALUES
(N'Breakfast'),
(N'Lunch'),
(N'Dinner'),
(N'Dessert'),
(N'Holiday');

INSERT INTO dbo.Tags (TagName)
VALUES
(N'Quick'),
(N'Kid-Friendly'),
(N'Vegetarian'),
(N'Gluten-Free'),
(N'Family Classic');

INSERT INTO dbo.Ingredients (IngredientName)
VALUES
(N'Flour'),
(N'Sugar'),
(N'Baking Powder'),
(N'Eggs'),
(N'Milk'),
(N'Butter'),
(N'Salt'),
(N'Vanilla Extract');
GO

/* Example recipe seed */
INSERT INTO dbo.Recipes (Title, Description, PrepMinutes, CookMinutes, Servings, Source, IsFavorite, CreatedByMemberID)
VALUES
(
    N'Grandma''s Pancakes',
    N'Fluffy Sunday pancakes from the handwritten family card.',
    10,
    15,
    4,
    N'Family Card Box',
    1,
    1
);

INSERT INTO dbo.RecipeCategories (RecipeID, CategoryID)
SELECT r.RecipeID, c.CategoryID
FROM dbo.Recipes r
CROSS JOIN dbo.Categories c
WHERE r.Title = N'Grandma''s Pancakes'
  AND c.CategoryName = N'Breakfast';

INSERT INTO dbo.RecipeTags (RecipeID, TagID)
SELECT r.RecipeID, t.TagID
FROM dbo.Recipes r
CROSS JOIN dbo.Tags t
WHERE r.Title = N'Grandma''s Pancakes'
  AND t.TagName IN (N'Quick', N'Family Classic');

INSERT INTO dbo.RecipeIngredients (RecipeID, IngredientID, Quantity, Unit, PrepNote, SequenceNumber)
SELECT r.RecipeID, i.IngredientID, x.Quantity, x.Unit, x.PrepNote, x.SequenceNumber
FROM dbo.Recipes r
JOIN (
    VALUES
    (N'Flour', 2.00, N'cups', NULL, 1),
    (N'Sugar', 2.00, N'tbsp', NULL, 2),
    (N'Baking Powder', 1.00, N'tbsp', NULL, 3),
    (N'Salt', 0.50, N'tsp', NULL, 4),
    (N'Milk', 1.50, N'cups', NULL, 5),
    (N'Eggs', 1.00, N'large', N'beaten', 6),
    (N'Butter', 3.00, N'tbsp', N'melted', 7),
    (N'Vanilla Extract', 1.00, N'tsp', NULL, 8)
) x(IngredientName, Quantity, Unit, PrepNote, SequenceNumber) ON 1 = 1
JOIN dbo.Ingredients i ON i.IngredientName = x.IngredientName
WHERE r.Title = N'Grandma''s Pancakes';

INSERT INTO dbo.RecipeSteps (RecipeID, StepNumber, InstructionText)
SELECT r.RecipeID, x.StepNumber, x.InstructionText
FROM dbo.Recipes r
JOIN (
    VALUES
    (1, N'Whisk dry ingredients in a large bowl.'),
    (2, N'Stir in milk, egg, melted butter, and vanilla until just combined.'),
    (3, N'Heat a lightly buttered skillet over medium heat.'),
    (4, N'Pour 1/4 cup batter per pancake and cook until bubbles form.'),
    (5, N'Flip and cook until golden brown.'),
    (6, N'Serve warm with syrup or fruit.')
) x(StepNumber, InstructionText) ON 1 = 1
WHERE r.Title = N'Grandma''s Pancakes';
GO

/* Useful starter views */
CREATE OR ALTER VIEW dbo.vw_RecipeSummary
AS
SELECT
    r.RecipeID,
    r.Title,
    r.PrepMinutes,
    r.CookMinutes,
    (r.PrepMinutes + r.CookMinutes) AS TotalMinutes,
    r.Servings,
    r.IsFavorite,
    AVG(CAST(rr.Rating AS DECIMAL(4,2))) AS AvgRating,
    COUNT(DISTINCT rr.RecipeRatingID) AS RatingCount
FROM dbo.Recipes r
LEFT JOIN dbo.RecipeRatings rr ON rr.RecipeID = r.RecipeID
GROUP BY
    r.RecipeID,
    r.Title,
    r.PrepMinutes,
    r.CookMinutes,
    r.Servings,
    r.IsFavorite;
GO

/* Example query pack */
-- 1) List favorite recipes by quickest total time
SELECT TOP (20)
    Title,
    TotalMinutes,
    Servings,
    AvgRating,
    RatingCount
FROM dbo.vw_RecipeSummary
WHERE IsFavorite = 1
ORDER BY TotalMinutes ASC, Title ASC;

-- 2) Shopping list for one recipe
SELECT
    r.Title,
    i.IngredientName,
    ri.Quantity,
    ri.Unit,
    ri.PrepNote
FROM dbo.Recipes r
JOIN dbo.RecipeIngredients ri ON ri.RecipeID = r.RecipeID
JOIN dbo.Ingredients i ON i.IngredientID = ri.IngredientID
WHERE r.Title = N'Grandma''s Pancakes'
ORDER BY ri.SequenceNumber;

-- 3) Full steps for one recipe
SELECT
    r.Title,
    rs.StepNumber,
    rs.InstructionText
FROM dbo.Recipes r
JOIN dbo.RecipeSteps rs ON rs.RecipeID = r.RecipeID
WHERE r.Title = N'Grandma''s Pancakes'
ORDER BY rs.StepNumber;
GO
