/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.int_sessions
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.stg_events_flat

columns:
  - name: user_pseudo_id
    type: STRING
    checks:
      - name: not_null
  - name: session_id
    type: STRING
    checks:
      - name: not_null
      - name: unique

@bruin */

SELECT
    user_pseudo_id,
    CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))  AS session_id,
    ga_session_id,
    MIN(event_date)                                              AS session_date,
    MIN(event_timestamp)                                         AS session_start,
    MAX(event_timestamp)                                         AS session_end,
    -- Note: ANY_VALUE assumes these dimensions are stable within a session.
    ANY_VALUE(country)                                           AS country,
    ANY_VALUE(device_category)                                   AS device_category,
    ANY_VALUE(traffic_source)                                    AS traffic_source,
    ANY_VALUE(traffic_medium)                                    AS traffic_medium,
    ANY_VALUE(campaign)                                          AS campaign,
    COUNTIF(event_name = 'page_view')                            AS page_views,
    COUNTIF(event_name = 'view_item')                            AS product_views,
    COUNTIF(event_name = 'add_to_cart')                          AS add_to_carts,
    COUNTIF(event_name = 'begin_checkout')                       AS checkouts,
    COUNTIF(event_name = 'purchase')                             AS purchases,
    SUM(COALESCE(purchase_revenue_usd, 0))                       AS session_revenue_usd,
    SUM(COALESCE(engagement_time_msec, 0))                       AS total_engagement_msec,
    (MAX(event_timestamp) - MIN(event_timestamp)) / 1000000.0    AS session_length_sec,
    MAX(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END)    AS reached_view,
    MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END)  AS reached_cart,
    MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS reached_checkout,
    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END)     AS reached_purchase,
    CASE
        WHEN MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) = 1    THEN 'purchase'
        WHEN MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) = 1 THEN 'checkout'
        WHEN MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) = 1 THEN 'cart'
        WHEN MAX(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END) = 1   THEN 'view'
        WHEN COUNTIF(event_name = 'page_view') > 0                           THEN 'browse'
        ELSE 'other'
    END                                                          AS funnel_stage
FROM
    `ecommerce-analytics-bruin.de_pipeline.stg_events_flat`
WHERE
    ga_session_id IS NOT NULL
GROUP BY
    user_pseudo_id, ga_session_id
