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
Semantic model + semantic documentation
  - business topics
      - Executive Performance
      - Funnel Performance
      - Customer Segments
      - Predictive LTV
      - Responsible AI
  - shared measures
      - gross_revenue
      - net_revenue
      - orders
      - sessions
      - conversion_rate
      - avg_order_value
      - predicted_ltv
      - parity_gap
      - drift_score
  - shared dimensions
      - date
      - country
      - device_category
      - traffic_source
      - campaign
      - customer_segment
      - model_version
  - joins / relationships
  - KPI definitions
  - naming / synonyms / business-friendly fields
  - topic documentation
  - metric definitions
  - dimension definitions
  - table grain documentation
  - assumptions / caveats
  - dashboard-to-topic mapping
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
BI dashboards
  - Executive KPIs
  - Funnel
  - Customer Segments
  - Predictive LTV
  - Responsible AI

Deployment layer
  - local Docker-based development
  - environment configs (dev / prod)
  - CI validation for SQL / Python / pipeline definitions
  - scheduled job deployment
  - lightweight release process for pipeline + semantic model changes
```

## In one line

```text
GA4 → BigQuery → Bruin transforms + checks → BigQuery ML + RAI → serving tables → semantic model + docs → lineage + observability → BI, with lightweight deployment around the stack
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

**Semantic model + documentation**: This is the reusable business-definition layer on top of the serving tables. It defines:

* topics for each business area
* approved measures
* approved dimensions
* joins and relationships
* business-friendly naming
* documentation for grain, caveats, and usage

This prevents every dashboard or analyst from redefining metrics differently.

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
