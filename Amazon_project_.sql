
/*
1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.
*/


	
-- Creating new column
ALTER TABLE order_items
ADD COLUMN total_sale FLOAT;


SELECT * FROM order_items;

UPDATE order_items
SET total_sale = quantity * price_per_unit;
SELECT * FROM order_items;


SELECT * FROM order_items
ORDER BY quantity DESC;

SELECT 
	oi.product_id,
	p.product_name,
	SUM(oi.total_sale) as total_sale,
	COUNT(o.order_id)  as total_orders
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON p.product_id = oi.product_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10




/*
2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.
*/


SELECT 
	p.category_id,
	c.category_name,
	SUM(oi.total_sale) as total_sale,
	SUM(oi.total_sale)/
					(SELECT SUM(total_sale) FROM order_items) 
					* 100
	as contribution
FROM order_items as oi
JOIN
products as p
ON p.product_id = oi.product_id
LEFT JOIN category as c
ON c.category_id = p.category_id
GROUP BY 1, 2
ORDER BY 3 DESC


-- 


/*
3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.
*/



SELECT 
	c.customer_id,
	CONCAT(c.first_name, ' ',  c.last_name) as full_name,
	SUM(total_sale)/COUNT(o.order_id) as AOV,
	COUNT(o.order_id) as total_orders --- filter
FROM orders as o
JOIN 
customers as c
ON c.customer_id = o.customer_id
JOIN 
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1, 2
HAVING  COUNT(o.order_id) > 5



/*
4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!
*/


SELECT 
	year,
	month,
	total_sale as current_month_sale,
	LAG(total_sale, 1) OVER(ORDER BY year, month) as last_month_sale
FROM ---
(
SELECT 
	EXTRACT(MONTH FROM o.order_date) as month,
	EXTRACT(YEAR FROM o.order_date) as year,
	ROUND(
			SUM(oi.total_sale::numeric)
			,2) as total_sale
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 1, 2
ORDER BY year, month
) as t1



/*
5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.
*/

-- Approach 1
SELECT *
	-- reg_date - CURRENT_DATE
FROM customers
WHERE customer_id NOT IN (SELECT 
					DISTINCT customer_id
				FROM orders
				);


-- Approach 2
SELECT *
FROM customers as c
LEFT JOIN
orders as o
ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL

-- 

/*
6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.
*/

WITH ranking_table
AS

(
SELECT 
	c.state,
	cat.category_name,
	SUM(oi.total_sale) as total_sale,
	RANK() OVER(PARTITION BY c.state ORDER BY SUM(oi.total_sale) ASC) as rank
FROM orders as o
JOIN 
customers as c
ON o.customer_id = c.customer_id
JOIN
order_items as oi
ON o.order_id = oi. order_id
JOIN 
products as p
ON oi.product_id = p.product_id
JOIN
category as cat
ON cat.category_id = p.category_id
GROUP BY 1, 2
)
SELECT 
*
FROM ranking_table
WHERE rank = 1


/*
7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.
*/




SELECT 
	c.customer_id,
	CONCAT(c.first_name, ' ',  c.last_name) as full_name,
	SUM(total_sale) as CLTV,
	DENSE_RANK() OVER( ORDER BY SUM(total_sale) DESC) as cx_ranking
FROM orders as o
JOIN 
customers as c
ON c.customer_id = o.customer_id
JOIN 
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1, 2




/*
8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.
*/

SELECT 
	i.inventory_id,
	p.product_name,
	i.stock as current_stock_left,
	i.last_stock_date,
	i.warehouse_id
FROM inventory as i
join 
products as p
ON p.product_id = i.product_id
WHERE stock < 10



/*
9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.
*/



SELECT 
	c.*,
	o.*,
	s.shipping_providers,
s.shipping_date - o.order_date as days_took_to_ship
FROM orders as o
JOIN
customers as c
ON c.customer_id = o.customer_id
JOIN 
shippings as s
ON o.order_id = s.order_id
WHERE s.shipping_date - o.order_date > 3





