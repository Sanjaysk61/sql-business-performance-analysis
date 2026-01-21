/*
==============================================================================
Cutomer Report
==============================================================================
Purpose:
	- This report consolidates key customer metric and behaviors

Highlight :
	1. Gather essential fields such as names, ages , and transaction detials.
	2. segment customers into categories (VIP , Regular , New) and age group.
	3. Aggregates customer - level metrics :
			- total orders 
			- total sales 
			- total quantity purchased 
			- total products 
			- life span (in months)
	4. Calculates valuable KPIs:
			- recency (months since last order)
			- average order value
			- average monthly spend
	==========================================================================
	*/
CREATE VIEW gold.report_customers AS 
WITH base_query AS(
/*----------------------------------------------------------------------------
	1) Base query : Retrives core columns from tables
------------------------------------------------------------------------------*/
SELECT 
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	c.gender,
	DATEDIFF(year,c.birthdate, GETDATE()) AS age,
	s.order_date,
	s.order_number,
	s.product_key,
	s.sales_amount,
	s.price,
	s.quantity,
	c.country
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON s.customer_key = c.customer_key
WHERE order_date IS NOT NULL
),
 customer_aggregation AS (
/*----------------------------------------------------------------------------
	2) Customer aggregations: Summarizes key metrics at the customer level
------------------------------------------------------------------------------*/
SELECT 
	customer_key,
	customer_number,
    customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(sales_amount) AS total_sales_amount,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order,
	DATEDIFF(month,MIN(order_date) , MAX(order_date)) AS life_span
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
		 WHEN age < 18 THEN ' Under 18'
		 WHEN age BETWEEN 18 AND 29 THEN ' 20 - 29'
		 WHEN age BETWEEN 30 AND 39 THEN ' 30 - 39'
		 WHEN age BETWEEN 40 AND 49 THEN ' 40 - 49'
		 ELSE '50 and Above'
	END AS age_group,	 
    CASE 
		 WHEN life_span >= 12 AND total_sales_amount > 5000 THEN 'VIP'
		 WHEN life_span >= 12 AND total_sales_amount <= 5000 THEN 'Regular'
		 WHEN life_span < 12 AND total_sales_amount < 5000 THEN 'Normal'
		 ELSE 'New'
	END AS customer_segment,
	last_order,
	DATEDIFF(month,last_order,GETDATE()) AS recency,
    total_orders,
	total_quantity,
	total_sales_amount,
	total_products,
	life_span,
	-- Compuate average order value
	total_sales_amount/NULLIF(total_orders,0) AS avg_order_value,
	--compuate average monthly spend 
	total_sales_amount/NULLIF(life_span,0) AS avg_monthly_spend
FROM customer_aggregation
