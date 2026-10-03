-- ==================================================
-- business question 1
-- how did monthly order volume and product sales change?
-- ==================================================

-- monthly order volume

with monthly_orders as 
		(
			select
				order_id, year(order_purchase_timestamp) as purchase_year, month(order_purchase_timestamp) as purchase_month
			from orders
		)

			select
						purchase_year, purchase_month, count(order_id) as month_orders
			from monthly_orders
				group by purchase_year, purchase_month
					order by purchase_year, purchase_month;


-- monthly product sales

	with order_sales as (
		select
			order_id, sum(price) as order_price
		from order_items
			group by order_id
	),

		monthly_sales as (
			select
				ord.order_id, year(ord.order_purchase_timestamp) as purchase_year, month(ord.order_purchase_timestamp) as purchase_month, os.order_price
			from orders as ord
				left join order_sales as os
					on ord.order_id = os.order_id
		)

				select
					purchase_year, purchase_month, round(sum(order_price), 2) as month_product_sales
				from monthly_sales
					group by purchase_year, purchase_month
						order by purchase_year, purchase_month;



-- ==================================================
-- business question 2
-- which product categories generate the most product sales?
-- ==================================================

	with category_sales as 
		
			(
				select
						prd.product_category_name, round(sum(oi.price), 2) as product_sales
				from order_items as oi
					left join products as prd
						on oi.product_id = prd.product_id
				group by prd.product_category_name
			)

					select
						case
							when product_category_name = '' or product_category_name is null then 'Unknown'
							else product_category_name
						end as product_category_name,
							product_sales
					from category_sales
						order by product_sales desc;



-- ==================================================
-- business question 3
-- which customer states generate the most orders and product sales?
-- ==================================================

-- orders by customer state

	with orders_by_state as 
				(
					select
						ord.order_id, ord.customer_id, cm.customer_state
					from orders as ord
						left join customers as cm
							on ord.customer_id = cm.customer_id
				)

		select
			customer_state, count(order_id) as state_orders_count
		from orders_by_state
			group by customer_state
				order by state_orders_count desc;


-- product sales by customer state

	with order_sales as 
		(
			select
				order_id, sum(price) as order_price
			from order_items
				group by order_id
		),

			sales_by_state as (
				select
					os.order_id, os.order_price, cm.customer_state
				from order_sales as os
					left join orders as ord
						on os.order_id = ord.order_id
					left join customers as cm
						on ord.customer_id = cm.customer_id
			)


		select
			customer_state, round(sum(order_price), 2) as state_product_sales
		from sales_by_state
		group by customer_state
			order by state_product_sales desc;



-- ==================================================
-- business question 4
-- which payment methods are used most often,
-- and how does payment value differ by method?
-- ==================================================

-- aggregate payment records to one row per order + payment method

	with payment_by_order as 
			(
				select
					order_id, payment_type, sum(payment_value) as payment_value
				from order_payments
				group by order_id, payment_type
			)


	select
		payment_type, count(order_id) as order_count
	from payment_by_order
	group by payment_type
		order by order_count desc;


-- average payment value by payment method

	with payment_by_order as 
			(
				select
					order_id, payment_type, sum(payment_value) as payment_value
				from order_payments
				group by order_id, payment_type
			)


	select
		payment_type, round(avg(payment_value), 2) as avg_payment_value
	from payment_by_order
	group by payment_type
		order by avg_payment_value desc;



-- ==================================================
-- business question 5
-- what percentage of customers made repeat purchases?
-- ==================================================

	with customer_orders as 
			(
				select
					ord.order_id, cm.customer_unique_id
				from orders as ord
				left join customers as cm
					on ord.customer_id = cm.customer_id
			),

				orders_per_customer as
						(
							select
								customer_unique_id, count(order_id) as order_count
							from customer_orders
							group by customer_unique_id
						)

	select
    
		count(*) as unique_customers,
			sum( case when order_count > 1 then 1 else 0 end) as repeat_customers,
		round(sum(case when order_count > 1 then 1 else 0 end) / count(*) * 100,2) as repeat_customer_rate_pct
                
	from orders_per_customer;

