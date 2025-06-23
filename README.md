# Netflix Movies and TV Show Data Analysis using SQL

![Netflix Logo](https://github.com/rajnish-kumar-hub/netflix_sql_project/blob/main/logo.png)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset
- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);
```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
SELECT 
    type,
    COUNT(*)
FROM netflix
GROUP BY 1;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
WITH RatingCounts AS (
    SELECT 
        type,
        rating,
        COUNT(*) AS rating_count
    FROM netflix
    GROUP BY type, rating
),
RankedRatings AS (
    SELECT 
        type,
        rating,
        rating_count,
        RANK() OVER (PARTITION BY type ORDER BY rating_count DESC) AS rank
    FROM RatingCounts
)
SELECT 
    type,
    rating AS most_frequent_rating
FROM RankedRatings
WHERE rank = 1;
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
SELECT * 
FROM netflix
WHERE release_year = 2020;
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix
```sql
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
```
**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie
```sql
SELECT
	*
FROM netflix
WHERE 
  type = 'Movie'
  AND
  duration = (SELECT MAX(duration) FROM netflix);
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years
```sql
ALTER TABLE netflix ADD COLUMN date_added_clean DATE;
UPDATE netflix
SET date_added_clean = STR_TO_DATE(date_added, '%M %d, %Y')
WHERE date_added IS NOT NULL
  AND date_added != ''
  AND date_added REGEXP '^[A-Za-z]+ [0-9]{1,2}, [0-9]{4}$';

SELECT *
FROM netflix
WHERE date_added_clean >= CURDATE() - INTERVAL 5 YEAR;
```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'
```sql
SELECT 
	*
FROM netflix 
WHERE director LIKE '%Rajiv Chilaka%';
```
**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons
```sql
SELECT *
FROM (
    SELECT *,
           CAST(REGEXP_SUBSTR(duration, '[0-9]+') AS UNSIGNED) AS season
    FROM netflix
    WHERE type = 'TV Show'
) AS sub
WHERE season > 5;
```
**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre
```sql
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
```
**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
### return top 5 year with highest avg content release!
```sql
SELECT
      YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS date,
      COUNT(*) AS content_release_per_year,
      ROUND(COUNT(*)/ (SELECT COUNT(*) FROM netflix WHERE country = 'India') * 100,2) AS avg_content_release_per_year
FROM netflix
WHERE country = 'India'
GROUP BY date
ORDER BY content_release_per_year DESC;
```
**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries
```sql
SELECT
	*
FROM netflix 
WHERE
	listed_in LIKE '%Documentaries%';
```
**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director
```sql
SELECT 
	*
FROM netflix 
WHERE director IS NULL OR director LIKE '';
```
**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years
```sql
SELECT 
	*
FROM netflix 
WHERE 
	casts LIKE '%Salman Khan%'
    AND 
    release_year > YEAR(CURDATE()) - 10;
```
**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India
```sql
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
```
**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords
```sql
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
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.



## Author - Rajnish Kumar

This project is part of my portfolio, showcasing the SQL skills essential for data analyst roles. If you have any questions, feedback, or would like to collaborate, feel free to get in touch!


- **YouTube**: [Subscribe to my channel for tutorials and insights](https://www.youtube.com/@zero_analyst)
- **Instagram**: [Follow me for daily tips and updates](https://www.instagram.com/zero_analyst/)
- **LinkedIn**: [Connect with me professionally](https://www.linkedin.com/in/najirr)
- **Discord**: [Join our community to learn and grow together](https://discord.gg/36h5f2Z5PK)

Thank you for your support, and I look forward to connecting with you!
