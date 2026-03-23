---
aliases: []
status:
time: 2026-03-22 14-27-48
tags:
  - "#data-engineering"
  - "#zoomcamp"
TARGET DECK:
---

```text
GA4 web ecommerce demo dataset in BigQuery
(bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*)
   ↓
Bruin pipeline
  - read source tables incrementally
  - flatten / normalize GA4 event fields
  - build base business tables
  - run data quality checks
  - build KPI / funnel / RFM / LTV marts
  - build feature snapshots for ML
  - train + version model in BigQuery ML
  - score customers and write prediction snapshots
  - compute Responsible AI monitoring tables
   ↓
BigQuery serving layer
  - kpi_daily
  - funnel_daily
  - rfm_segments
  - ltv_features
  - ltv_predictions
  - ltv_prediction_history
  - ml_model_registry
  - ml_training_runs
  - ml_scoring_runs
  - rai_model_eval
  - rai_feature_importance
  - rai_segment_parity
  - rai_prediction_drift
   ↓
Semantic model — Cube (cube.dev)
  - tool: Cube open-source, deployed to Cube Cloud (GCP us-central1, free tier)
  - deployment: https://ldang.cubecloud.dev/d/2
  - cubes (physical table definitions, 9 cubes)
      - kpi_daily, funnel_daily, rfm_segments
      - ltv_predictions, ml_scoring_runs
      - rai_model_eval, rai_feature_importance
      - rai_segment_parity, rai_prediction_drift
  - views (business topic definitions, 9 views)
      - executive_kpis      → kpi_daily
      - funnel_performance  → funnel_daily
      - customer_segments   → rfm_segments
      - predictive_ltv      → ltv_predictions
      - model_eval          → rai_model_eval
      - feature_importance  → rai_feature_importance
      - segment_monitoring  → rai_segment_parity  (incl. parity_alert flag)
      - prediction_drift    → rai_prediction_drift
      - scoring_freshness   → ml_scoring_runs
  - shared measures (defined once, correct everywhere)
      - gross_revenue (SUM), net_revenue (SUM), orders (SUM), sessions (SUM)
      - avg_order_value = SUM(gross_revenue) / SUM(orders)
      - session_conversion_rate = SUM(purchase_sessions) / SUM(sessions)
      - cart_rate, checkout_rate, purchase_rate
      - avg_predicted_ltv, parity_gap, alert_count, drift_score, r2_score
  - shared dimensions
      - date (event_date, scored_at, evaluated_at)
      - country, device_category, traffic_source, campaign
      - customer_segment, model_version, segment_name, feature, parity_alert
  - Dev Playground: localhost:4000 (local dev)
  - SQL API: Cube Cloud — rose-fowl.sql.gcp-us-central1.cubecloudapp.dev:5432
      - database: rose-fowl  |  user: cube
   ↓
Lineage + metadata outputs
  - source-to-table lineage
  - table-to-mart lineage
  - mart-to-metric lineage
  - metric-to-dashboard lineage
  - source-to-model-feature lineage
  - source-to-prediction lineage
   ↓
Observability layer
  - pipeline run status
  - data freshness / latency
  - row-count / volume monitoring
  - data quality check results
  - model training status
  - model scoring freshness
  - prediction drift monitoring
  - parity / fairness threshold alerts
  - dashboard source freshness status
   ↓
BI dashboards — Looker Studio (connected ✓)
  - connector: PostgreSQL → Cube Cloud SQL API (stable, no tunnels)
  - data source: rose-fowl.sql.gcp-us-central1.cubecloudapp.dev:5432
  - views available: executive_kpis, funnel_performance, customer_segments,
                     predictive_ltv, model_eval, segment_monitoring,
                     scoring_freshness, prediction_drift, feature_importance
  - dashboards to build
      - Executive KPIs
      - Funnel Performance
      - Customer Segments (RFM)
      - Predictive LTV
      - Responsible AI Monitoring

Deployment layer
  - local Docker-based development
  - environment configs (dev / prod)
  - CI validation for SQL / Python / pipeline definitions
  - scheduled job deployment
  - lightweight release process for pipeline + semantic model changes
```

## In one line

```text
GA4 → BigQuery → Bruin transforms + checks → BigQuery ML + RAI → serving tables → Cube semantic layer (cubes + views + measures) → lineage + observability → Looker Studio BI, with lightweight deployment around the stack
```

## What each layer does

**GA4 + BigQuery**: GA4 exports raw event data into BigQuery, where it lands in daily event tables.

**Bruin**: Bruin is the pipeline framework for transformation, dependency ordering, incremental processing, and data quality using SQL/Python assets against BigQuery.

**BigQuery ML**: Model training, versioning, and scoring happen inside BigQuery using SQL, so the MVP does not need a separate ML platform.

**Productized ML layer**: Instead of only producing one predictions table, the pipeline also writes:

* feature snapshots
* model registry metadata
* training run metadata
* scoring run metadata
* prediction history

