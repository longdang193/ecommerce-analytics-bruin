/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.rai_segment_parity
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.ltv_predictions
  - ecommerce-analytics-bruin.de_pipeline.rfm_segments

@bruin */

-- BUSINESS PARITY NOTE: This is a business segment comparison, NOT a regulated-ML fairness metric.
-- Segments (Champions, Loyal, etc.) are defined by the same behavioral features that drive predictions,
-- so prediction differences across segments primarily reflect the segment definitions themselves.
-- Interpret parity_gap as a descriptive business insight, not as evidence of model bias.
WITH segment_stats AS (
    SELECT
        r.customer_segment                                          AS segment_name,
        AVG(p.predicted_ltv)                                        AS avg_predicted_ltv,
        STDDEV(p.predicted_ltv)                                     AS stddev_predicted_ltv,
        APPROX_QUANTILES(p.predicted_ltv, 4)[OFFSET(2)]             AS median_predicted_ltv,
        COUNT(*)                                                    AS segment_size
    FROM
        `ecommerce-analytics-bruin.de_pipeline.ltv_predictions` p
    JOIN
        `ecommerce-analytics-bruin.de_pipeline.rfm_segments` r USING (user_pseudo_id)
    GROUP BY r.customer_segment
),
overall AS (
    SELECT AVG(predicted_ltv) AS global_avg
    FROM `ecommerce-analytics-bruin.de_pipeline.ltv_predictions`
)
SELECT
    s.segment_name,
    s.avg_predicted_ltv,
    s.stddev_predicted_ltv,
    s.median_predicted_ltv,
    s.segment_size,
    o.global_avg,
    ROUND(ABS(s.avg_predicted_ltv - o.global_avg) / NULLIF(o.global_avg, 0), 4)  AS parity_gap,
    ROUND(ABS(s.avg_predicted_ltv - o.global_avg) / NULLIF(o.global_avg, 0), 4)  AS relative_gap,
    ABS(s.avg_predicted_ltv - o.global_avg) / NULLIF(o.global_avg, 0) > 0.20     AS parity_alert,
    CURRENT_TIMESTAMP()                                                            AS evaluated_at,
    'ltv_model'                                                                    AS model_name,
    'v1'                                                                           AS model_version
FROM segment_stats s
CROSS JOIN overall o
