-- =============================================================================
-- Analysis queries against superstore_mx.db
-- Organized from basic to advanced. Each block answers a concrete business
-- question, the kind you'd expect to walk through in an interview or on the
-- job.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Overall business KPIs
-- -----------------------------------------------------------------------------
SELECT
    ROUND(SUM(sales), 2)                       AS total_sales,
    ROUND(SUM(profit), 2)                      AS total_profit,
    COUNT(DISTINCT order_id)                   AS unique_orders,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2) AS overall_margin_pct
FROM fact_sales;


-- -----------------------------------------------------------------------------
-- 2. Sales and profit by category (JOIN + GROUP BY)
-- -----------------------------------------------------------------------------
SELECT
    p.category,
    ROUND(SUM(f.sales), 2)   AS sales,
    ROUND(SUM(f.profit), 2)  AS profit,
    ROUND(SUM(f.profit) * 100.0 / SUM(f.sales), 2) AS margin_pct
FROM fact_sales f
JOIN dim_product p ON p.product_id = f.product_id
GROUP BY p.category
ORDER BY sales DESC;


-- -----------------------------------------------------------------------------
-- 3. Top 10 products by profit (not by sales -- to find products that sell a
--    lot but leave little profit, vs. the ones that are actually profitable)
-- -----------------------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    ROUND(SUM(f.sales), 2)  AS sales,
    ROUND(SUM(f.profit), 2) AS profit
FROM fact_sales f
JOIN dim_product p ON p.product_id = f.product_id
GROUP BY p.product_id
ORDER BY profit DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- 4. Monthly sales with running total (window function: SUM OVER)
-- -----------------------------------------------------------------------------
SELECT
    d.year_month,
    ROUND(SUM(f.sales), 2) AS monthly_sales,
    ROUND(SUM(SUM(f.sales)) OVER (ORDER BY d.year_month), 2) AS running_total_sales
FROM fact_sales f
JOIN dim_date d ON d.date_id = f.date_id
GROUP BY d.year_month
ORDER BY d.year_month;


-- -----------------------------------------------------------------------------
-- 5. Month-over-month growth, % (window function: LAG)
-- -----------------------------------------------------------------------------
WITH monthly_sales AS (
    SELECT d.year_month, SUM(f.sales) AS sales
    FROM fact_sales f
    JOIN dim_date d ON d.date_id = f.date_id
    GROUP BY d.year_month
)
SELECT
    year_month,
    ROUND(sales, 2) AS sales,
    ROUND(
        (sales - LAG(sales) OVER (ORDER BY year_month)) * 100.0
        / LAG(sales) OVER (ORDER BY year_month), 2
    ) AS pct_growth_vs_prior_month
FROM monthly_sales
ORDER BY year_month;


-- -----------------------------------------------------------------------------
-- 6. Customer ranking by total spend, with their position (RANK)
-- -----------------------------------------------------------------------------
SELECT
    c.customer_name,
    c.segment,
    c.region,
    ROUND(SUM(f.sales), 2) AS total_spend,
    RANK() OVER (ORDER BY SUM(f.sales) DESC) AS ranking
FROM fact_sales f
JOIN dim_customer c ON c.customer_id = f.customer_id
GROUP BY c.customer_id
ORDER BY ranking
LIMIT 15;


-- -----------------------------------------------------------------------------
-- 7. Average margin by discount range (CASE + GROUP BY)
--    This is the project's central insight: high discounts destroy profit,
--    and can even push it negative.
-- -----------------------------------------------------------------------------
SELECT
    CASE
        WHEN discount = 0 THEN 'No discount'
        WHEN discount <= 0.15 THEN 'Low (1-15%)'
        WHEN discount <= 0.30 THEN 'Medium (16-30%)'
        ELSE 'High (>30%)'
    END AS discount_range,
    COUNT(*) AS num_lines,
    ROUND(AVG(profit_margin) * 100, 2) AS avg_margin_pct
FROM fact_sales
GROUP BY discount_range
ORDER BY avg_margin_pct DESC;


-- -----------------------------------------------------------------------------
-- 8. Year-over-year (YoY) comparison by category
-- -----------------------------------------------------------------------------
SELECT
    p.category,
    d.year,
    ROUND(SUM(f.sales), 2) AS sales
FROM fact_sales f
JOIN dim_product p ON p.product_id = f.product_id
JOIN dim_date d ON d.date_id = f.date_id
GROUP BY p.category, d.year
ORDER BY p.category, d.year;


-- -----------------------------------------------------------------------------
-- 9. Average shipping time by ship mode
-- -----------------------------------------------------------------------------
SELECT
    ship_mode,
    COUNT(*) AS num_orders,
    ROUND(AVG(ship_days), 2) AS avg_ship_days
FROM fact_sales
GROUP BY ship_mode
ORDER BY avg_ship_days;


-- -----------------------------------------------------------------------------
-- 10. Customers who only ordered once (possible churn risk)
--     Subquery + CTE
-- -----------------------------------------------------------------------------
WITH orders_per_customer AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS num_orders
    FROM fact_sales
    GROUP BY customer_id
)
SELECT
    c.customer_name,
    c.region,
    c.segment
FROM orders_per_customer opc
JOIN dim_customer c ON c.customer_id = opc.customer_id
WHERE opc.num_orders = 1
ORDER BY c.customer_name
LIMIT 20;


-- -----------------------------------------------------------------------------
-- 11. Sales by region and category in cross-tab form (manual pivot with CASE)
-- -----------------------------------------------------------------------------
SELECT
    c.region,
    ROUND(SUM(CASE WHEN p.category = 'Furniture' THEN f.sales ELSE 0 END), 2)        AS furniture,
    ROUND(SUM(CASE WHEN p.category = 'Office Supplies' THEN f.sales ELSE 0 END), 2)  AS office_supplies,
    ROUND(SUM(CASE WHEN p.category = 'Technology' THEN f.sales ELSE 0 END), 2)       AS technology
FROM fact_sales f
JOIN dim_customer c ON c.customer_id = f.customer_id
JOIN dim_product p ON p.product_id = f.product_id
GROUP BY c.region
ORDER BY c.region;


-- -----------------------------------------------------------------------------
-- 12. Top 3 products by profit within each category
--     (window function ROW_NUMBER partitioned -- a common interview ask)
-- -----------------------------------------------------------------------------
WITH product_profit AS (
    SELECT
        p.category,
        p.product_name,
        SUM(f.profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(f.profit) DESC) AS rank_in_category
    FROM fact_sales f
    JOIN dim_product p ON p.product_id = f.product_id
    GROUP BY p.category, p.product_id
)
SELECT category, product_name, ROUND(total_profit, 2) AS total_profit, rank_in_category
FROM product_profit
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;
