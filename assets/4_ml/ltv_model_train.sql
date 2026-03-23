/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.ltv_model
type: bq.sql
depends:
  - ecommerce-analytics-bruin.de_pipeline.ltv_features

@bruin */

CREATE OR REPLACE MODEL `ecommerce-analytics-bruin.de_pipeline.ltv_model`
OPTIONS(
    model_type = 'BOOSTED_TREE_REGRESSOR',
    input_label_cols = ['ltv_label'],
    data_split_method = 'AUTO_SPLIT',
    max_iterations = 50
) AS
-- Customer Value Scoring Model: predicts proxy LTV (historical revenue) from behavioral features.
-- This is NOT a true forward-looking LTV model; it fits observed value over the same period as features.
-- Snapshot date: 2021-01-31. All recency/RFM features are relative to this cutoff.
SELECT
    customer_lifespan_days,
    days_since_last_activity,
    days_since_last_purchase,
    has_purchase_history,
    total_sessions,
    total_page_views,
    total_product_views,
    total_add_to_carts,
    total_purchases,
    total_engagement_sec,
    avg_order_value,
    purchase_rate,
    r_score,
    f_score,
    m_score,
    ltv_label
FROM
    `ecommerce-analytics-bruin.de_pipeline.ltv_features`
WHERE
    ltv_label IS NOT NULL
