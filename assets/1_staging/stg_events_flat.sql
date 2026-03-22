/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.stg_events_flat
type: bq.sql
materialization:
    type: table

columns:
  - name: event_date
    type: DATE
    checks:
      - name: not_null
  - name: event_timestamp
    type: INTEGER
    checks:
      - name: not_null
  - name: event_name
    type: STRING
    checks:
      - name: not_null
  - name: user_pseudo_id
    type: STRING
    checks:
      - name: not_null

@bruin */

SELECT
    PARSE_DATE('%Y%m%d', event_date)                                                              AS event_date,
    event_timestamp,
    event_name,
    user_pseudo_id,
    user_first_touch_timestamp,
    device.category                                                                                AS device_category,
    device.operating_system                                                                        AS device_os,
    device.web_info.browser                                                                        AS browser,
    geo.country                                                                                    AS country,
    geo.city                                                                                       AS city,
    traffic_source.source                                                                          AS traffic_source,
    traffic_source.medium                                                                          AS traffic_medium,
    traffic_source.name                                                                            AS campaign,
    ecommerce.total_item_quantity                                                                  AS total_item_quantity,
    ecommerce.purchase_revenue_in_usd                                                              AS purchase_revenue_usd,
    ecommerce.unique_items                                                                         AS unique_items,
    ecommerce.transaction_id                                                                       AS transaction_id,
    -- Extract key event_params (each is a RECORD in a REPEATED field)
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title')                AS page_title,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')             AS page_location,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer')             AS page_referrer,
    (SELECT value.int_value    FROM UNNEST(event_params) WHERE key = 'ga_session_id')             AS ga_session_id,
    (SELECT value.int_value    FROM UNNEST(event_params) WHERE key = 'ga_session_number')         AS ga_session_number,
    (SELECT value.int_value    FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')      AS engagement_time_msec
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
    -- Bounded sample: 2020-11-01 to 2021-01-31 (batch read, not incremental)
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
