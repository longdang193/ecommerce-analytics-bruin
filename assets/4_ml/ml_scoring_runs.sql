/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.ml_scoring_runs
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.ltv_predictions

@bruin */

SELECT
    'ltv_model_v1'                    AS model_name,
    COUNT(*)                          AS rows_scored,
    MIN(scored_at)                    AS scoring_started_at,
    MAX(scored_at)                    AS scoring_ended_at,
    CURRENT_TIMESTAMP()               AS logged_at
FROM
    `ecommerce-analytics-bruin.de_pipeline.ltv_predictions`
