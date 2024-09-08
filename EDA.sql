
/* EDA - Check for NULL values */

SELECT
	COUNT(*)
FROM customers
WHERE customer_name IS NULL
	OR reg_date IS NULL;

SELECT
	COUNT(*)
FROM restaurants
WHERE restaurant_name IS NULL
	OR city IS NULL
	OR opening_hours IS NULL;

SELECT
	*
FROM orders
WHERE order_item IS NULL
	OR order_date IS NULL
	OR order_time IS NULL
	OR order_status IS NULL
	OR total_amount IS NULL;


/* EDA through answering 20 business questions.
   Question 1 is worm up and not a business question                */

/* 1. Find the top 5 most frequently ordered dishes by customer called
	  "Arjun Mehta" in the last 1 year.
		- Calculate dish distrabution per customer + Rank them DESC
		- Filter by name, chosen date range and top 5 ranks          */                                    
SELECT
	customer_name,
	order_item,
	score
FROM
	(SELECT
		c.customer_name,
		o.order_item,
		COUNT(o.order_item) AS popularity,
		ROW_NUMBER() OVER(PARTITION BY customer_name ORDER BY COUNT(o.order_item) DESC) AS score
		FROM orders AS o
		LEFT JOIN customers AS c
			ON o.customer_id = c.customer_id
		WHERE customer_name = 'Arjun Mehta'
			AND o.order_date >= CURRENT_DATE - INTERVAL '1 Year'
		GROUP BY c.customer_name,
			o.order_item
		ORDER by c.customer_name, score) AS sub_query
WHERE score <= 5;
  
/* 2. Popular Time Slots
	  Identify the time slots during which the most orders are placed.
	  based on 2-hour intervals.
	    - Divied order_time into 2-hour intrevals --> Normalization */
SELECT 
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 AS start_time,
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 + 2 AS end_time,
	COUNT(*) as total_orders
FROM orders
GROUP BY start_time,
	end_time
ORDER BY total_orders DESC;

/* 3. Order Value Analysis (customer_name and aov)
      Find the average order value(aov) per customer who has placed
	  more than 750 orders.
	    - Avg order value per customer
		- Filter >= 750                                              */
SELECT
	c.customer_name,
	COUNT(o.order_id) AS orders,
	ROUND(AVG(o.total_amount), 2) AS aov
FROM orders AS o
LEFT JOIN customers AS c
	ON o.customer_id = c.customer_id
GROUP BY c.customer_name
HAVING COUNT(o.order_id) > 750;

/* 4. High-Value Customers (customer_name, customer_id)
	  List the customers who have spent more than 100K in total on food
	  orders.                                                  	  */
SELECT
	c.customer_name,
	SUM(o.total_amount) AS sov
FROM orders AS o
LEFT JOIN customers AS c
	On o.customer_id = c.customer_id
GROUP BY customer_name
HAVING SUM(o.total_amount) > 100000
ORDER BY SUM(o.total_amount) DESC;

/* 5. Orders Without Delivery
	  Write a query to find orders that were placed but not delivered. 
	  Return each restuarant name, city and number of not delivered
	  orders                                                        */
SELECT 
	r.restaurant_name,
	r.city,
	COUNT(d.delivery_status) AS not_delivered
FROM orders AS o
LEFT JOIN deliveries AS d
	ON o.order_id = d.order_id
LEFT JOIN restaurants AS r
	ON o.restaurant_id = r.restaurant_id
WHERE d.delivery_status = 'Not Delivered'
GROUP BY r.restaurant_name,
	     r.city
ORDER BY not_delivered DESC;

/* 6. Restaurant Revenue Ranking
	  Rank restaurants by their total revenue from the last year, including
	  their name, total revenue, and rank within their city.
	    - Rank total revenue by city                                     */
SELECT 
	*
FROM
	(SELECT
		r.restaurant_name,
		r.city,
		SUM(o.total_amount) AS total_revenue,
		DENSE_RANK( ) OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rank
	FROM orders AS o
	LEFT JOIN restaurants AS r
		ON o.restaurant_id = r.restaurant_id
	WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
	GROUP BY r.restaurant_name,
		r.city) AS sub_query
WHERE rank = 1
ORDER BY total_revenue DESC;

/* 7. Most Popular Dish by City
      Identifying the most popular dish in each city based on the number
	  of orders.
	    - Count total number of orders per item per city
		- Rank the total number of dishes per city                    */
SELECT
	*
FROM
	(SELECT
		r.city,
		o.order_item,
		COUNT(o.order_item) AS total,
		DENSE_RANK () OVER(PARTITION BY r.city ORDER BY COUNT(o.order_item)DESC) AS rank
	FROM orders AS o
	LEFT JOIN restaurants AS r
		ON o.restaurant_id = r.restaurant_id
	GROUP BY r.city,
		     o.order_item) AS sub_query
WHERE rank = 1
ORDER BY total DESC
;	  

/* 8. Customer Churn: 
      Find customers who haven’t placed an order in 2024 but did in 2023.
	  - Find customers that placed an order in 2023
	  - Find "               -               " 2024
	  - In 2023 NOT IN 2024                                            */
