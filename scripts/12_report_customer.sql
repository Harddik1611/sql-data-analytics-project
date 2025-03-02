
/*
===========================================================================================
Customer Report
===========================================================================================
Purpose:
	- This reports consolidates key customer metris and behaviours

Highlights:
	1. gathers essential fields such as names,ages,and transaction details.
	2. Segments customers into categories (VIP,Regular,New) and age groups.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- lifespan(in months)
	4. Calculates valuable KPIs:
		- recency (months since last order)
		- average order value
		- average monthly spend
	==========================================================================================
	*/

/* ---------------------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
------------------------------------------------------------------------------------------*/
Create VIEW gold.report_customers as 
with base_query as(
select 
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	c.first_name,
	c.last_name,
	concat(c.first_name,' ',c.last_name) as customer_name,
	DATEDIFF(year,c.birthdate,GETDATE()) age
	from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key=f.customer_key
where order_date is not null
)
/* ---------------------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level.
------------------------------------------------------------------------------------------*/
,customer_aggregation as (
select 
customer_key,
customer_number,
customer_name,
age,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
count(distinct product_key) as total_products,
Max(order_date) as last_order_date,
datediff(month,min(order_date),max(order_date)) as lifespan
from base_query
group by 
	customer_key,
	customer_number,
	customer_name,
	age
)
select
	customer_key,
	customer_number,
	customer_name,
	age,
	case 
		 when age < 20 then 'Under 20'
		 when age between 20 and 29 then '20-29'
		 when age between 30 and 39 then '30-39'
		 when age between 40 and 49 then '40-49'
	else '50 and above'
	end as age_group,
	case
		when lifespan >= 12 and total_sales > 5000 then 'VIP'
	    when lifespan >= 12 and total_sales <= 5000 then 'Regular'
		else 'New'
	end as customer_segment,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	last_order_date,
	DATEDIFF(month,last_order_date,GETDATE()) as recency,
	lifespan,
-- Compute Average Order Value (AVO)
	case when total_orders = 0 then 0
		 else total_sales/total_orders
	end as avg_order_value,
-- compute Average Monthly Spend
Case when lifespan=0 then total_sales
	 else total_sales/lifespan
end as avg_monthly_spend
from customer_aggregation
