/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.ltv_features
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.int_customers
  - ecommerce-analytics-bruin.de_pipeline.rfm_segments

columns:
  - name: user_pseudo_id
    type: STRING
    checks:
      - name: not_null
      - name: unique

@bruin */

-- NOTE: All features are anchored to the snapshot date 2021-01-31.
-- RFM scores and recency fields are only valid relative to that cutoff.
SELECT
    c.user_pseudo_id,
    -- Lifecycle / activity signals
    c.customer_lifespan_days,
    c.days_since_last_activity,
    c.days_since_last_purchase,
    c.has_purchase_history,
    c.activity_status,
    -- Behavioral counters
    c.total_sessions,
    c.total_page_views,
    c.total_product_views,
    c.total_add_to_carts,
    c.total_purchases,
    c.total_revenue_usd,
    c.total_engagement_sec,
    -- Derived ratios
    SAFE_DIVIDE(c.total_revenue_usd, NULLIF(c.total_purchases, 0))   AS avg_order_value,
    SAFE_DIVIDE(c.total_purchases, NULLIF(c.total_sessions, 0))      AS purchase_rate,
    -- RFM scores from rfm_segments (compact segment signals)
    r.r_score,
    r.f_score,
    r.m_score,
    -- PROXY LABEL: total_revenue_usd over the same observed period as features.
    -- This makes the model a customer VALUE SCORING model, not a true future-LTV predictor.
    -- Acceptable for MVP; production would use a forward-looking prediction window.
    c.total_revenue_usd AS ltv_label
FROM
    `ecommerce-analytics-bruin.de_pipeline.int_customers` c
LEFT JOIN
    `ecommerce-analytics-bruin.de_pipeline.rfm_segments` r USING (user_pseudo_id)
