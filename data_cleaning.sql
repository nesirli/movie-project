-- ============================================================
-- Data Cleaning Script for Movies Dataset
-- Author: Nasir Nesirli
-- Date: 2024-02-12
-- Description:
--    This script performs the full data cleaning operations on
--    the movies dataset. It renames columns to standardized names,
--    creates a staging table, removes duplicates, extracts and 
--    parses year information, appends Roman numeral identifiers
--    to movie titles, trims white spaces, and converts various 
--    columns (rating, votes, runtime, and gross) to their correct 
--    data types.
--
-- Dataset Source:
--    https://www.kaggle.com/datasets/bharatnatrayn/movies-dataset-for-feature-extracion-prediction?select=movies.csv
-- ============================================================

-- --- Rename columns in the source table to standard names ---
EXEC sp_rename 'movies.MOVIES', 'Name', 'COLUMN';
EXEC sp_rename 'movies.YEAR', 'ProductionYear', 'COLUMN';
EXEC sp_rename 'movies.GENRE', 'Genre', 'COLUMN';
EXEC sp_rename 'movies.RATING', 'Rating', 'COLUMN';
EXEC sp_rename 'movies.ONE_LINE', 'Description', 'COLUMN';
EXEC sp_rename 'movies.STARS', 'Stars', 'COLUMN';
EXEC sp_rename 'movies.VOTES', 'Votes', 'COLUMN';

-- --- Verify column names and data types in the movies table ---
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'movies';

-- --- Create a staging table for data cleaning ---
CREATE TABLE movies_staging (
    id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    year NVARCHAR(50),
    genre NVARCHAR(50),
    rating DECIMAL(3,1),
    description NVARCHAR(MAX),
    stars NVARCHAR(MAX),
    votes NVARCHAR(255),
    runtime NVARCHAR(255),
    gross NVARCHAR(255)
);

-- --- Populate the staging table with data from the source ---
INSERT INTO movies_staging  
SELECT * FROM movies.dbo.movies;

-- --- Verify the number of rows inserted into the staging table ---
SELECT 
    COUNT(*)
FROM movies.dbo.movies_staging;

-- --- Preview the top 10 rows in the staging table ---
SELECT TOP (10) [id]
      ,[title]
      ,[year]
      ,[genre]
      ,[rating]
      ,[description]
      ,[stars]
      ,[votes]
      ,[runtime]
      ,[gross]
FROM [movies].[dbo].[movies_staging];

-- --- Confirm the total row count in the staging table ---
SELECT COUNT(*)
FROM movies.dbo.movies_staging; -- 9999 lines in the table, each line corresponds to one movie

-- --- Analyze unique titles and unique title-year combinations ---
SELECT COUNT(DISTINCT title)
FROM movies.dbo.movies_staging; -- returns 6428, there are 9999 lines in the table

SELECT COUNT(*)
FROM (SELECT DISTINCT title, year FROM movies.dbo.movies_staging) AS unique_movies; -- unique title and year combination returns 6503 

-- --- Identify duplicate records using ROW_NUMBER ---
WITH RankedMovies AS (
    SELECT 
	    *,
	    ROW_NUMBER() OVER(PARTITION BY title, year, description, runtime ORDER BY id) AS rn
    FROM movies.dbo.movies_staging
)
SELECT COUNT(*)
FROM RankedMovies
WHERE rn > 1;

-- --- List duplicate records ---
WITH RankedMovies AS (
    SELECT 
	    *,
	    ROW_NUMBER() OVER(PARTITION BY title, year, description, runtime ORDER BY id) AS rn
    FROM movies.dbo.movies_staging
)
SELECT *
FROM RankedMovies
WHERE rn > 1;

-- --- Delete duplicate records from the staging table ---
WITH RankedMovies AS (
    SELECT 
	    *,
	    ROW_NUMBER() OVER(PARTITION BY title, year, description, runtime ORDER BY id) AS rn
    FROM movies.dbo.movies_staging
)
DELETE FROM movies.dbo.movies_staging
WHERE id IN (
	SELECT id FROM RankedMovies WHERE rn > 1
);

-- --- Check distinct year values (some contain Roman numerals) ---
SELECT DISTINCT year FROM movies.dbo.movies_staging ORDER BY year DESC;

-- --- Add start_year and end_year columns to parse production years ---
ALTER TABLE movies.dbo.movies_staging
ADD start_year INT,
    end_year INT;

