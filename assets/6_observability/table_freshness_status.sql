/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.table_freshness_status
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.kpi_daily
  - ecommerce-analytics-bruin.de_pipeline.funnel_daily
  - ecommerce-analytics-bruin.de_pipeline.ltv_predictions

@bruin */

SELECT
    table_id  AS table_name,
    TIMESTAMP_MILLIS(last_modified_time) AS last_modified_time,
    row_count
FROM
    `ecommerce-analytics-bruin.de_pipeline.__TABLES__`
WHERE
    table_id IN (
        'kpi_daily', 'funnel_daily', 'rfm_segments',
        'ltv_features', 'ltv_predictions',
        'rai_model_eval', 'rai_segment_parity'
    )
