-- Rank films by their length and create an output table that includes the title, length, and rank columns only. Filter out any rows with null or zero values in the length column.

USE sakila;
SELECT * FROM film;
SELECT title, length,
ROW_NUMBER() OVER(ORDER BY length DESC) AS "film_length_rank"
FROM film
WHERE length IS NOT NULL AND length > 0;

-- Rank films by length within the rating category and create an output table that includes the title, length, rating and rank columns only. Filter out any rows with null or zero values in the length column.
SELECT 
    title, 
    length, 
    rating, 
    ROW_NUMBER() OVER (PARTITION BY rating ORDER BY length DESC) AS film_length_rank
FROM 
    film
WHERE 
    length IS NOT NULL AND length > 0;
    
-- Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films, as well as the total number of films in which they have acted. Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.

WITH ActorFilmCounts AS (
    SELECT
        film_actor.actor_id,
        COUNT(DISTINCT film_actor.film_id) AS total_films
    FROM
        film_actor
    GROUP BY
        film_actor.actor_id
),
FilmActorWithRanks AS (
    SELECT
        film.film_id,
        film.title,
        film_actor.actor_id,
        actor.first_name,
        actor.last_name,
        ActorFilmCounts.total_films,
        ROW_NUMBER() OVER (PARTITION BY film.film_id ORDER BY ActorFilmCounts.total_films DESC) AS `rank`
    FROM
        film_actor
    JOIN film ON film_actor.film_id = film.film_id
    JOIN ActorFilmCounts ON film_actor.actor_id = ActorFilmCounts.actor_id
    JOIN actor ON film_actor.actor_id = actor.actor_id
)
SELECT
    FilmActorWithRanks.title AS film_title,
    CONCAT(FilmActorWithRanks.first_name, ' ', FilmActorWithRanks.last_name) AS top_actor,
    FilmActorWithRanks.total_films AS actor_total_films
FROM
    FilmActorWithRanks
WHERE
    FilmActorWithRanks.`rank` = 1
ORDER BY
    FilmActorWithRanks.title;

-- Challenge 2
-- Step 1. Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.
WITH monthly_active AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,  -- "YYYY-MM"
        COUNT(DISTINCT customer_id)       AS monthly_active_customers
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
)
SELECT *
FROM monthly_active
ORDER BY rental_month;

-- Step 2. Retrieve the number of active users in the previous month.
SELECT
    COUNT(DISTINCT customer_id) AS active_users_last_month
FROM rental
WHERE rental_date >= DATE_FORMAT(CURRENT_DATE - INTERVAL 1 MONTH, '%Y-%m-01')
  AND rental_date <  DATE_FORMAT(CURRENT_DATE, '%Y-%m-01');
  
-- Step 3. Calculate the percentage change in the number of active customers between the current and previous month.

WITH previous_month AS (
    SELECT 
        COUNT(DISTINCT customer_id) AS prev_month_count
    FROM rental
    WHERE rental_date >= DATE_FORMAT(CURRENT_DATE - INTERVAL 1 MONTH, '%Y-%m-01')
      AND rental_date <  DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
),
current_month AS (
    SELECT 
        COUNT(DISTINCT customer_id) AS current_month_count
    FROM rental
    WHERE rental_date >= DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
      AND rental_date <  DATE_FORMAT(CURRENT_DATE + INTERVAL 1 MONTH, '%Y-%m-01')
)
SELECT 
    current_month_count,
    prev_month_count,
    CASE 
        WHEN prev_month_count = 0 THEN NULL   
        ELSE (current_month_count - prev_month_count) 
              / prev_month_count * 100 
    END AS pct_change
FROM current_month, previous_month;

-- Step 4. Calculate the number of retained customers every month, i.e., customers who rented movies in the current and previous months.
WITH monthly_customers AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,  
        customer_id
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m'), customer_id
)
SELECT
    mc1.rental_month            AS current_month,
    COUNT(mc1.customer_id)      AS retained_customers
FROM monthly_customers mc1
JOIN monthly_customers mc2
    ON mc1.customer_id = mc2.customer_id
   AND mc2.rental_month = DATE_FORMAT(
                            STR_TO_DATE(CONCAT(mc1.rental_month, '-01'), '%Y-%m-%d') 
                            - INTERVAL 1 MONTH,
                            '%Y-%m'
                          )
GROUP BY mc1.rental_month
ORDER BY mc1.rental_month;
