/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.ml_model_registry
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.ltv_model

@bruin */

SELECT
    'ltv_model'                        AS model_name,
    'v1'                               AS model_version,
    'BOOSTED_TREE_REGRESSOR'           AS model_type,
    CURRENT_TIMESTAMP()                AS registered_at,
    '2020-11-01 to 2021-01-31'         AS training_data_date_range,
    'de_pipeline'                      AS dataset,
    'active'                           AS status