-- --- Extract and parse the production year(s) from the 'year' column ---
WITH SplitTokens AS (
    -- Replace ') (' with ')|(' to create a known delimiter, then split the string.
    SELECT
        m.id,
        m.year AS original_year,
        LTRIM(RTRIM(value)) AS token
    FROM (
        SELECT 
            id,
            year,
            REPLACE(year, ') (', ')|(') AS modified_year
        FROM movies.dbo.movies_staging
    ) m
    CROSS APPLY STRING_SPLIT(m.modified_year, '|')
),
YearToken AS (
    -- Choose the token that contains a digit right after the opening parenthesis.
    SELECT
        id,
        original_year,
        MIN(token) AS token_with_year
    FROM SplitTokens
    WHERE token LIKE '([0-9]%' OR token LIKE '(%[0-9]%'
    GROUP BY id, original_year
),
ParsedYears AS (
    -- Remove the outer parentheses from the selected token.
    SELECT
        id,
        original_year,
        SUBSTRING(token_with_year, 2, LEN(token_with_year) - 2) AS inner_token
    FROM YearToken
),
ParsedFinal AS (
    -- Extract the start and (if available) end year.
    SELECT
        id,
        -- Start year: if a dash is present, take the substring before it; otherwise, the whole token.
        TRY_CAST(
            CASE 
                WHEN CHARINDEX('–', inner_token) > 0 
                     THEN LTRIM(RTRIM(SUBSTRING(inner_token, 1, CHARINDEX('–', inner_token) - 1)))
                ELSE inner_token 
            END AS INT
        ) AS start_year,
        -- End year: if a dash is present, take the substring after it; otherwise, NULL.
        TRY_CAST(
            CASE 
                WHEN CHARINDEX('–', inner_token) > 0 
                     THEN 
                        CASE 
                            WHEN LEN(LTRIM(RTRIM(SUBSTRING(inner_token, CHARINDEX('–', inner_token) + 1, 10)))) = 0 
                                 THEN NULL
                            ELSE LTRIM(RTRIM(SUBSTRING(inner_token, CHARINDEX('–', inner_token) + 1, 10)))
                        END
                ELSE NULL 
            END AS INT
        ) AS end_year
    FROM ParsedYears
)
-- Update the staging table with the parsed production years.
UPDATE m
SET 
    m.start_year = p.start_year,
    m.end_year   = p.end_year
FROM movies.dbo.movies_staging m
JOIN ParsedFinal p 
    ON m.id = p.id;

-- --- Update movie names by appending Roman numeral tokens (if any) ---
WITH SplitTokens AS (
    -- Replace ') (' with ')|(' so we can use STRING_SPLIT with a known delimiter.
    SELECT
        m.id,
        m.title,
        m.year,
        LTRIM(RTRIM(value)) AS token
    FROM movies.dbo.movies_staging m
    CROSS APPLY STRING_SPLIT(REPLACE(m.year, ') (', ')|('), '|')
),
RomanToken AS (
    -- Keep only tokens that exactly match one of the expected Roman numeral values.
    SELECT 
         id,
         title,
         year,
         token AS roman_token
    FROM SplitTokens
    WHERE token IN (
          '(I)', '(II)', '(III)', '(IV)', '(V)', '(VI)', '(VII)', '(VIII)', '(IX)', '(X)',
          '(XI)', '(XII)', '(XIII)', '(XIV)', '(XV)', '(XVI)', '(XVII)', '(XVIII)', '(XIX)',
          '(XX)', '(XXI)', '(XXII)', '(XXIII)', '(XLI)'
    )
),
RomanTokensAgg AS (
    -- For each movie, choose one Roman numeral token (if more than one exists).
    SELECT 
         id,
         MIN(roman_token) AS roman_token  -- Using MIN to pick one (adjust if needed)
    FROM RomanToken
    GROUP BY id
)
-- Append the Roman numeral to the movie title.
UPDATE m
SET title = title + ' ' + rt.roman_token
FROM movies.dbo.movies_staging m
JOIN RomanTokensAgg rt 
    ON m.id = rt.id;

-- --- Drop the original 'year' column as it is no longer needed ---
ALTER TABLE movies.dbo.movies_staging
DROP COLUMN [year];

-- --- Create a computed column 'type' based on production year values ---
-- If a row has both start_year and end_year, it is considered a Series; otherwise, a Movie.
ALTER TABLE movies.dbo.movies_staging
ADD [type] AS (
    CASE 
        WHEN start_year IS NOT NULL AND end_year IS NOT NULL THEN 'Series'
        ELSE 'Movie'
    END
);

-- --- Check if values in text columns have unwanted white spaces ---
SELECT *
FROM movies.dbo.movies_staging
WHERE title <> LTRIM(RTRIM(title));

SELECT *
FROM movies.dbo.movies_staging
WHERE genre <> LTRIM(RTRIM(genre));

SELECT *
FROM movies.dbo.movies_staging
WHERE description <> LTRIM(RTRIM(description));

SELECT *
FROM movies.dbo.movies_staging
WHERE stars <> LTRIM(RTRIM(stars));

-- --- Update movie titles to remove leading/trailing white spaces ---
UPDATE movies.dbo.movies_staging
SET title = LTRIM(RTRIM(title));

-- --- Convert the rating column to FLOAT ---
ALTER TABLE movies.dbo.movies_staging
ALTER COLUMN rating FLOAT;

-- --- Clean and convert the votes column to INT ---
UPDATE movies.dbo.movies_staging
SET votes = REPLACE(votes, ',', '');

ALTER TABLE movies.dbo.movies_staging
ALTER COLUMN votes INT;

-- --- Convert runtime column to INT (assuming it holds numeric values as text) ---
ALTER TABLE movies.dbo.movies_staging
ALTER COLUMN runtime INT;

-- --- Check non-null values for the gross column ---
SELECT COUNT(*)
FROM movies.dbo.movies_staging
WHERE gross IS NULL;

SELECT COUNT(*)
FROM movies.dbo.movies_staging
WHERE gross IS NOT NULL;

SELECT gross
FROM movies.dbo.movies_staging
WHERE gross IS NOT NULL;

-- --- Rename the 'gross' column to 'gross(million dollars)' ---
EXEC sp_rename 'movies.dbo.movies_staging.gross', 'gross(million dollars)', 'COLUMN';

-- --- Convert gross values (formatted like "$75.47M") to numeric (millions) ---
UPDATE movies.dbo.movies_staging
SET [gross(million dollars)] = TRY_CAST(
    REPLACE(REPLACE([gross(million dollars)], '$', ''), 'M', '') 
    AS DECIMAL(10,2)
);
