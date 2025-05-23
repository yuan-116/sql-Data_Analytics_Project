/*
=============================================
Data Analysis on Sales Performance and Customer Segmentation
=============================================

This SQL script performs a data analysis on a sales database created in a previous project.
It is organized into five major sections to systematically analyze sales trends, cumulative growth, product performance, contribution by category, and customer/product segmentation.

1. Change Over Time
- Analyze how sales volume, number of customers, and quantity sold change over time on a monthly basis.

2. Cumulative Analysis
- Calculate total yearly sales and track running cumulative sales growth.

3. Performance Analysis
- Evaluate yearly product performance by comparing current year sales to previous year sales and average performance, including year-over-year (YoY) comparisons.

4. Part-to-Whole Analysis
- Determine the contribution of each product category to overall sales, both in total and by year.

5. Data Segmentation
- Segment products based on cost ranges and classify customers into VIP, Regular, and New groups according to spending behavior and activity history.

This script provides a detailed breakdown of sales and customer behavior, supporting strategic business insights and reporting needs.

*/


-- 1. Change over time
-- How many bew customers wre added each year

SELECT 
	YEAR(order_date) AS order_year,
	MONTH(order_date) AS order_month,
	SUM(sales_amount) AS total_amount,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM
	gold.fact_sales
WHERE order_Date IS NOT NULL
GROUP BY YEAR(order_date),	MONTH(order_date) 
ORDER BY YEAR(order_date),	MONTH(order_date) 

--

SELECT 
	DATETRUNC(month, order_date) AS order_date,
	SUM(sales_amount) AS total_amount,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM
	gold.fact_sales
WHERE order_Date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date)
--


SELECT 
	FORMAT(order_date, 'yyyy-MMM') AS order_date,
	SUM(sales_amount) AS total_amount,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM
	gold.fact_sales
WHERE order_Date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM')

-- 2. Cumulative Analysis
-- Calculate the total sales per month
-- and the running total of sales over time

WITH years_table as(
	SELECT 
		DATETRUNC(year, order_date) AS order_year,
		SUM(sales_amount) as total_sales
	FROM
		gold.fact_sales
	WHERE
		order_date IS NOT NULL
	GROUP BY
		DATETRUNC(year, order_date)

)

SELECT 
	*,
	SUM(total_sales) OVER (ORDER BY order_year) as running_total_sales
FROM
	years_table

--
SELECT
	*,
	SUM(total_sales) OVER (ORDER BY order_year) as running_total_sales,
	AVG(moving_average_price) OVER (ORDER BY order_year) as avg_price_intheyear
FROM(
	SELECT 
		DATETRUNC(year, order_date) AS order_year,
		SUM(sales_amount) as total_sales,
		AVG(price) as moving_average_price
	FROM
		gold.fact_sales
	WHERE
		order_date IS NOT NULL
	GROUP BY
		DATETRUNC(year, order_date)
)t


-- 3. Performance Analysis
/*
Analyze the yearly performnce of products by comparing their sales to both the
average sales performance of the product and the previous year's sales
*/
WITH yearly_product_sales AS
(
	SELECT
		YEAR(order_date) AS order_year,
		p.product_name,
		SUM(s.sales_amount) AS current_sales
	FROM
		gold.fact_sales s
		LEFT JOIN gold.dim_products p ON p.product_key = s.product_key
	WHERE 
		order_date IS NOT NULL
	GROUP BY 
		YEAR(order_date), p.product_name
		
		), sales_cacultion AS(
	SELECT
		*,
		LAG(current_sales, 1) OVER (ORDER BY product_name, order_year) AS last_year_sales,
		(current_sales - LAG(current_sales, 1) OVER (ORDER BY product_name, order_year)) AS year_sales_improvment,
		AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
		AVG(current_sales) OVER(PARTITION BY product_name) - current_sales as avg_change
	FROM yearly_product_sales)
SELECT 
	*,
