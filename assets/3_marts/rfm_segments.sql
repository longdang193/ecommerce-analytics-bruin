/* @bruin

name: ecommerce-analytics-bruin.de_pipeline.rfm_segments
type: bq.sql
materialization:
    type: table
depends:
  - ecommerce-analytics-bruin.de_pipeline.int_customers

columns:
  - name: user_pseudo_id
    type: STRING
    checks:
      - name: not_null
      - name: unique

@bruin */

WITH rfm_raw AS (
    SELECT
        user_pseudo_id,
        DATE('2021-01-31')                                  AS snapshot_date,
        DATE_DIFF(DATE('2021-01-31'), last_seen_date, DAY)  AS recency_days,
        total_sessions                                      AS frequency,
        total_revenue_usd                                   AS monetary
    FROM
        `ecommerce-analytics-bruin.de_pipeline.int_customers`
),
rfm_scored AS (
    SELECT
        *,
        -- Scoring convention: higher score = better.
        -- recency: ORDER BY DESC so that large recency_days (least recent) land in bucket 1 (worst)
        --          and small recency_days (most recent) land in bucket 5 (best).
        -- frequency/monetary: ORDER BY ASC so higher values get higher scores.
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
    FROM rfm_raw
)
SELECT
    *,
    CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_segment,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3                   THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2                   THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3                   THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2                   THEN 'Hibernating'
        ELSE 'Other'
    END AS customer_segment
FROM rfm_scored