/*
10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).
*/

SELECT 
	p.payment_status,
	COUNT(*) as total_cnt,
	COUNT(*)::numeric/(SELECT COUNT(*) FROM payments)::numeric * 100
FROM orders as o
JOIN
payments as p
ON o.order_id = p.order_id
GROUP BY 1


-- 



/*
11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.
*/


WITH top_sellers
AS
(SELECT 
	s.seller_id,
	s.seller_name,
	SUM(oi.total_sale) as total_sale
FROM orders as o
JOIN
sellers as s
ON o.seller_id = s.seller_id
JOIN 
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 5
),

sellers_reports
AS
(SELECT 
	o.seller_id,
	ts.seller_name,
	o.order_status,
	COUNT(*) as total_orders
FROM orders as o
JOIN 
top_sellers as ts
ON ts.seller_id = o.seller_id
WHERE 
	o.order_status NOT IN ('Inprogress', 'Returned')
	
GROUP BY 1, 2, 3
)
SELECT 
	seller_id,
	seller_name,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END) as Completed_orders,
	SUM(CASE WHEN order_status = 'Cancelled' THEN total_orders ELSE 0 END) as Cancelled_orders,
	SUM(total_orders) as total_orders,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END)::numeric/
	SUM(total_orders)::numeric * 100 as successful_orders_percentage
	
FROM sellers_reports
GROUP BY 1, 2

-- 




/*
12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.
*/



SELECT 
	product_id,
	product_name,
	profit_margin,
	DENSE_RANK() OVER( ORDER BY profit_margin DESC) as product_ranking
FROM
(SELECT 
	p.product_id,
	p.product_name,
	-- SUM(total_sale - (p.cogs * oi.quantity)) as profit,
	SUM(total_sale - (p.cogs * oi.quantity))/sum(total_sale) * 100 as profit_margin
FROM order_items as oi
JOIN 
products as p
ON oi.product_id = p.product_id
GROUP BY 1, 2
) as t1




/*
13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.
*/



SELECT 
	p.product_id,
	p.product_name,
	COUNT(*) as total_unit_sold,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) as total_returned,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::numeric/COUNT(*)::numeric * 100 as return_percentage
FROM order_items as oi
JOIN 
products as p
ON oi.product_id = p.product_id
JOIN orders as o
ON o.order_id = oi.order_id
GROUP BY 1, 2
ORDER BY 5 DESC


/*
14. Orders Pending Shipment
Find orders that have been paid but are still pending shipment.
Challenge: Include order details, payment date, and customer information.
*/



select c.customer_id, concat(c.first_name, ' ', c.last_name) as customer_name, o.order_id, o.order_date, 
	p.payment_date
from customers as c
join orders as o on o.customer_id = c.customer_id
join payments as p on o.order_id = p.order_id
join products as pd on pd.product_id = o.order_id
where p.payment_status = 'Payment Successed' and o.order_status = 'Inprogress'



/*
15. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months.
Challenge: Show the last sale date and total sales from those sellers.
*/


with cte as 
(select * from sellers
where seller_id not in (select seller_id from orders where order_date >= current_date - interval '6 Month') )

select o.seller_id, max(o.order_date), sum(oi.total_sale)
from orders as o
join order_items as oi on o.order_id = oi.order_id
join cte on cte.seller_id = o.seller_id
group by 1


------ both the sellers have not done any sale


/*
16. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
Challenge: List customers id, name, total orders, total returns
*/

	
select 
	c.customer_id, concat(c.first_name, ' ' , c.last_name) as customer_name,
	count(o.order_id) as total_orders ,
	sum(case when o.order_status = 'Returned' then 1 else 0 end) as return_count,
	case when sum(case when o.order_status = 'Returned' then 1 else 0 end) >5 then 'Returning' else 'New' end as Status
from customers as c
join orders as o on c.customer_id = o.customer_id
join shippings as s on s.order_id = o.order_id
group by 1,2
order by return_count;








/*
18. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
*/

