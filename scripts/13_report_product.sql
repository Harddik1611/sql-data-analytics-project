/*
===========================================================================================
Product Report
===========================================================================================
Purpose:
	- This reports consolidates key product metrics and behaviors

Highlights
	1. gathers essential fields such as product names,category,sucategory,and cost.
	2. Segments products by revenue to identify High-Performers,Mid-Range or Low-Performers.
	3. Aggregates prdouct-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customer(unique)
		- lifespan(in months)
	4. Calculates valuable KPIs:
		- recency (months since last order)
		- average order revenue (AOR)
		- average monthly revenue
	==========================================================================================
	*/

/* ---------------------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
------------------------------------------------------------------------------------------*/
Create VIEW gold.report_products as 
with base_query as(
select 
	f.order_number,
	f.order_date,
	f.sales_amount,
	f.customer_key,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
from gold.fact_sales f
left join gold.dim_products p
 on f.product_key=p.product_key
where order_date is not null -- only consider valid sales dates
)
/* ---------------------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the Product level.
------------------------------------------------------------------------------------------*/
,product_aggregation as (
select 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	datediff(month,min(order_date),max(order_date)) as lifespan,
	MAX(order_date) as last_sale_date,
	count(distinct order_number) as total_orders,
	count(distinct customer_key) as total_customers,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	Round(avg(cast(sales_amount as float) / nullif(quantity,0)),1) as avg_selling_price
from base_query
group by 
	product_key,
	product_name,
	category,
	subcategory,
	cost
)
/*------------------------------------------------------------------------------------------------
 3) Final Query: Combines all products results inot one output
-------------------------------------------------------------------------------------------------*/
select
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(month,last_sale_date,GETDATE()) as recency_in_months,
	Case
		when total_sales > 50000 then 'High-Performer'
		when total_sales >= 10000 then 'Mid-Range'
		else 'Low-Performer'
	end as product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average order Revenue (AOR)
	case
		when total_orders=0 then 0
		else total_sales /total_orders
	end as avg_order_revenue,

	-- Average Monthly Revenue
	Case 
		when lifespan = 0 then total_sales
		else total_sales/lifespan
	end as avg_monthly_revenue
from product_aggregation
	
