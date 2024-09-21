-- Amazon Project

-- Category Table

create table category(
	category_id	int primary key,
	category_name varchar(20)
);


create table customers(
	customer_id int primary key,
	first_name varchar(20),
	last_name varchar(20),
	state varchar(20),
	address varchar(5) default ('xxxx')
);

create table sellers(
	seller_id int primary key,
	seller_name varchar(25),
	origin varchar(10)
	);

create table products(
	product_id int primary key,
	product_name varchar(50),
	price float ,
	cogs float,
	category_id int,
	constraint product_fk_category foreign key(category_id) references category(category_id) 
);

create table orders(
	order_id int primary key,
	order_date date,
	customer_id int,
	seller_id int,
	order_status varchar(20),
	constraint orders_fk_customers foreign key(customer_id) references customers(customer_id),
	constraint orders_fk_sellers foreign key(seller_id) references sellers(seller_id)
); 

create table orders_item(
	order_item_id int primary key,
	order_id int,
	product_id int, 
	quantity int,
	price_per_unit int,
	constraint orders_item_fk_products foreign key(product_id) references products(product_id),
	constraint orders_item_fk_orders foreign key(order_id) references orders(order_id)
);

create table payments(
	payment_id int primary key,
	order_id int,
	payment_date date,
	payment_status varchar(30),
	constraint payments_fk_orders foreign key(order_id) references orders(order_id)
);

create table shippings(
	shipping_id int primary key,
	order_id int,
	shipping_date date,
	return_date date,
	shipping_providers varchar(20),
	delivery_status varchar(15),
	constraint shippings_fk_orders foreign key(order_id) references orders(order_id)
);

create table inventory(
	inventory_id int primary key,
	product_id int,
	stock int,
	warehouse_id int,
	last_stock_date date,
	constraint inventory_fk_products foreign key(product_id) references products(product_id)

);