-- analysis result:
-- unique customers: 96,096
-- repeat customers: 2,997
-- repeat customer rate: ~3.12%



-- ==================================================
-- business question 6
-- how does average order value vary over time?
-- ==================================================

	with order_values as 
			(
				select
					order_id, sum(price) as order_price
				from order_items
				group by order_id
			),

		orders_with_dates as 
				(
					select
						ov.order_id, ov.order_price, ord.order_purchase_timestamp
					from order_values as ov
						left join orders as ord
							on ov.order_id = ord.order_id
				),

			monthly_aov as
					 (
						select
							year(order_purchase_timestamp) as order_year, month(order_purchase_timestamp) as order_month,
								round(avg(order_price), 2) as avg_order_price,
							str_to_date(concat(year(order_purchase_timestamp),'-',month(order_purchase_timestamp),'-01'),'%Y-%m-%d') as month_start
						from orders_with_dates
						group by year(order_purchase_timestamp), month(order_purchase_timestamp)
					),

				monthly_aov_with_lag as 
						(
							select
								*,
									lag(avg_order_price) over(order by month_start) as prior_month_aov,
									lag(month_start) over(order by month_start) as prior_month_start
                                    
							from monthly_aov
						)

	select
			order_year, order_month, avg_order_price,
		case
			when timestampdiff(month, prior_month_start, month_start) = 1
			then concat(round(((avg_order_price - prior_month_aov) / prior_month_aov) * 100,2),'%')
				else null
		end as mom_aov_change
	from monthly_aov_with_lag
		order by month_start;



-- ==================================================
-- business question 7
-- how well does delivery performance meet customer expectations?
-- ==================================================

	with delivery_performance as 
			(
				select
					order_id,
						case
							when date(order_delivered_customer_date) <= date(order_estimated_delivery_date)
								then 'on time / early'
							else 'late'
						end as delivery_status,
					datediff(order_delivered_customer_date,order_purchase_timestamp) as delivery_days
				from orders
				where order_status = 'delivered'
					and order_delivered_customer_date <> ''
			)

	select
		delivery_status, count(order_id) as order_count,
		round(count(order_id) /(select count(*) from delivery_performance) * 100,2) as delivery_rate_pct,round(avg(delivery_days), 2) as avg_delivery_days
	from delivery_performance
		group by delivery_status
			order by order_count desc;

-- analysis result:
-- on time / early: 89,936 orders, ~93.23%, avg delivery ~10.94 days
-- late: 6,534 orders, ~6.77%, avg delivery ~33.91 days



-- ==================================================
-- business question 8
-- how does delivery delay affect customer review scores?
-- ==================================================

-- reviews are aggregated to one row per order before the join
-- because some orders contain more than one review row

	with reviews_by_order as 
			(
				select
					order_id, avg(review_score) as review_score
				from order_reviews
					group by order_id
			),

		delivery_status as 
				(
					select
						order_id,
						case
							when date(order_delivered_customer_date) <= date(order_estimated_delivery_date)
								then 'on time / early'
							else 'late'
						end as delivery_status
					from orders
					where order_status = 'delivered'
						and order_delivered_customer_date <> ''
				),

			delivery_reviews as 
					(
						select
							ds.order_id, ds.delivery_status, rbo.review_score
						from delivery_status as ds
							inner join reviews_by_order as rbo
								on ds.order_id = rbo.order_id
					)

	select
		delivery_status, count(order_id) as reviewed_orders, round(avg(review_score), 2) as avg_review_score
	from delivery_reviews
		group by delivery_status
			order by avg_review_score desc;

-- analysis result:
-- on time / early: avg review score ~4.29
-- late: avg review score ~2.27