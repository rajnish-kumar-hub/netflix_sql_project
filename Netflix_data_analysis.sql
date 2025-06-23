CREATE DATABASE netflix_db;
USE netflix_db;

DROP TABLE if exists netflix;
CREATE TABLE netflix(
	show_id	VARCHAR(6),
    type	VARCHAR(10),
    title	VARCHAR(150),
    director	VARCHAR(208),
    casts	VARCHAR(1000),
    country	VARCHAR(150),
    date_added	VARCHAR (50),
    release_year	INT,
    rating	VARCHAR(10),
    duration	VARCHAR(15),
    listed_in	VARCHAR(100),
    description VARCHAR(250)
);


SELECT
	COUNT(*) AS total_content
FROM netflix;

SELECT
	DISTINCT type
FROM netflix;

-- 1. Count the number of Movies vs TV shows

SELECT
	type,
    COUNT(*) AS total_content
FROM netflix 
GROUP BY type;

-- 2. Find the most common rating for movies and TV shows
SELECT 
	type,
    rating
FROM
(SELECT
	type,
    rating,
    COUNT(*),
    RANK() OVER (PARTITION BY type ORDER BY COUNT(*) DESC) AS ranking
FROM netflix
GROUP BY type, rating) AS t1
WHERE
	ranking = 1;
    
-- 3. List all movies released in a specific year (e.g., 2020)

SELECT
	*
FROM netflix
WHERE release_year = 2020 and type = 'Movie';

-- 4. Find the top 5 countries with the most content on Netflix
-- Step 1: Split comma-separated countries using recursive CTE
WITH RECURSIVE country_split AS (
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
    CASE
      WHEN country LIKE '%,%' THEN SUBSTRING_INDEX(country, ',', -1)
      ELSE NULL
    END AS rest
  FROM netflix
  WHERE country IS NOT NULL

  UNION ALL

  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS country,
    CASE 
      WHEN rest LIKE '%,%' THEN SUBSTRING_INDEX(rest, ',', -1)
      ELSE NULL
    END AS rest
  FROM country_split
  WHERE rest IS NOT NULL
)

SELECT 
  country,
  COUNT(*) AS total_content
FROM country_split
GROUP BY country
ORDER BY total_content DESC
LIMIT 5;

-- 5. Identify the longest movie?
SELECT
	*
FROM netflix
WHERE 
	type = 'Movie'
    AND
    duration = (SELECT MAX(duration) FROM netflix);
    
-- 6. Find content added in the last 5 years

ALTER TABLE netflix ADD COLUMN date_added_clean DATE;
UPDATE netflix
SET date_added_clean = STR_TO_DATE(date_added, '%M %d, %Y')
WHERE date_added IS NOT NULL
  AND date_added != ''
  AND date_added REGEXP '^[A-Za-z]+ [0-9]{1,2}, [0-9]{4}$';

SELECT *
FROM netflix
WHERE date_added_clean >= CURDATE() - INTERVAL 5 YEAR;

-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'.
SELECT 
	*
FROM netflix 
WHERE director LIKE '%Rajiv Chilaka%';

-- 8. List all TV shows with more than 5 seasons
SELECT *
FROM (
    SELECT *,
           CAST(REGEXP_SUBSTR(duration, '[0-9]+') AS UNSIGNED) AS season
    FROM netflix
    WHERE type = 'TV Show'
) AS sub
WHERE season > 5;

-- 9. Count the number of content items in each genre.
-- Step 1: Split the genres into individual rows using Recursive CTE
WITH RECURSIVE genre_split AS (
  SELECT
    show_id,
    TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
    SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS rest
  FROM netflix

  UNION ALL

  SELECT
    show_id,
    TRIM(SUBSTRING_INDEX(rest, ',', 1)),
    SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2)
  FROM genre_split
  WHERE rest != ''
)

-- Step 2: Group by genre and count
SELECT 
  genre,
  COUNT(show_id) AS content_count
FROM genre_split
GROUP BY genre
ORDER BY content_count DESC;

-- 10. Find each year and the average numbers of content release in India on netflix. 
-- Return top 5 year with highest avg content release

SELECT
      YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS date,
      COUNT(*) AS content_release_per_year,
      ROUND(COUNT(*)/ (SELECT COUNT(*) FROM netflix WHERE country = 'India') * 100,2) AS avg_content_release_per_year
FROM netflix
WHERE country = 'India'
GROUP BY date
ORDER BY content_release_per_year DESC;

-- 11. List all movies that are documentaries
SELECT
	*
FROM netflix 
WHERE
	listed_in LIKE '%Documentaries%';
    
-- 12. Find all content without a director
SELECT 
	*
FROM netflix 
WHERE director IS NULL OR director LIKE '';
	
-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years
SELECT 
	*
FROM netflix 
WHERE 
	casts LIKE '%Salman Khan%'
    AND 
    release_year > YEAR(CURDATE()) - 10;

-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India
WITH RECURSIVE cast_split AS (
  -- Step 1: Start splitting cast names for Indian Movies
  SELECT
    show_id,
    TRIM(SUBSTRING_INDEX(casts, ',', 1)) AS actor,
    SUBSTRING(casts, LENGTH(SUBSTRING_INDEX(casts, ',', 1)) + 2) AS rest
  FROM netflix
  WHERE type = 'Movie' AND country LIKE '%India%' AND casts IS NOT NULL AND casts != ''

  UNION ALL

  -- Step 2: Recursively extract remaining cast names
  SELECT
    show_id,
    TRIM(SUBSTRING_INDEX(rest, ',', 1)) AS actor,
    SUBSTRING(rest, LENGTH(SUBSTRING_INDEX(rest, ',', 1)) + 2) AS rest
  FROM cast_split
  WHERE rest IS NOT NULL AND rest != ''
)

-- Step 3: Group by actor and count how many movies they appeared in
SELECT 
  actor,
  COUNT(DISTINCT show_id) AS movie_count
FROM cast_split
GROUP BY actor
ORDER BY movie_count DESC
LIMIT 10;

-- 15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field. 
-- Label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category. 

WITH new_table AS(
SELECT
	*,
    CASE
		WHEN 
			description LIKE '%kill%' OR
            description LIKE '%violence' THEN 'Bad_content'
            ELSE 'Good Content'
	END category
FROM netflix
)
SELECT 
	category,
    COUNT(*) AS total_content
FROM new_table
GROUP BY category;





