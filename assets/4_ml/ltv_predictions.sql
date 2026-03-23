/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.ltv_predictions
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.ltv_model
  - ecommerce-analytics-bruin.de_pipeline.ltv_features

@bruin */

-- predicted_value_score: proxy LTV score (historical revenue fit), not a true future prediction.
-- Interpret as a relative customer value rank, not an absolute revenue forecast.
SELECT
    user_pseudo_id,
    predicted_ltv_label                             AS predicted_value_score,
    CURRENT_TIMESTAMP()                             AS scored_at,
    'ltv_model_v1'                                  AS model_name,
    GENERATE_UUID()                                 AS scoring_run_id,
    r_score, f_score, m_score
FROM
    ML.PREDICT(
        MODEL `ecommerce-analytics-bruin.de_pipeline.ltv_model`,
        (SELECT * FROM `ecommerce-analytics-bruin.de_pipeline.ltv_features`)
    )
