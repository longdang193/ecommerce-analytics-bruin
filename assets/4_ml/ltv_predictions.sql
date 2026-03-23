/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.ltv_predictions
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.ltv_model
  - ecommerce-analytics-bruin.de_pipeline.ltv_features

@bruin */

-- predicted_ltv: proxy LTV score (historical revenue fit), not a true future prediction.
-- Interpret as a relative customer value rank, not an absolute revenue forecast.
SELECT
    user_pseudo_id,
    predicted_ltv_label                             AS predicted_ltv,
    CURRENT_TIMESTAMP()                             AS scored_at,
    'ltv_model_v1'                                  AS model_name,
    -- scoring_run_id: shared across all rows in one run (timestamp-derived, not per-row UUID)
    FORMAT_TIMESTAMP('%Y%m%dT%H%M%S', CURRENT_TIMESTAMP()) AS scoring_run_id,
    r_score, f_score, m_score
FROM
    ML.PREDICT(
        MODEL `ecommerce-analytics-bruin.de_pipeline.ltv_model`,
        (SELECT * FROM `ecommerce-analytics-bruin.de_pipeline.ltv_features`)
    )
