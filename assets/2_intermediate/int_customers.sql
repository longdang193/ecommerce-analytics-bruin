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
    MIN(session_date)                                                                           AS first_seen_date,
    MAX(session_date)                                                                           AS last_seen_date,
    MIN(CASE WHEN purchases > 0 THEN session_date END)                                         AS first_purchase_date,
    MAX(CASE WHEN purchases > 0 THEN session_date END)                                         AS last_purchase_date,
    DATE_DIFF(MAX(session_date), MIN(session_date), DAY)                                       AS customer_lifespan_days,
    DATE_DIFF(DATE('2021-01-31'), MAX(session_date), DAY)                                      AS days_since_last_activity,
    -- Note: days_since_last_purchase will be NULL for users with no purchase history
    DATE_DIFF(DATE('2021-01-31'), MAX(CASE WHEN purchases > 0 THEN session_date END), DAY)    AS days_since_last_purchase,
    COUNT(DISTINCT session_id)                                                                  AS total_sessions,
    SUM(page_views)                                                                            AS total_page_views,
    SUM(product_views)                                                                         AS total_product_views,
    SUM(add_to_carts)                                                                          AS total_add_to_carts,
    SUM(purchases)                                                                             AS total_purchases,
    SUM(session_revenue_usd)                                                                   AS total_revenue_usd,
    CASE WHEN SUM(purchases) > 0 THEN TRUE ELSE FALSE END                                      AS has_purchase_history,
    SAFE_DIVIDE(SUM(session_revenue_usd), NULLIF(SUM(purchases), 0))                           AS avg_order_value,
    SUM(total_engagement_msec) / 1000.0                                                        AS total_engagement_sec,
    CASE
        WHEN DATE_DIFF(DATE('2021-01-31'), MAX(session_date), DAY) > 90 THEN 'churned'
        WHEN DATE_DIFF(DATE('2021-01-31'), MAX(session_date), DAY) > 60 THEN 'at_risk'
        WHEN DATE_DIFF(DATE('2021-01-31'), MAX(session_date), DAY) > 30 THEN 'declining'
        ELSE 'active'
    END                                                                                        AS activity_status
FROM
    `ecommerce-analytics-bruin.de_pipeline.int_sessions`
GROUP BY
    user_pseudo_id
