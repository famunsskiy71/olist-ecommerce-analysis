# Olist E-Commerce Analysis

End-to-end analysis of the Olist Brazilian e-commerce dataset using MySQL and Power BI.

The project covers sales performance, customer behavior, payment methods, delivery performance, and customer reviews.

![Olist E-Commerce Dashboard](dashboard.jpg)

## Project Overview

The analysis was built from 9 related CSV files covering customers, orders, order items, products, sellers, payments, reviews, geolocation, and product category translations.

The workflow included:

- loading and validating the source data in MySQL
- checking table relationships and data grain
- handling ingestion issues in messy CSV data
- answering 8 business questions in SQL
- preparing dedicated SQL views for Power BI
- building a one-page Power BI dashboard

## Business Questions

1. How did monthly order volume and product sales change?
2. Which product categories generated the most product sales?
3. Which customer states generated the most orders and product sales?
4. Which payment methods were used most often, and how did payment value differ?
5. What percentage of customers made repeat purchases?
6. How did average order value change over time?
7. How well did delivery performance meet customer expectations?
8. How was delivery timing associated with customer review scores?

## Key Findings

- **99.4K** total orders
- **13.59M** in product sales
- **3.12%** repeat customer rate
- **93.23%** of delivered orders arrived on time or early
- On-time / early deliveries took about **10.94 days** on average
- Late deliveries took about **33.91 days** on average
- Average review score was **4.29** for on-time / early deliveries and **2.27** for late deliveries
- São Paulo (**SP**) generated the highest product sales among customer states

Late delivery is associated with substantially lower review scores in this dataset.

## Data Preparation & Modeling

A large part of the project was making sure the analysis was performed at the correct level of detail.

Some of the main checks and transformations:

- validated imported row counts against the source files
- handled UTF-8 / Portuguese character issues during ingestion
- worked around multiline records in the reviews dataset
- checked relationship cardinality before joining tables
- aggregated order items before joining them to order-level data
- used `customer_unique_id` instead of `customer_id` for repeat customer analysis
- aggregated multiple review records to one row per order
- avoided direct joins where ZIP-prefix relationships could multiply rows

For Power BI, I created five SQL views with clearly defined grains:

- `pbi_orders_monthly` — one row per month
- `pbi_state_performance` — one row per customer state
- `pbi_payment_methods` — one row per payment type
- `pbi_category_sales` — one row per product category
- `pbi_order_detail` — one row per order

## SQL Files

### `01_business_analysis.sql`

Contains the SQL used to answer the 8 business questions.

### `02_powerbi_data.sql`

Creates the SQL views used as the Power BI data layer.

## Dashboard

The Power BI dashboard combines the main results into a single page covering:

- monthly order and product sales trends
- customer-state performance
- top product categories
- delivery performance
- payment methods
- review score by delivery status

The full Power BI file is included in the repository:

`03_olist_ecommerce_dashboard.pbix`

## Business Takeaways

Based on the analysis, the main areas worth further investigation are:

- low repeat purchase behavior
- reduction of late deliveries
- regional concentration of product sales
- concentration across product categories

Delivery reliability is especially important to monitor because late orders are associated with much lower customer review scores.

## Limitations

- **Product Sales** is calculated as the sum of item prices; it is not profit or platform revenue
- the dataset is historical and does not represent current Olist performance
- the relationship between delivery timing and review score is an association, not proof of causation
- some orders contain multiple payment or review records and therefore require aggregation
- repeat customer rate depends on the customer definition and the time period covered by the dataset

## Tools

`MySQL` · `Power BI` · `Power Query` · `CSV preprocessing`
