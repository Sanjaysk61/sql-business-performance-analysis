/*
==============================================================================
Product Report
==============================================================================
Purpose:
	- This report consolidates key product metric and behaviors

Highlight :
	1. Gather essential fields such as prdocut names, category, subcategory, and cost.
	2. segment products by revenue to identify High performers, Mid-range, or Low-Performers.
	3. Aggregates Product - level metrics :
			- total orders 
			- total sales 
			- total quantity purchased 
			- total products 
			- total customers(unique)
			- lifespan (in months)
	4. Calculates valuable KPIs:
			- recency (months since last order)
			- average order revenue (AOR)
			- average monthly revenue
	==========================================================================
	*/ 
CREATE VIEW gold.product_report AS

	WITH base_query AS(
/*----------------------------------------------------------------------------
	1) Base query : Retrives core columns from tables
------------------------------------------------------------------------------*/
SELECT 
	p.product_name,
	p.category,
	p.subcategory,
	p.cost,
	p.product_line,
	s.customer_key,
	s.order_date,
	s.order_number,
	s.product_key,
	s.sales_amount,
	s.price,
	s.quantity
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
WHERE order_date IS NOT NULL
) ,

	product_aggregation AS (
/*----------------------------------------------------------------------------
	2) Customer aggregations: Summarizes key metrics at the customer level
------------------------------------------------------------------------------*/
SELECT 
	category,
	subcategory,
	product_name,
	DATEDIFF(month,MIN(order_date),MAX(order_date)) AS life_span,
	DATEDIFF(month,MAX(order_date),GETDATE()) AS recency,
	COUNT(DISTINCT customer_key) AS total_customers,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(sales_amount) AS total_sales_amount,
	ROUND(AVG(CAST(sales_amount AS FLOAT)/NULLIF(quantity,0)),1) AS avg_selling_price
FROM base_query
GROUP BY 	
	category,
	subcategory,
	product_name
)
SELECT 
	category,
	subcategory,
	product_name,
	life_span,
	recency,
	total_customers,
	total_orders,
	total_quantity,
	total_sales_amount,
	CASE
		WHEN total_sales_amount > 50000 THEN 'High performance'
		WHEN total_sales_amount >= 10000 THEN 'Mid range'
		ELSE 'Low performer'
	END AS product_segment,
	total_sales_amount/NULLIF(total_orders,0) AS avg_order_revenue,
	total_sales_amount/NULLIF(life_span,0) AS avg_monthly_revenue
FROM product_aggregation
