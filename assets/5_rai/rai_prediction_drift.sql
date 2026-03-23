/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.rai_prediction_drift
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.ltv_predictions

@bruin */

-- MONITORING PATTERN NOTE: This is a distribution monitoring skeleton, not a production drift detector.
-- Each row represents one scoring batch (grouped by scoring_run_id), enabling comparison across runs.
-- Because the underlying feature population is static (same historical GA4 sample scored each run),
-- drift_score will be minimal or artificial in this MVP setup.
-- In production, compare mean_prediction / stddev_prediction against a baseline snapshot.
SELECT
    scoring_run_id,
    MIN(scored_at)                                              AS evaluation_date,
    'ltv_model'                                                 AS model_name,
    'v1'                                                        AS model_version,
    AVG(predicted_ltv)                                          AS mean_prediction,
    STDDEV(predicted_ltv)                                       AS stddev_prediction,
    MIN(predicted_ltv)                                          AS min_prediction,
    MAX(predicted_ltv)                                          AS max_prediction,
    APPROX_QUANTILES(predicted_ltv, 4)[OFFSET(2)]               AS median_prediction,
    COUNT(*)                                                    AS total_predictions,
    -- drift_score placeholder: in production, compare to baseline distribution snapshot
    0.0                                                         AS drift_score
FROM
    `ecommerce-analytics-bruin.de_pipeline.ltv_predictions`
GROUP BY
    scoring_run_id
