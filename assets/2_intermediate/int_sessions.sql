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

@bruin */

SELECT
    user_pseudo_id,
    CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))  AS session_id,
    ga_session_id,
    MIN(event_date)                                              AS session_date,
    MIN(event_timestamp)                                         AS session_start,
    MAX(event_timestamp)                                         AS session_end,
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
    SUM(COALESCE(engagement_time_msec, 0))                       AS total_engagement_msec
FROM
    `ecommerce-analytics-bruin.de_pipeline.stg_events_flat`
GROUP BY
    user_pseudo_id, ga_session_id
