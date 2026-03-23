/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.ltv_prediction_history
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.ltv_predictions

@bruin */

-- Append-only snapshot log of prediction runs.
-- Each full run appends all predictions with a shared scoring_run_id; this is NOT deduplicated history.
SELECT
    user_pseudo_id,
    predicted_value_score,
    scored_at,
    model_name,
    scoring_run_id
FROM
    `ecommerce-analytics-bruin.de_pipeline.ltv_predictions`
