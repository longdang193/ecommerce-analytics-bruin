/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.rai_feature_importance
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.ltv_model

@bruin */

-- INTERPRETATION NOTE: Feature importance here reflects which features drive the proxy LTV label
-- (historical revenue over the observed period), not causal drivers of future lifetime value.
-- Read this as: "which signals matter for customer value scoring in this dataset."
SELECT
    *,
    CURRENT_TIMESTAMP()      AS evaluated_at,
    'ltv_model'              AS model_name,
    'v1'                     AS model_version
FROM
    ML.FEATURE_IMPORTANCE(MODEL `ecommerce-analytics-bruin.de_pipeline.ltv_model`)
