/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.model_monitoring_status
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.rai_model_eval
  - ecommerce-analytics-bruin.de_pipeline.rai_prediction_drift
  - ecommerce-analytics-bruin.de_pipeline.ml_scoring_runs

@bruin */

SELECT
    e.model_name,
    e.model_version,
    e.evaluated_at                   AS last_eval_date,
    d.mean_prediction                AS latest_mean_prediction,
    d.drift_score                    AS latest_drift_score,
    s.last_scored_at,
    s.total_rows_scored,
    CURRENT_TIMESTAMP()              AS checked_at
FROM
    `ecommerce-analytics-bruin.de_pipeline.rai_model_eval` e
CROSS JOIN (
    SELECT * FROM `ecommerce-analytics-bruin.de_pipeline.rai_prediction_drift`
    ORDER BY evaluation_date DESC LIMIT 1
) d
LEFT JOIN (
    SELECT
        MAX(scoring_ended_at)   AS last_scored_at,
        SUM(rows_scored)        AS total_rows_scored
    FROM `ecommerce-analytics-bruin.de_pipeline.ml_scoring_runs`
) s ON TRUE
