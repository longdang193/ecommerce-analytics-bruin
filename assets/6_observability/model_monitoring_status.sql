/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.model_monitoring_status
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.rai_model_eval
  - ecommerce-analytics-bruin.de_pipeline.rai_prediction_drift

@bruin */

SELECT
    e.model_name,
    e.model_version,
    e.evaluated_at                   AS last_eval_date,
    d.mean_prediction                AS latest_mean_prediction,
    d.drift_score                    AS latest_drift_score,
    CURRENT_TIMESTAMP()              AS checked_at
FROM
    `ecommerce-analytics-bruin.de_pipeline.rai_model_eval` e
CROSS JOIN (
    SELECT * FROM `ecommerce-analytics-bruin.de_pipeline.rai_prediction_drift`
    ORDER BY evaluation_date DESC LIMIT 1
) d