-- YOY anlysis
	CASE 
		WHEN year_sales_improvment > 0 THEN 'Increase'
		WHEN year_sales_improvment < 0 THEN 'Decrease'
		ELSE 'first_year or no diff'
	END sales_diff_by_year,
	CASE 
		WHEN avg_change > 0 THEN 'Above avg'
		WHEN avg_change <-0 THEN 'below avg'
		ELSE 'avg'
	END avg_change
FROM sales_cacultion


-- 4. Part-to-Whole Analysis

-- Which categories contribute the most to ovrall sales?
WITH tb_cat_sales AS(
	SELECT
		SUM(s.sales_amount) AS cat_sales,
		p.category 
	FROM
		gold.fact_sales s
		LEFT JOIN gold.dim_products p on p.product_key = s.product_key
	WHERE
		order_date IS NOT NULL
	GROUP BY
		p.category
)
SELECT
	category,
	cat_sales,
	SUM(cat_sales) OVER () total_sales,
	CONCAT(CAST(ROUND((cat_sales *100.0 / SUM(cat_sales) OVER ()),2)AS DECIMAL(10,2)), '%') AS percentage_of_total
FROM
	tb_cat_sales
ORDER BY cat_sales DESC
-- Which categories contribute the most to ovrall sales by year?

WITH year_cat_sales AS(
	SELECT
		YEAR(s.order_date) AS year,
		s.sales_amount,
		p.category 
	FROM
		gold.fact_sales s
		LEFT JOIN gold.dim_products p on p.product_key = s.product_key
	WHERE
		order_date IS NOT NULL
), tb_yearly_sales AS(
	SELECT DISTINCT
		year, category,
		SUM(sales_amount) OVER (PARTITION BY year) as yearly_total_sales,
		SUM(sales_amount) over (PARTITION BY category, year) as yearly_cat_sales
	FROM year_cat_sales
)

SELECT 
	*,
	CONCAT(CAST(ROUND(yearly_cat_sales * 100.0 / yearly_total_sales, 2) AS DECIMAL(10,2)), '%') AS percentage_of_cat_sales
FROM tb_yearly_sales
ORDER BY year ASC, yearly_cat_sales DESC


-- 5. Data Segmentation
/* Segment products into cost reanges and
count how many products fall into each segment*/
WITH product_segments AS(
	SELECT 
		product_key,
		product_name,
		cost,
		CASE 
			WHEN cost < 100 THEN 'Below 100'
			WHEN cost BETWEEN 100 AND 500 THEN '100 - 500'
			WHEN cost BETWEEN 500 AND 1000 THEN '500 - 1000'
			ELSE 'Above 1000'
		END cost_range
	FROM
		gold.dim_products
)
SELECT
	cost_range,
	COUNT(product_key) AS total_products
FROM
	product_segments
GROUP BY cost_range
ORDER BY total_products DESC

/* Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than $5,000.
	- Regular: Customers with ar least 12 months of history but spending $5,000 or less.
	- New: Customers with a lifespan less than 12 months
And find the totl number of customers by each group.
*/

WITH cust_info AS(
	SELECT DISTINCT
		customer_key,
		SUM(sales_amount) OVER(PARTITION BY customer_key) AS spending,
		MIN(order_date) OVER (PARTITION BY customer_key) AS first_order,
		MAX(order_date) OVER (PARTITION BY customer_key) AS last_order,
		DATEDIFF(month, MIN(order_date) OVER (PARTITION BY customer_key),MAX(order_date) OVER (PARTITION BY customer_key)) AS months_diff
	FROM gold.fact_sales
), group_info AS(
	SELECT 
		customer_key,
		spending,
		months_diff,
		CASE
		WHEN spending > 5000 AND months_diff >= 12 THEN 'VIP'
		WHEN spending < 5000 AND months_diff >= 12 THEN 'Regular'
		ELSE 'New'
		END AS customers_segments
	FROM cust_info
)

SELECT DISTINCT
	customers_segments,
	count(*) OVER(PARTITION BY customers_segments) AS count_numbers_in_group
FROM
	group_info

