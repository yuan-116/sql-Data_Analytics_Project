/* 
=============================================
EDA (Exploratory Data Analysis) for Sales Database
=============================================

This SQL script conducts an exploratory data analysis (EDA) on a sales database I developed in a previous project.
It is organized into several sections to explore the database structure, key dimensions, time coverage, business metrics, and customer/product performance.

1. Database Structure Exploration
- List all tables and columns to understand the available data.

2. Dimensions Exploration
- Explore customer countries and product categories to profile the data.

3. Date Exploration
- Identify the range of available order dates and customer age distribution.

4. Measures Exploration
- Summarize core metrics including total sales, quantity sold, average selling price, number of products, and customer counts.

5. Magnitude Analysis
- Compare key measures across countries, genders, categories, and customers.

6. Ranking Analysis
- Rank top and bottom products and customers based on revenue and order counts.

This EDA provides a comprehensive overview of the database to support further business analysis, reporting, and modeling efforts.

*/


-- 1) Database Exploration

--Explore All objects in the Database

SELECT * FROM INFORMATION_SCHEMA.TABLES

-- Explore All Columns in the Database

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_products'


-- 2) Dimensions Exploration
 
-- Explore All Countries our customers come from
SELECT DISTINCT
	country
FROM gold.dim_customers

-- Explore All Categories "The major Divisions"

SELECT DISTINCT
	category, subcategory, product_name
FROM gold.dim_products
ORDER BY 1,2,3

-- 3) Date Exploration
-- Find the date of the first and the last order
-- How many years of sales are avaiable
SELECT
	MIN(order_date) AS first_order_date,
	MAX(order_date) AS last_order_date,
	DATEDIFF(year, Min(order_date), MAX(order_date)) AS order_range_years,
	DATEDIFF(month, Min(order_date), MAX(order_date)) AS order_range_months
FROM
	gold.fact_sales 

-- Find the youngest and oldest customer

SELECT
	MIN(birthdate) AS oldest_customer_birthdate,
	DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
	MAX(birthdate) AS youngest_customer_birthdate,
	DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
FROM
	gold.dim_customers

-- 4) Measures Exploration

-- Find the Total Sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales;
-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity FROM gold.fact_sales;
-- Find the average selling price
SELECT AVG(price) AS avg_price FROM gold.fact_sales;
-- Find the total number of orders
SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales;
SELECT COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales;

-- Find the total number of products
SELECT COUNT(product_key) AS total_product FROM gold.dim_products;
SELECT COUNT(DISTINCT product_key) AS total_product FROM gold.dim_products;
-- Find the total number of customers

SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers;
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.dim_customers;
-- Find the total number of customers that has places an order

SELECT COUNT(DISTINCT customer_key)
FROM 
	gold.fact_sales ;


-- Generate a Report that shows all key metrics of the business


SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Price' AS measure_name, AVG(price) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Products' AS measure_name, COUNT(DISTINCT product_key) AS measure_value FROM gold.dim_products
UNION ALL
SELECT 'Total Customers' AS measure_name,  COUNT(DISTINCT customer_key) AS measure_value FROM gold.dim_customers
UNION ALL
SELECT 'Total Customers did place an order' AS measure_name,   COUNT(DISTINCT customer_key) AS measure_value FROM gold.fact_sales;


-- 5) Magnitude 
-- Compare the Measure values by categories

-- Find total customers by conutries
SELECT DISTINCT
	country,
	COUNT(customer_key) OVER(PARTITION BY country) AS total_customers
FROM
	gold.dim_customers
ORDER BY
	total_customers DESC
-- Find total customers by gender
SELECT DISTINCT
	gender,
	COUNT(customer_key) OVER(PARTITION BY gender) AS total_customers
FROM
	gold.dim_customers
ORDER BY
	total_customers DESC
-- Find total products by category
SELECT DISTINCT
	category,
	count(product_number) OVER (PARTITION BY category) AS total_products
FROM gold.dim_products
ORDER BY
	total_products DESC
-- What is the average costs in each category?
SELECT DISTINCT
	category,
	AVG(cost) OVER (PARTITION BY category) AS avg_cost
FROM gold.dim_products
ORDER BY
	avg_cost DESC
-- What is the total revenue generated for each category?
SELECT DISTINCT
	p.category,
	SUM(sales_amount) OVER (PARTITION BY category) AS total_revenue
FROM
	gold.fact_sales s
	LEFT JOIN gold.dim_products p on p.product_key = s.product_key
ORDER BY
	total_revenue DESC
-- Find total revenue is generated by each customer
SELECT DISTINCT
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(s.sales_amount) OVER (PARTITION BY c.customer_key, c.first_name, c.last_name) AS total_revenue
FROM
	gold.fact_sales s
	LEFT JOIN gold.dim_customers c on s.customer_key = c.customer_key
ORDER BY
	c.customer_key
-- What is the distribution of sold items across countries?
SELECT DISTINCT
	c.country,
	SUM(quantity) OVER (PARTITION BY c.country) AS total_sold_items
FROM
	gold.fact_sales s
	LEFT JOIN gold.dim_customers c on c.customer_key = s.customer_key
ORDER BY
	total_sold_items DESC



-- 6) Ranking
 
 --Which 5 products generate the highest revenue?
 SELECT DISTINCT TOP 5
	p.product_name,
	SUM(s.sales_amount) OVER (PARTITION BY p.product_name) AS total_revenue
FROM
	gold.fact_sales s
	LEFT JOIN gold.dim_products p on s.product_key = p.product_key
ORDER BY
	total_revenue DESC

SELECT * FROM(
	 SELECT 
		p.product_name,
		SUM(s.sales_amount) AS total_revenue,
		ROW_NUMBER() OVER (ORDER BY SUM(s.sales_amount) desc) as rank_products
	FROM
		gold.fact_sales s
		LEFT JOIN gold.dim_products p on s.product_key = p.product_key
	GROUP BY
		product_name
)t
WHERE rank_products <= 5

 -- What are the 5 worst-performing products in terms of sales?

  SELECT DISTINCT TOP 5
	p.product_name,
	SUM(s.sales_amount) OVER (PARTITION BY p.product_name) AS total_revenue
FROM
	gold.fact_sales s
	LEFT JOIN gold.dim_products p on s.product_key = p.product_key
ORDER BY
	total_revenue

-- Find the top 10 customers who have generated the highest revenue

SELECT TOP 10
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(s.sales_amount) AS total_revenue
FROM
	gold.fact_sales s
	LEFT JOIN gold.dim_customers c on s.customer_key = s.customer_key
GROUP BY
	c.customer_key,
	c.first_name,
	c.last_name
ORDER BY
	total_revenue DESC

-- The 3 customers with the fewest orders placed

SELECT TOP 3
	c.customer_key,
	c.first_name,
	c.last_name,
	COUNT(DISTINCT order_number) AS total_order
FROM
	gold.fact_sales s
	LEFT JOIN gold.dim_customers c on s.customer_key = s.customer_key
GROUP BY
	c.customer_key,
	c.first_name,
	c.last_name
ORDER BY
	total_order