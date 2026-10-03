-- ==================================================
-- power bi dataset 1
-- monthly orders / sales / aov
-- grain: 1 row = 1 month
-- ==================================================

create view pbi_orders_monthly as

	with order_sales as
		(
			select
				order_id, sum(price) as order_price
			from order_items
			group by order_id
		)

	select
		str_to_date(concat(year(ord.order_purchase_timestamp),'-',month(ord.order_purchase_timestamp),'-01'),'%Y-%m-%d') as month_start,
		count(ord.order_id) as order_count, round(sum(coalesce(os.order_price,0)),2) as product_sales, round(avg(os.order_price),2) as avg_order_value
	from orders as ord
		left join order_sales as os
			on ord.order_id = os.order_id
group by 
	year(ord.order_purchase_timestamp), month(ord.order_purchase_timestamp), month_start
order by month_start;

select*from pbi_orders_monthly;

-- ==================================================
-- power bi dataset 2
-- customer state performance
-- grain: 1 row = 1 customer_state
-- ==================================================

create view pbi_state_performance as

	with order_sales as
		(
			select
				order_id, sum(price) as order_price
			from order_items
			group by order_id
		)

	select
		cm.customer_state, count(ord.order_id) as order_count, round(sum(coalesce(os.order_price,0)),2) as product_sales
	from orders as ord
		left join customers as cm
			on ord.customer_id = cm.customer_id
		left join order_sales as os
			on ord.order_id = os.order_id
            
group by cm.customer_state
order by product_sales desc;

select*from pbi_state_performance;

-- ==================================================
-- power bi dataset 3
-- payment method performance
-- grain: 1 row = 1 payment_type
-- ==================================================

create view pbi_payment_methods as

	with payment_by_order as
		(
			select
				order_id, payment_type, sum(payment_value) as payment_value
			from order_payments
			group by order_id, payment_type
		)

		select
			payment_type, count(order_id) as order_count, round(avg(payment_value),2) as avg_payment_value
		from payment_by_order
    
	group by payment_type
	order by order_count desc;

select*from pbi_payment_methods;

-- ==================================================
-- power bi dataset 4
-- product category sales
-- grain: 1 row = 1 product category
-- ==================================================

create view pbi_category_sales as

	select
		case when prd.product_category_name = '' or prd.product_category_name is null
				then 'Unknown'
					else prd.product_category_name
			end as product_category_name,
					round(sum(oi.price),2) as product_sales
	from order_items as oi
		left join products as prd
			on oi.product_id = prd.product_id
	group by
		case when prd.product_category_name = '' or prd.product_category_name is null
				then 'Unknown'
			 else prd.product_category_name end
	order by product_sales desc;

select*from pbi_category_sales;

-- ==================================================
-- power bi dataset 5
-- order / customer / delivery performance
-- grain: 1 row = 1 order
-- ==================================================

create view pbi_order_detail as

	with order_sales as
		(
			select
				order_id, sum(price) as order_price
			from order_items
			group by order_id
		),

			reviews_by_order as
			(
				select
					order_id, avg(review_score) as review_score
				from order_reviews
				group by order_id
			)

	select
		ord.order_id, ord.order_purchase_timestamp, cm.customer_unique_id, cm.customer_state, os.order_price, rv.review_score,
	case
		when ord.order_status = 'delivered'
			and ord.order_delivered_customer_date <> ''
			and date(ord.order_delivered_customer_date) <= date(ord.order_estimated_delivery_date)
			then 'on time / early'

		when ord.order_status = 'delivered'
			and ord.order_delivered_customer_date <> ''
			and date(ord.order_delivered_customer_date) > date(ord.order_estimated_delivery_date)
			then 'late' else null 
	end as delivery_status,

	case
		when ord.order_status = 'delivered'
			and ord.order_delivered_customer_date <> ''
			then datediff(ord.order_delivered_customer_date, ord.order_purchase_timestamp) else null
	end as delivery_days

	from orders as ord
		left join customers as cm
			on ord.customer_id = cm.customer_id
		left join order_sales as os
			on ord.order_id = os.order_id
		left join reviews_by_order as rv
			on ord.order_id = rv.order_id;
        
	select*from pbi_order_detail ;