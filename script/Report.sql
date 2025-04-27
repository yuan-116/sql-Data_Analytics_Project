/*
==================================================
Customer and Product Reporting Script
==================================================

==================================================
Customer Report
==================================================
Purpose:
	- This report consolidates key customer metrics and behaviors

Hihglights:
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- lifespan (in months)
	4. Calculates valuable KPIS:
		- recency (months since last order)
		- average order value
		- average monthly spend
==================================================
*/
CREATE VIEW gold.report_customers AS 
-- 1) Base Query: Retrieves core columns from tables
WITH base_query AS(
	SELECT
		s.order_number,
		s.product_key,
		s.order_date,
		s.sales_amount,
		s.quantity,
		c.customer_key,
		c.customer_number,
		CONCAT(c.first_name,' ', c.last_name) AS customer_name,
		DATEDIFF(year, c.birthdate, GETDATE()) AS age
	FROM
		gold.fact_sales s
	LEFT JOIN gold.dim_customers c on c.customer_key = s.customer_key
	WHERE
		order_date IS NOT NULL
), customer_aggregation AS(
-- 2) Customer Aggregation: Summrizes key metrics at the customer level
	SELECT
		customer_key,
		customer_number,
		customer_name,
		age,
		count(DISTINCT order_number) AS total_orders,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT product_key) AS total_products,
		MAX(order_date) AS last_order_date,
		DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
	FROM base_query
	GROUP BY 
		customer_key,
		customer_number,
		customer_name,
		age
)


SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE
		WHEN age < 20 THEN 'Under 20'
		WHEN age between 20 and 29 THEN '20 - 29'
		WHEN age between 30 and 39 THEN '30 - 39'
		WHEN age between 40 and 49 THEN '40 - 49'
		ELSE '50 and above'
	END AS age_segment,
	CASE
		WHEN total_sales > 5000 AND lifespan >= 12 THEN 'VIP'
		WHEN total_sales < 5000 AND lifespan >= 12 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,
	last_order_date,
	DATEDIFF (month, last_order_date, GETDATE()) AS recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
	-- Compute average order value (AVO)
	CASE 
	WHEN total_sales = 0 THEN 0
	ELSE (total_sales / total_quantity)
	END AS avg_order_value,

	-- Compute average monthly spend 
	CASE WHEN lifespan = 0 THEN total_sales
		ELSE (total_sales / lifespan) 
	END AS avg_monthly_spend
FROM customer_aggregation


/*
================================================
Product Report
================================================
Purpose:
	- This report consolidates key product metrics and behaviors.

Highlights:
	1. Gather essential fields such as product name, category, subcategory, and cost.
	2. Segments products by revenue, to identify High-Performers, Mid-Range, or Low-Performers
	3. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
================================================
*/
CREATE VIEW gold.report_product AS 
-- 1) Base query: Retrieves core columns from fact_sales and dim_products
WITH base_query AS(
	SELECT
		s.order_number,
		s.order_date,
		s.customer_key,
		s.sales_amount,
		s.quantity,
		p.product_key,
		p.product_name,
		p.category,
		p.subcategory,
		p.cost
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p on s.product_key = p.product_key
	WHERE order_date IS NOT NULL
), product_aggregation AS(
-- 2) Product Aggregations: Summarizes keys metrics at the product level
	SELECT 
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		MAX(order_date) AS last_sale_date,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT order_number) AS total_orders,
		COUNT(DISTINCT customer_key) AS total_customers,
		DATEDIFF(month, MIN(order_date),MAX(order_date)) AS lifespan,
		ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_unit_price
	FROM
		base_query
	GROUP BY
		product_key,
		product_name,
		category,
		subcategory,
		cost
)
-- 3) Final Query: Combines all product results into one output
SELECT
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		last_sale_date,
		DATEDIFF(month, last_sale_date, GETDATE()) AS recency_in_months,
		CASE
			WHEN total_sales > 50000 THEN 'High-Performer'
			WHEN total_sales >= 10000 THEN 'Mid-Performer'
			ELSE 'Low-Performer'
		END AS product_segment,
		lifespan,
		total_orders,
		total_sales,
		total_quantity,
		total_customers,
		avg_unit_price,
		-- (AOR)
		CASE
			WHEN total_orders = 0 THEN 0
			ELSE total_sales / total_orders
		END AS avg_order_revenue,
		-- (average monthly revenue)
		CASE 
			WHEN lifespan = 0 THEN 0
			ELSE total_sales/lifespan
		END AS avg_monthly_revenue
FROM
product_aggregation