SELECT DISTINCT
	 customer_id
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2023
	AND customer_id NOT IN (SELECT DISTINCT customer_id FROM orders
							 	WHERE EXTRACT(year FROM order_date) = 2024);

/* 9. Cancellation Rate Comparison
      Calc and compare the order cancellation rate for each restaurant between the
	  current year and the previous year.
	    - Calc cancel ratio by year 
		- Join 2023 & 2024                                                      */
WITH cancel_ratio_2024 AS (
	SELECT
		r.restaurant_id,
		r.restaurant_name,
		ROUND(COUNT(CASE WHEN o.order_status = 'Not Fulfilled' THEN 1 END)::NUMERIC/COUNT(o.order_status) * 100, 2) AS cancellation
	FROM orders AS o
	JOIN restaurants AS r
		ON o.restaurant_id = r.restaurant_id
	WHERE EXTRACT(YEAR FROM o.order_date) = 2024
	GROUP BY r.restaurant_id, r.restaurant_name),
	
cancel_ratio_2023 AS (
	SELECT
		r.restaurant_id,
		r.restaurant_name,
		ROUND(COUNT(CASE WHEN o.order_status = 'Not Fulfilled' THEN 1 END)::NUMERIC/COUNT(o.order_status) * 100, 2) AS cancellation
	FROM orders AS o
	JOIN restaurants AS r
		ON o.restaurant_id = r.restaurant_id
	WHERE EXTRACT(YEAR FROM o.order_date) = 2023
	GROUP BY r.restaurant_id, r.restaurant_name)

SELECT 
	c23.restaurant_id,
	c23.restaurant_name,
	c23.cancellation AS cancel_23,
	coalesce(c24.cancellation, 0) AS cancel_24
FROM cancel_ratio_2023 AS c23
FULL JOIN cancel_ratio_2024 AS c24
	ON c23.restaurant_id = c24.restaurant_id
ORDER BY c23.restaurant_id;

/* 10. Rider Average Delivery Time
       Determine each rider's average delivery time. */
SELECT
--	o.order_id,
	d.rider_id,
--	o.order_time,
--	d.delivery_time,
--	d.delivery_time - o.order_time,
	AVG(CASE WHEN d.delivery_time < o.order_time THEN d.delivery_time - o.order_time + INTERVAL '24 hours' ELSE d.delivery_time - o.order_time END) AS diff_corrected
FROM orders AS o
LEFT JOIN deliveries AS d
	ON o.order_id = d.order_id
LEFT JOIN riders AS r
	ON d.rider_id = r.rider_id
WHERE d.delivery_status = 'Delivered'
GROUP BY 1
ORDER BY 1;

/* 11. Monthly Restaurant Growth Ratio
       Calculate each restaurant's growth ratio based on the total number of
	   delivered orders since its joining
	     - Break down by mm-yy
		 - Monthly orders and previous monthly orders
		 - Calc growth ration                                             */
WITH order_count AS (
	SELECT
	o.restaurant_id AS rest_id,
	TO_CHAR(o.order_date, 'mm-yy') AS mm_yy,
	COUNT(o.order_id) AS cr_count,
	LAG(COUNT(o.order_id), 1) OVER(PARTITION BY o.restaurant_id ORDER BY TO_CHAR(o.order_date, 'mm-yy'))::NUMERIC AS prv_count
	FROM deliveries AS d
	FULL JOIN orders AS o
		ON	d.order_id = o.order_id
	WHERE d.delivery_status = 'Delivered'
	GROUP BY 1,2
	ORDER BY 1,2) 

SELECT 
	rest_id,
	mm_yy,
	cr_count,
	prv_count,
	ROUND((cr_count - prv_count)::NUMERIC/prv_count * 100, 2) AS ratio
FROM order_count;
	
/* 12. Customer Segmentation
       Segment customers into 'Gold' or 'Silver' groups based on their total spending
       compare to the average order value (AOV)                                    */
WITH segment_prep AS (
	SELECT
		customer_id,
		COUNT(order_id) AS total_orders,
		SUM(total_amount) AS total_spent,
		ROUND((SELECT SUM(total_amount)/COUNT(order_id) FROM orders), 2) AS aov
		FROM orders
		GROUP BY customer_id)

SELECT
	customer_id,
	total_orders,
	total_spent,
	aov,
	CASE WHEN total_spent > aov THEN 'Gold' ELSE 'Silver' END AS segment
	FROM segment_prep
	ORDER BY total_spent DESC;

/* 13. Rider Monthly Earnings
 	   Rider's total monthly earnings, assuming they earn 8% of the order
	   amount                                                          */
SELECT
	d.rider_id,
	TO_CHAR(o.order_date, 'mm-yy') AS mm_yy,
	ROUND(SUM(o.total_amount) * 0.08, 2) AS montly_earnings
FROM orders AS o
JOIN deliveries AS d
	ON o.order_id = d.order_id