with cte as(
select 
	c.customer_id, concat(c.first_name, ' ' , c.last_name) as customer_name,
	c.state,
	count(o.order_id) as total_orders,
	sum(oi.total_sale) as total_sales
from orders as o
join customers as c on c.customer_id = o.customer_id
join order_items as oi on o.order_id = oi.order_id
group by 1,2,3),
	cte2 as(
select *, row_number() over(partition by state order by total_sales desc)
from cte)

select *
from cte2
where row_number <=5;



/*
19. Revenue by sellers
Calculate the total revenue handled by each seller.
Challenge: Include the total number of orders handled and the average delivery time for each provider.
*/


select * from shippings;
select 
	sp.shipping_providers , count(o.order_id) as total_orders , sum(oi.total_sale) as total_sales, 
	abs(round(avg(o.order_date - sp.shipping_date))) as avg_delivery_time
from sellers as s
join orders as o on s.seller_id = o.seller_id
join order_items as oi on o.order_id = oi.order_id
join shippings as sp on o.order_id = sp.order_id
group by 1
order by total_sales DESC;


/*
20. Top 10 product with highest decreasing revenue ratio compare to last year(2022) and current_year(2023)
Challenge: Return product_id, product_name, category_name, 2022 revenue and 2023 revenue decrease ratio at end Round the result

Note: Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)
*/

with year_2022 as 
	(select 
    p.product_id, 
    p.product_name, 
    sum(oi.total_sale)
from products as p 
join category as c on p.category_id = c.category_id
join order_items as oi on oi.product_id = p.product_id
join orders as o on o.order_id = oi.order_id
where extract(year from o.order_date) in (2022)
group by 1,2 ),
year_2023 as
	(select 
    p.product_id, 
    p.product_name, 
    sum(oi.total_sale)
from products as p 
join category as c on p.category_id = c.category_id
join order_items as oi on oi.product_id = p.product_id
join orders as o on o.order_id = oi.order_id
where extract(year from o.order_date) in (2023)
group by 1,2 )
	


select ly.product_id, ly.product_name, ly.sum as revenue_2022,
	cy.sum as revenue_2023, ly.sum- cy.sum as reveneue_difference,  
	round(((cy.sum - ly.sum)/cy.sum) * 100 , 2) as Decrease_ratio
from year_2022 as ly
join year_2023 as cy on ly.product_id = cy.product_id
where ly.sum > cy.sum
order by decrease_ratio
limit 10;




/*
Final Task
-- Store Procedure
create a function as soon as the product is sold the the same quantity should reduced from inventory table
after adding any sales records it should update the stock in the inventory table based on the product and qty purchased
-- 
*/


create or replace procedure add_sales(
	p_order_id int,
	p_customer_id int,
	p_seller_id int,
	p_order_item_id int,
	p_product_id int, 
	p_quantity int
	)

language plpgsql
as $$

declare
	
	v_stock int;
	v_price float;
	v_product_name varchar(100);
	
begin

	select price, product_name
	into v_price, v_product_name
	from products
	where product_id = p_product_id;
	
	select 
		count(*)
		into 
		v_stock
	from inventory
	where product_id = p_product_id and stock>= p_quantity;

	if v_stock>0 then 
	
		--inserting values
		insert into orders(order_id, order_date, customer_id, seller_id) 
		values(p_order_id, current_date, p_customer_id, p_seller_id);

		insert into order_items(order_item_id, order_id, product_id, quantity, price_per_unit, total_sale)
			values(p_order_item_id, p_order_id, p_product_id,p_quantity, v_price, v_price* p_quantity);

			
		--inserting values

		update inventory
		set stock = stock - p_quantity
		where product_id = p_product_id;

		raise notice 'Thankyou Product: % sale has been added into the orders and order_items table. 
					   Also inventory table is also updated ', v_product_name;

	else
		raise notice 'Thankyou for your info. Your product is not available. ';

	end if;
	
end;

$$

call add_sales(25000,20,5,250001,1,30);


