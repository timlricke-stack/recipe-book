/*
Family Recipe Book Operations Pack
Target: Microsoft SQL Server 2025
Applies to: FamilyRecipeBook database created by family_recipe_book.sql
*/

SET NOCOUNT ON;
GO

IF DB_ID(N'FamilyRecipeBook') IS NULL
BEGIN
    THROW 50000, 'FamilyRecipeBook database not found. Run family_recipe_book.sql first.', 1;
END;
GO

USE FamilyRecipeBook;
GO

/* 1) Focused database status report */
CREATE OR ALTER PROCEDURE dbo.usp_DatabaseStatus
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.name AS DatabaseName,
        d.state_desc AS DatabaseState,
        d.recovery_model_desc AS RecoveryModel,
        d.user_access_desc AS UserAccess,
        d.compatibility_level AS CompatibilityLevel,
        d.collation_name AS CollationName,
        d.create_date AS CreatedDate,
        d.is_read_only AS IsReadOnly,
        d.is_auto_close_on AS IsAutoCloseOn,
        d.is_auto_shrink_on AS IsAutoShrinkOn,
        d.is_fulltext_enabled AS IsFullTextEnabled,
        CAST(SUM(CASE WHEN mf.type_desc = 'ROWS' THEN mf.size END) * 8.0 / 1024 AS DECIMAL(18,2)) AS DataSizeMB,
        CAST(SUM(CASE WHEN mf.type_desc = 'LOG' THEN mf.size END) * 8.0 / 1024 AS DECIMAL(18,2)) AS LogSizeMB,
        CAST(SUM(mf.size) * 8.0 / 1024 AS DECIMAL(18,2)) AS TotalSizeMB,
        MAX(CASE WHEN bs.type = 'D' THEN bs.backup_finish_date END) AS LastFullBackup,
        MAX(CASE WHEN bs.type = 'I' THEN bs.backup_finish_date END) AS LastDiffBackup,
        MAX(CASE WHEN bs.type = 'L' THEN bs.backup_finish_date END) AS LastLogBackup
    FROM master.sys.databases d
    LEFT JOIN master.sys.master_files mf
        ON mf.database_id = d.database_id
    LEFT JOIN msdb.dbo.backupset bs
        ON bs.database_name = d.name
    WHERE d.name = DB_NAME()
    GROUP BY
        d.name,
        d.state_desc,
        d.recovery_model_desc,
        d.user_access_desc,
        d.compatibility_level,
        d.collation_name,
        d.create_date,
        d.is_read_only,
        d.is_auto_close_on,
        d.is_auto_shrink_on,
        d.is_fulltext_enabled;
END;
GO

/* 2) Full-text search support for recipe titles + steps */
IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'RecipeCatalog')
BEGIN
    CREATE FULLTEXT CATALOG RecipeCatalog AS DEFAULT;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Recipes') AND name = N'UX_Recipes_RecipeID_FT')
BEGIN
    CREATE UNIQUE INDEX UX_Recipes_RecipeID_FT ON dbo.Recipes(RecipeID);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.RecipeSteps') AND name = N'UX_RecipeSteps_RecipeStepID_FT')
BEGIN
    CREATE UNIQUE INDEX UX_RecipeSteps_RecipeStepID_FT ON dbo.RecipeSteps(RecipeStepID);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.Recipes'))
BEGIN
    CREATE FULLTEXT INDEX ON dbo.Recipes
    (
        Title LANGUAGE 1033,
        Description LANGUAGE 1033
    )
    KEY INDEX UX_Recipes_RecipeID_FT
    WITH CHANGE_TRACKING AUTO;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.RecipeSteps'))
BEGIN
    CREATE FULLTEXT INDEX ON dbo.RecipeSteps
    (
        InstructionText LANGUAGE 1033
    )
    KEY INDEX UX_RecipeSteps_RecipeStepID_FT
    WITH CHANGE_TRACKING AUTO;
END;
GO

/* 3) Create recipe core record */
CREATE OR ALTER PROCEDURE dbo.usp_CreateRecipe
    @Title NVARCHAR(200),
    @Description NVARCHAR(1000) = NULL,
    @PrepMinutes INT = 0,
    @CookMinutes INT = 0,
    @Servings INT = NULL,
    @Source NVARCHAR(300) = NULL,
    @IsFavorite BIT = 0,
    @CreatedByMemberID INT = NULL,
    @RecipeID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Recipes
    (
        Title,
        Description,
        PrepMinutes,
        CookMinutes,
        Servings,
        Source,
        IsFavorite,
        CreatedByMemberID
    )
    VALUES
    (
        @Title,
        @Description,
        @PrepMinutes,
        @CookMinutes,
        @Servings,
        @Source,
        @IsFavorite,
        @CreatedByMemberID
    );

    SET @RecipeID = CAST(SCOPE_IDENTITY() AS INT);
