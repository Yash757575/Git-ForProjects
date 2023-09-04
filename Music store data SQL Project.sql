/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */

SELECT first_name,last_name,title,levels FROM employee
ORDER BY levels DESC
LIMIT 1;

/* Q2: Which countries have the most Invoices? */

SELECT COUNT(*) AS c, billing_country FROM invoice
GROUP BY billing_country
ORDER BY c DESC;

/* Q3: What are top 3 values of total invoice? */

SELECT total FROM invoice
ORDER BY total DESC
LIMIT 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

SELECT billing_city, SUM(total) FROM invoice
GROUP BY billing_city
ORDER BY SUM(total) DESC
LIMIT 1;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spending 
FROM customer AS c
INNER JOIN invoice AS i 
ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY SUM(i.total) DESC
LIMIT 1;


/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */


SELECT DISTINCT c.email, c.first_name, c.last_name, g.name FROM customer AS c
INNER JOIN invoice AS i 
ON c.customer_id = i.customer_id
INNER JOIN invoice_line AS il
ON i.invoice_id = il.invoice_id
INNER JOIN track AS t
ON il.track_id = t.track_id
INNER JOIN genre AS g
ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT a.name, COUNT(a.name) FROM artist AS a
INNER JOIN album AS al 
ON a.artist_id = al.artist_id
INNER JOIN track AS t
ON al.album_id = t.album_id
INNER JOIN genre AS g
ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY a.name
ORDER BY COUNT(a.name) DESC
LIMIT 10;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name, milliseconds FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;


/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* First method*/

WITH best_selling_artists AS (
	SELECT a.artist_id, a.name AS artist_name, SUM(il.unit_price*il.quantity) AS total_spend FROM artist AS a
	INNER JOIN album AS al
	ON a.artist_id = al.artist_id
	INNER JOIN track AS t
	ON al.album_id = t.album_id
	INNER JOIN invoice_line AS il
	ON t.track_id = il.track_id
	GROUP BY 1
	ORDER BY 3 DESC
)
SELECT DISTINCT c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS total_spending FROM customer AS c
INNER JOIN invoice AS i
ON c.customer_id = i.customer_id
INNER JOIN invoice_line AS il
ON i.invoice_id = il.invoice_id
INNER JOIN track AS t
ON il.track_id = t.track_id
INNER JOIN album AS al
ON t.album_id = al.album_id
INNER JOIN best_selling_artists AS bsa
ON al.artist_id = bsa.artist_id
GROUP BY 1,2,3
ORDER BY 4 DESC;

/* Second method */

SELECT DISTINCT c.first_name, c.last_name, a.name, SUM(il.unit_price*il.quantity) AS total_spending FROM customer AS c
INNER JOIN invoice AS i
ON c.customer_id = i.customer_id
INNER JOIN invoice_line AS il
ON i.invoice_id = il.invoice_id
INNER JOIN track AS t
ON il.track_id = t.track_id
INNER JOIN album AS al
ON t.album_id = al.album_id
INNER JOIN artist AS a
ON al.artist_id = a.artist_id
GROUP BY 1,2,3
ORDER BY 4 DESC;

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

WITH popular_genre AS(
	SELECT COUNT(il.quantity) AS purchases, c.country, g.genre_id, g.name,
	ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY count(il.quantity) DESC) AS row_no
	FROM customer AS c
	INNER JOIN invoice AS i ON c.customer_id=i.customer_id
	INNER JOIN invoice_line AS il ON i.invoice_id=il.invoice_id
	INNER JOIN track AS t ON il.track_id=t.track_id
	INNER JOIN genre AS g ON t.genre_id=g.genre_id
	GROUP BY 2,3,4
	ORDER BY 2, 1 DESC 
)
SELECT * FROM popular_genre WHERE row_no<=1

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

WITH customer_with_country AS(
	SELECT c.customer_id, c.first_name, c.last_name,c.country, SUM(i.total) AS total_spending,
	ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY SUM(i.total)) AS row_no FROM customer AS c
	INNER JOIN invoice AS i ON c.customer_id=i.customer_id
	GROUP BY 1,4
	ORDER BY 4,5 DESC
) SELECT * FROM customer_with_country WHERE row_no<=1

/* Another Method using RECURSIVE*/

WITH RECURSIVE customer_with_country AS(
	SELECT c.customer_id, c.first_name,c.last_name,c.country, SUM(i.total) AS total_spending
	FROM customer AS c
	INNER JOIN invoice AS i ON c.customer_id=i.customer_id
	GROUP BY 1,4
	ORDER BY 4, 5 DESC
),
	max_spending_customer AS(
		SELECT country, MAX(total_spending) AS max_spending 
		FROM customer_with_country
		GROUP BY 1
	)
SELECT cc.country,cc.customer_id,cc.first_name, cc.last_name, cc.total_spending
FROM customer_with_country As cc
INNER JOIN max_spending_customer AS msc 
ON cc.country=msc.country
WHERE cc.total_spending=msc.max_spending
ORDER BY 1 