This makes the ML part operational rather than one-off.

**Responsible AI layer**: Bruin materializes evaluation, explainability, drift, and segment-parity tables into BigQuery for monitoring and BI.

**BigQuery serving layer**: This is the curated physical data layer. It contains trusted, analysis-ready tables produced by the pipeline.

**Semantic model — Cube**: Cube (cube.dev) is the open-source semantic layer on top of the serving tables. It is deployed to **Cube Cloud** (GCP us-central1) for a stable, cloud-accessible endpoint. It defines:

* **Cubes** — 9 physical table definitions with typed dimensions and `SUM/COUNT` base measures
* **Views** — 9 business-topic facades (executive_kpis, funnel_performance, customer_segments, predictive_ltv, model_eval, feature_importance, segment_monitoring, prediction_drift, scoring_freshness), each exposing only curated fields
* **Calculated measures** — defined once (`avg_order_value = SUM(revenue) / SUM(orders)`), enforced everywhere
* **parity_alert** — boolean flag on `segment_monitoring` firing when a segment's predicted LTV deviates >20% from the global average
* **Dev Playground** — live query interface at localhost:4000 for local development
* **SQL API** — PostgreSQL wire protocol on Cube Cloud (`rose-fowl.sql.gcp-us-central1.cubecloudapp.dev:5432`) — connected to Looker Studio

This prevents every dashboard from redefining metrics differently. Cube was chosen over LookML (requires paid Looker instance) and Power BI (Windows-only, different ecosystem).

**Lineage + metadata outputs**: This makes lineage a first-class output instead of an implicit idea. It shows:

* where each metric comes from
* which source tables feed which marts
* which features feed which models
* which dashboards consume which topics

**Observability layer**: This makes monitoring explicit rather than implicit. It tracks:

* job success / failure
* freshness
* row volumes
* check status
* model freshness
* drift / parity alerts
* dashboard data readiness

**BI layer**: Dashboards read from the semantic model, not directly from raw tables or raw GA4 events.

**Deployment layer**: This makes the project runnable and maintainable, even if lightweight:

* local Docker setup
* simple CI
* environment separation
* scheduled execution
* controlled release process

## Core output tables (example)

Serving / analytics tables:

* `kpi_daily`
* `funnel_daily`
* `rfm_segments`
* `ltv_features`
* `ltv_predictions`
* `ltv_prediction_history`
* `rai_model_eval`
* `rai_feature_importance`
* `rai_segment_parity`
* `rai_prediction_drift`

ML operations tables:

* `ml_model_registry`
* `ml_training_runs`
* `ml_scoring_runs`

Observability tables:

* `pipeline_run_log`
* `data_quality_results`
* `table_freshness_status`
* `model_monitoring_status`

## Example semantic model content

**Topic: Executive Performance**

* Sources: `kpi_daily`
* Measures:
 	* `gross_revenue`
 	* `net_revenue`
 	* `orders`
 	* `avg_order_value`
* Dimensions:
 	* `date`
 	* `country`
 	* `device_category`
 	* `traffic_source`

**Topic: Funnel Performance**

* Sources: `funnel_daily`
* Measures:
 	* `sessions`
 	* `product_views`
 	* `add_to_cart`
 	* `purchases`
 	* `conversion_rate`
* Dimensions:
 	* `date`
 	* `campaign`
 	* `device_category`
 	* `traffic_source`

**Topic: Predictive LTV**

* Sources: `ltv_features`, `ltv_predictions`, `ltv_prediction_history`
* Measures:
 	* `predicted_ltv`
 	* `avg_predicted_ltv`
 	* `high_ltv_customer_count`
* Dimensions:
 	* `prediction_date`
 	* `customer_segment`
 	* `country`
 	* `device_category`
 	* `model_version`

**Topic: Responsible AI**

* Sources: `rai_model_eval`, `rai_feature_importance`, `rai_segment_parity`, `rai_prediction_drift`
* Measures:
 	* `rmse`
 	* `mae`
 	* `parity_gap`
 	* `drift_score`
* Dimensions:
 	* `evaluation_date`
 	* `segment_name`
 	* `feature_name`
 	* `model_version`

## Why this version

It still follows the Razor principle because each part has one clear job:

* **GA4** = source
* **BigQuery** = storage + compute
* **Bruin** = orchestration + transforms + checks
* **BigQuery ML** = train / score / evaluate
* **Serving layer** = trusted physical tables
* **Semantic model** = trusted business definitions
* **Semantic docs** = shared meaning and correct usage
* **Lineage** = traceability
* **Observability** = operational visibility
* **Deployment** = reproducible execution
* **BI** = consumption

## Dataset (DE PROJECT)

See [[bigquery-public-data.ga4_obfuscated_sample_ecommerce Dataset]].

## [[Bruin Pipeline (DE PROJECT)]]

## Semantic Model

See [[Semantic Model vs. DAX Measure]].
