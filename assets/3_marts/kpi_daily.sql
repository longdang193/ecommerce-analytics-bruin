/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.kpi_daily
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.int_sessions

columns:
  - name: event_date
    type: DATE
    checks:
      - name: not_null

@bruin */

SELECT
    session_date                               AS event_date,
    country,
    device_category,
    traffic_source,
    traffic_medium,
    COUNT(DISTINCT session_id)                 AS sessions,
    COUNT(DISTINCT user_pseudo_id)             AS unique_users,
    SUM(purchases)                             AS orders,
    SUM(session_revenue_usd)                   AS gross_revenue,
    -- net_revenue placeholder (no returns data in GA4 demo)
    SUM(session_revenue_usd)                   AS net_revenue,
    SAFE_DIVIDE(SUM(session_revenue_usd), NULLIF(SUM(purchases), 0)) AS avg_order_value,
    SAFE_DIVIDE(
        COUNTIF(purchases > 0),
        COUNT(DISTINCT session_id)
    )                                          AS session_conversion_rate
FROM
    `ecommerce-analytics-bruin.de_pipeline.int_sessions`
GROUP BY
    session_date, country, device_category, traffic_source, traffic_medium
