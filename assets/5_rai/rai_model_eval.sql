/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.rai_model_eval
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.ltv_model

@bruin */

-- MODEL EVALUATION TYPE: evaluation (not monitoring)
-- INTERPRETATION NOTE: Metrics are computed against the PROXY LABEL (historical revenue over the same
-- observed period as features), not true future LTV. This model is a customer value scorer.
-- Treat R², MAE, MSE as fit quality on observed data — not predictive accuracy for future revenue.
SELECT
    *,
    CURRENT_TIMESTAMP() AS evaluated_at,
    'ltv_model'         AS model_name,
    'v1'                AS model_version
FROM
    ML.EVALUATE(MODEL `ecommerce-analytics-bruin.de_pipeline.ltv_model`)
