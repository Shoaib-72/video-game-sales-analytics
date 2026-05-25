-- Quick look at the data

SELECT * FROM game_data LIMIT 10;
SELECT COUNT(*) AS total_rows FROM game_data;

SELECT MIN(release_year), MAX(release_year),
       MIN(critic_score),  MAX(critic_score),
       MIN(total_sales),   MAX(total_sales)
FROM game_data;

-- Check for nulls
SELECT
  SUM(CASE WHEN na_sales    IS NULL THEN 1 ELSE 0 END) AS na_nulls,
  SUM(CASE WHEN jp_sales    IS NULL THEN 1 ELSE 0 END) AS jp_nulls,
  SUM(CASE WHEN pal_sales   IS NULL THEN 1 ELSE 0 END) AS pal_nulls,
  SUM(CASE WHEN other_sales IS NULL THEN 1 ELSE 0 END) AS other_nulls,
  SUM(CASE WHEN release_year IS NULL THEN 1 ELSE 0 END) AS year_nulls
FROM game_data;

-- top 10 selling games
select title,console,total_sales
from game_data
order by total_sales desc
limit 10;

-- sales by genre
select genre,
count(*) as num_games,
round(sum(total_sales),2)as total_sales_M,
round(avg(total_sales),2)as Avg_sales_M,
round(avg(critic_score),2)as avg_score
from game_data
group by genre
order by total_sales_M desc;

-- sales by console
select console,
count(*) as num_games,
round(sum(total_sales),2)as total_sales_M
from game_data
group by console
order by total_sales_M desc;

-- regional sales
select genre,
round(sum(na_sales),2) as north_america_M,
round(sum(pal_sales),2) as europe_M,
round(sum(jp_sales),2) as japan_M,
round(sum(other_sales),2) as other_M
from game_data
where na_sales is not null
group by genre
order by north_america_M desc;

-- sales trend by year
SELECT
  release_year,
  COUNT(*) AS games_released,
  ROUND(SUM(total_sales), 2)  AS total_sales_M,
  ROUND(AVG(critic_score), 2) AS avg_score
FROM game_data
WHERE release_year IS NOT NULL
GROUP BY release_year
ORDER BY release_year;

-- Top publishers by total sales
select publisher,
count(*) as num_games,
round(sum(total_sales),2) as total_sales_M,
round(avg(critic_score),2) as avg_score
from game_data
group by publisher
order by total_sales_M desc
limit 10;

-- running total_sales
WITH yearly AS (
  SELECT
    release_year,
    ROUND(SUM(total_sales), 2) AS yr_sales
  FROM game_data
  WHERE release_year IS NOT NULL
  GROUP BY release_year
)
SELECT
  release_year,
  yr_sales,
  ROUND(
    SUM(yr_sales) OVER (
      ORDER BY release_year
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)  AS running_total
FROM yearly
ORDER BY release_year;

-- Genre performance: sales + regional breakdown
WITH genre_stats AS (
  SELECT
    genre,
    COUNT(*)                          AS num_games,
    ROUND(SUM(total_sales), 2)        AS total_sales,
    ROUND(SUM(na_sales), 2)           AS na_sales,
    ROUND(SUM(jp_sales), 2)           AS jp_sales,
    ROUND(SUM(pal_sales), 2)          AS pal_sales,
    ROUND(AVG(critic_score), 2)       AS avg_score
  FROM game_data
  GROUP BY genre
)
SELECT
  genre,
  num_games,
  total_sales,
  ROUND(na_sales  / total_sales * 100, 1) AS na_pct,
  ROUND(jp_sales  / total_sales * 100, 1) AS jp_pct,
  ROUND(pal_sales / total_sales * 100, 1) AS pal_pct,
  avg_score
FROM genre_stats
ORDER BY total_sales DESC;

-- Rank games by sales within each genre
SELECT
  genre,
  title,
  console,
  total_sales,
  RANK() OVER (
    PARTITION BY genre
    ORDER BY total_sales DESC
  ) AS rank_in_genre
FROM game_data
ORDER BY genre, rank_in_genre
LIMIT 40;
