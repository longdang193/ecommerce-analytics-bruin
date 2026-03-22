---
aliases: []
status:
time: 2026-03-22 15-04-38
tags:
  - "#data-engineering"
  - "#zoomcamp"
TARGET DECK:
---

1. Read new GA4 source tables from BigQuery incrementally
2. Flatten nested GA4 fields such as event_params and items
3. Map the GA4 export into a canonical event schema
	- extract fields like session_id, transaction_id, value, page_location
	- standardize column names and data types
4. Build reusable base tables. For example:
	- base_events_flat
	- base_sessions
	- base_purchases
	- base_users
5. Run data quality checks
	- freshness
	- null checks
	- row-count checks
	- valid revenue / purchase values
6. Build business marts
	- kpi_daily
	- funnel_daily
	- rfm_segments
	- ltv_features
7. Train and score the LTV model in BigQuery ML
8. Compute Responsible AI monitoring tables
	- model evaluation
	- feature importance
	- segment parity
	- prediction drift
9. Publish final BI-ready serving tables to BigQuery
