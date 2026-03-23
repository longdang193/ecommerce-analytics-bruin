/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.int_customers
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.int_sessions

columns:
  - name: user_pseudo_id
    type: STRING
    checks:
      - name: not_null
      - name: unique

@bruin */

SELECT
    user_pseudo_id,
    MIN(session_date)                                    AS first_seen_date,
    MAX(session_date)                                    AS last_seen_date,
    DATE_DIFF(MAX(session_date), MIN(session_date), DAY) AS customer_lifespan_days,
    COUNT(DISTINCT session_id)                           AS total_sessions,
    SUM(page_views)                                      AS total_page_views,
    SUM(product_views)                                   AS total_product_views,
    SUM(add_to_carts)                                    AS total_add_to_carts,
    SUM(purchases)                                       AS total_purchases,
    SUM(session_revenue_usd)                             AS total_revenue_usd,
    SUM(total_engagement_msec) / 1000.0                  AS total_engagement_sec
FROM
    `ecommerce-analytics-bruin.de_pipeline.int_sessions`
GROUP BY
    user_pseudo_id