GROUP BY 1,2
ORDER BY 1,2;

/* 14. Rider Ratings Analysis
       5-star (>15 mins), 4-star (15-20 mins), and 3-star (<20 mins) ratings
       based on delivery time.
	     - Calc delivery time of each delivered order
		 - Rank each delivery (5/4/3 stars)
		 - Group by rider and star count                                   */
WITH rider_star AS (SELECT
	rider_id,
	CASE WHEN time_to_deliver < INTERVAL '15 minutes' THEN '5 stars'
		WHEN time_to_deliver BETWEEN INTERVAL '15 minutes' AND INTERVAL '20 minutes' THEN '4 stars'
		ELSE '3 stars' END AS stars,
	time_to_deliver
FROM (
SELECT
	d.rider_id,
	o.order_date,
	o.order_time,
	d.delivery_time,
	CASE WHEN d.delivery_time < o.order_time
		THEN d.delivery_time - o.order_time + INTERVAL '24 hours'
		ELSE d.delivery_time - o.order_time END AS time_to_deliver
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
ORDER BY 1,2,3,4) AS sub)

SELECT
	rider_id,
	stars,
	COUNT(stars) AS total_stars
FROM rider_star
GROUP BY rider_id, Stars
ORDER BY rider_id, stars DESC;

/* 15. Order Frequency by Day
       Order frequency per day of the week + identifiction of the peak day for
	   each restaurant.                                                     */
SELECT 
	*
FROM (
	SELECT
		restaurant_id,
		TO_CHAR(order_date, 'Dy') AS day,
		COUNT(order_id) AS total_orders,
		DENSE_RANK() OVER(PARTITION BY restaurant_id ORDER BY COUNT(order_id) DESC) AS peak_rank
	FROM orders
	GROUP BY 1,2
	ORDER BY 1,2) AS sub
WHERE peak_rank = 1;

/* 16. Customer Lifetime Value (CLV):
       Total revenue generated by each customer over all their orders.      */
SELECT 
	o.customer_id,
	c.customer_name,
	SUM(o.total_amount) AS clv
FROM orders AS o
LEFT JOIN customers AS c
	ON o.customer_id = c.customer_id
GROUP BY 1,2
ORDER BY 1;

/* 17. Monthly Sales Trends
       Identification of sale trends by comparing each month's total sales
	   to the previous month.                                               */
SELECT
	restaurant_id,
	TO_CHAR(order_date, 'mm-yy') AS cr_month,
	SUM(total_amount) AS montly_total,
	LAG(SUM(total_amount), 1) OVER(PARTITION BY restaurant_id ORDER BY	TO_CHAR(order_date, 'mm-yy')) AS pr_month
FROM orders
GROUP BY 1,2
ORDER BY 1,2;

/* 18. Rider Efficiency
       Rider efficiency evaluation by determining average delivery times and
	   identifying those with the lowest and highest averages.             */
WITH rider_time_deliveries AS (
	SELECT
		-- o.order_id,	
		-- o.order_date,
		-- o.order_time,
		-- d.delivery_time,
		d.rider_id,
		CASE WHEN d.delivery_time < o.order_time THEN d.delivery_time - o.order_time + INTERVAL '24 hours'
			ELSE d.delivery_time - o.order_time END AS time_to_deliver
	FROM orders AS o
	JOIN deliveries AS d
		ON o.order_id = d.order_id
	WHERE d.delivery_status = 'Delivered'),

avg_times AS (
	SELECT
		rider_id,
		DATE_TRUNC('minutes', AVG(time_to_deliver)) AS avg_time
	FROM rider_time_deliveries
	GROUP BY 1
	ORDER BY 1)

SELECT
	MIN(avg_time) AS min_time,
	MAX(avg_time) AS max_time
FROM avg_times;

/* 19. Order Item Popularity
       Tracking the popularity of specific order items over time and identify
	   seasonal demand spikes.                                             */
SELECT
	order_item,
	COUNT(order_item) AS total_orders,
	-- TO_CHAR(order_date, 'mm') AS month,
	CASE WHEN TO_CHAR(order_date, 'mm') IN ('12','01','02') THEN 'winter'
		WHEN TO_CHAR(order_date, 'mm') BETWEEN '03' AND '05' THEN 'spring'
		WHEN TO_CHAR(order_date, 'mm') BETWEEN '06' AND '08' THEN 'summar'
		WHEN TO_CHAR(order_date, 'mm') BETWEEN '09' AND '11' THEN 'autumn' END AS season
FROM orders
GROUP BY 1,3
ORDER BY 1,2;

/* 20. The rank of each city based on the total revenue for last year 2023 */
SELECT
	r.city,
	SUM(total_amount) AS total_amount,
	DENSE_RANK() OVER(ORDER BY SUM(total_amount) DESC) AS rank
FROM orders AS o
LEFT JOIN restaurants AS r
	ON o.restaurant_id = r.restaurant_id
WHERE TO_CHAR(o.order_date, 'yyyy') = '2023'
GROUP BY r.city
ORDER BY 2 DESC;