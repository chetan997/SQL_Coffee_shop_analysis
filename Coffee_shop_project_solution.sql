	-----Coffee_shop_alaysis------
	use coffee_shop
--1)Coffee Consumers Count
----How many people in each city are estimated to consume coffee, given that 25% of the population does?

	select
	city_name,
	concat(cast(round((population*.25/1000000),2) as float),' ','M') as coffee_cons_in_millions
	from city;

--2)Total Revenue from Coffee Sales
---What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

	select
	c.city_name,
	sum(s.total) as total_revenue
	from sales as s
	join customers as cs
	on s.customer_id=cs.customer_id
	join city as c
	on cs.city_id=c.city_id
	where sale_date between '2023-10-1' and '2023-12-31'
	group by c.city_name
	order by total_revenue desc;

--3)Sales Count for Each Product
---How many units of each coffee product have been sold?

	select
	p.product_name,
	count(s.sale_id) as total_units
	from sales as s
	left join products as p
	on s.product_id=p.product_id
	group by p.product_name
	order by total_units desc;

--4)Average Sales Amount per City
---What is the average sales amount per customer in each city?

	select
	c.city_name,
	sum(s.total) as total_revenue,
	count(distinct cs.customer_id) as total_customers,
	(sum(s.total)/count(distinct cs.customer_id)) as avg_sales_per_customer
	from sales as s
	join customers as cs
	on s.customer_id=cs.customer_id
	join city as c
	on cs.city_id=c.city_id
	group by c.city_name
	order by total_revenue desc;

--5)City Population and Coffee Consumers
---Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%).

	with city_table as
	(
	select
	city_name,
	population,
	cast((population*.25) as int) as coffee_consumers
	from city
	group by city_name , population
	), customers_table as
	(
	select
	c.city_name,
	count(distinct s.customer_id) as total_customers
	from sales as s
	join customers as cs
	on s.customer_id=cs.customer_id
	join city as c 
	on cs.city_id=c.city_id
	group by c.city_name
	)
	select
	ct.city_name,
	(ct.population/1000000) as population_in_millions,
	round(cast(ct.coffee_consumers as float)/1000000,2) as coffee_consumers_in_millions,
	cst.total_customers 
	from city_table as ct
	join customers_table as cst
	on ct.city_name=cst.city_name
	order by population_in_millions desc;

--6)Top Selling Products by City
---What are the top 3 selling products in each city based on sales volume?

	with top_selling_products as 
	(
	select
	c.city_name,
	p.product_name,
	count(s.sale_id) as total_volume,
	dense_rank() over(partition by c.city_name order by count(s.sale_id) desc ) as rank
	from sales as s
	join customers as cs
	on s.customer_id=cs.customer_id
	join city as c
	on cs.city_id=c.city_id
	join products as p
	on s.product_id=p.product_id
	group by c.city_name,p.product_name
	
	)
	select
	*
	from top_selling_products
	where rank<=3
	order by city_name,  total_volume desc;

--7)Customer Segmentation by City
---How many unique customers are there in each city who have purchased coffee products?

	select
	city_name,
	count(distinct s.customer_id) as total_customers
	from sales as s
	left join customers as cs
	on s.customer_id=cs.customer_id
	left join city as c
	on cs.city_id=c.city_id
	left join products as p
	on s.product_id=p.product_id
	where s.product_id in ('1','2','3','4','5','6','7','8','9','10','11','12','13','14')
	group by c.city_name
	order by total_customers desc;

--8)Average Sale vs Rent
---Find each city and their average sale per customer and avg rent per customer

	with sale_per_customer as
	(
	select
	city_name,
	sum(s.total) as total_sales,
	count(distinct s.customer_id) as total_customers,
	round((cast(sum(s.total) as float)/count(distinct s.customer_id)),2) as avg_sale_per_customer
	from sales as s
	join customers as cs
	on s.customer_id=cs.customer_id
	join city as c
	on cs.city_id=c.city_id
	group by city_name
	), rent_per_customer as
	(
	select
	city_name,
	estimated_rent
	from city
	)
	select
	spc.city_name,
	spc.total_customers,
	avg_sale_per_customer,
	round((cast(rpc.estimated_rent as float)/spc.total_customers),2) as avg_rent_per_customer
	from sale_per_customer as spc
	join rent_per_customer as rpc
	on spc.city_name=rpc.city_name
	group by spc.city_name,spc.total_customers,avg_sale_per_customer,estimated_rent
	order by avg_rent_per_customer desc;

--9)Monthly Sales Growth
---Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
--by each city
	
	with monthly_sales as
	(
	select
	c.city_name,
	DATEPART(month,sale_date) as month,
	DATEPART(year,sale_date) as year,
	sum(total) as total_revenue
	from sales as s
	left join customers as cs
	on s.customer_id=cs.customer_id
	left join city as c
	on cs.city_id=c.city_id
	group by c.city_name,DATEPART(month,sale_date),DATEPART(year,sale_date)
	), month_by_month as
	(
	select
	city_name,
	month,
	year,
	total_revenue as current_month_sales,
	lag(total_revenue,1) over(partition by city_name order by year,month) as previous_month_sales
	from monthly_sales
	)
	select
	*,
	round(((cast(current_month_sales-previous_month_sales as float))/cast(previous_month_sales as float))*100,2) as percent_change
	from month_by_month
	where previous_month_sales is not null;
	

--10)Market Potential Analysis
---Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

	with city_customers as
	(
	select 
	c.city_name,
	sum(s.total) as total_sales,
	count(distinct s.customer_id) as total_customers,
	round(cast(sum(s.total) as float)/count(distinct s.customer_id),2) as avg_sale_per_cust,
	cast((c.population*.25) as float)/1000000 as estimated_consumers_in_millions
	from sales as s
	left join customers as cs
	on s.customer_id=cs.customer_id
	left join city as c
	on cs.city_id=c.city_id
	group by c.city_name,c.population
	), city_rent as
	(select 
	c.city_name,
	cast(c.estimated_rent as float) as total_rent,
	round((cast(c.estimated_rent as float)/count(distinct s.customer_id)),2) as avg_rent_per_cust
	from sales as s
	left join customers as cs
	on s.customer_id=cs.customer_id
	left join city as c
	on cs.city_id=c.city_id
	group by c.city_name,c.estimated_rent
	)
	select
	cc.city_name,
	cc.total_sales,
	cc.total_customers,
	cc.avg_sale_per_cust,
	cc.estimated_consumers_in_millions,
	cr.total_rent,
	cr.avg_rent_per_cust 
	from city_customers as cc
	join city_rent as cr
	on cc.city_name=cr.city_name
	order by total_sales desc;