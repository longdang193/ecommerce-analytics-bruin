/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.pipeline_run_log
type: bq.sql
materialization:
    type: table

@bruin */

-- PLACEHOLDER: In production, this would be populated by Bruin Cloud run metadata
-- or a custom Python asset querying the Bruin API. For MVP, this is a synthetic skeleton.
SELECT
    CURRENT_TIMESTAMP()              AS run_timestamp,
    'de-pipeline'                    AS pipeline_name,
    'manual'                         AS trigger_type,
    'success'                        AS status,
    CAST(NULL AS STRING)             AS error_message