END;
GO

/* 4) Update recipe core fields */
CREATE OR ALTER PROCEDURE dbo.usp_UpdateRecipe
    @RecipeID INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(1000) = NULL,
    @PrepMinutes INT,
    @CookMinutes INT,
    @Servings INT = NULL,
    @Source NVARCHAR(300) = NULL,
    @IsFavorite BIT,
    @CreatedByMemberID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Recipes
    SET
        Title = @Title,
        Description = @Description,
        PrepMinutes = @PrepMinutes,
        CookMinutes = @CookMinutes,
        Servings = @Servings,
        Source = @Source,
        IsFavorite = @IsFavorite,
        CreatedByMemberID = @CreatedByMemberID
    WHERE RecipeID = @RecipeID;

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 50001, 'Recipe not found for update.', 1;
    END;
END;
GO

/* 5) Keyword search (prefers full-text if installed) */
CREATE OR ALTER PROCEDURE dbo.usp_SearchRecipes
    @SearchText NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    IF @SearchText IS NULL OR LTRIM(RTRIM(@SearchText)) = N''
    BEGIN
        THROW 50002, 'Search text is required.', 1;
    END;

    DECLARE @HasFullText BIT = 0;

    IF EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.Recipes'))
       AND EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.RecipeSteps'))
    BEGIN
        SET @HasFullText = 1;
    END;

    IF @HasFullText = 1
    BEGIN
        SELECT DISTINCT
            r.RecipeID,
            r.Title,
            r.Description,
            r.PrepMinutes,
            r.CookMinutes,
            (r.PrepMinutes + r.CookMinutes) AS TotalMinutes,
            r.Servings,
            r.IsFavorite
        FROM dbo.Recipes r
        LEFT JOIN dbo.RecipeSteps rs ON rs.RecipeID = r.RecipeID
        WHERE CONTAINS((r.Title, r.Description), @SearchText)
           OR CONTAINS(rs.InstructionText, @SearchText)
        ORDER BY r.Title;
    END
    ELSE
    BEGIN
        DECLARE @LikePattern NVARCHAR(4010) = N'%' + @SearchText + N'%';

        SELECT DISTINCT
            r.RecipeID,
            r.Title,
            r.Description,
            r.PrepMinutes,
            r.CookMinutes,
            (r.PrepMinutes + r.CookMinutes) AS TotalMinutes,
            r.Servings,
            r.IsFavorite
        FROM dbo.Recipes r
        LEFT JOIN dbo.RecipeSteps rs ON rs.RecipeID = r.RecipeID
        WHERE r.Title LIKE @LikePattern
           OR r.Description LIKE @LikePattern
           OR rs.InstructionText LIKE @LikePattern
        ORDER BY r.Title;
    END;
END;
GO

/* 6) Simple maintenance helper: update stats + index reorg/rebuild */
CREATE OR ALTER PROCEDURE dbo.usp_MaintainRecipeBook
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SchemaName SYSNAME;
    DECLARE @TableName SYSNAME;
    DECLARE @ObjectId INT;

    DECLARE table_cursor CURSOR FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables t
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName, @ObjectId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql NVARCHAR(MAX);

        SET @sql = N'UPDATE STATISTICS ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N' WITH FULLSCAN;';
        EXEC sys.sp_executesql @sql;

        SET @sql = N'ALTER INDEX ALL ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N' REORGANIZE;';
        EXEC sys.sp_executesql @sql;

        FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName, @ObjectId;
    END;

    CLOSE table_cursor;
    DEALLOCATE table_cursor;
END;
GO

/* 7) Example executions */
-- EXEC dbo.usp_DatabaseStatus;
-- DECLARE @NewRecipeID INT;
-- EXEC dbo.usp_CreateRecipe
--     @Title = N'Weeknight Chili',
--     @Description = N'Quick one-pot family chili.',
--     @PrepMinutes = 15,
--     @CookMinutes = 35,
--     @Servings = 6,
--     @Source = N'Family Notes',
--     @IsFavorite = 0,
--     @CreatedByMemberID = 2,
--     @RecipeID = @NewRecipeID OUTPUT;
-- SELECT @NewRecipeID AS NewRecipeID;
-- EXEC dbo.usp_SearchRecipes @SearchText = N'"pancakes"';
-- EXEC dbo.usp_MaintainRecipeBook;
GO
