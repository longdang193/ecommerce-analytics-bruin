/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.data_quality_results
type: bq.sql
materialization:
    type: table

@bruin */

-- PLACEHOLDER: In production, populated by Bruin check results via API or Cloud integration.
-- For MVP, this is a single representative synthetic record.
SELECT
    CURRENT_TIMESTAMP()              AS check_timestamp,
    'stg_events_flat'                AS table_name,
    'not_null'                       AS check_type,
    'event_date'                     AS column_name,
    TRUE                             AS passed,
    0                                AS failed_rows
