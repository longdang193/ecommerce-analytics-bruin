# Semantic Layer — Cube Implementation Plan

Cube (cube.dev) is an open-source semantic layer that sits between BigQuery serving tables and BI consumers. It defines shared measures, dimensions, and joins once in YAML — dashboards read from Cube, not raw tables. This replaces the risk of repeated per-dashboard metric redefinition.

> [!NOTE]
> **Tool choice context:** Cube was chosen over Looker/LookML (requires paid instance) and Power BI (Windows-only, different ecosystem). Cube is free, open-source, runs locally via `npx`, and connects natively to BigQuery. Its YAML model format is nearly identical in concept to LookML.

## Architecture

```
BigQuery serving layer (de_pipeline)
    ↓
Cube semantic layer (local, port 4000)
  - Cubes = physical table definitions
  - Views = business topic definitions
  - Measures = approved metric formulas
  - Dimensions = approved grouping fields
    ↓
Dev Playground (localhost:4000) — query + verify
    ↓
Looker Studio / future BI tools (connect via Cube SQL API)
```

## Prerequisites

- [ ] Node.js 16+ installed (`node --version`)
- [ ] Service account file available: `ecommerce-analytics-bruin-16913ecd84b7.json`
- [ ] BigQuery project: `ecommerce-analytics-bruin`, dataset: `de_pipeline`
- [ ] All 20 serving tables materialized (verified in Phase 7)

---

## Task 1: Initialize Cube Project

### Step 1: Create Cube project

```bash
npx cubejs-cli create cube-semantic -d bigquery
cd cube-semantic
```

### Step 2: Configure `.env`

Create `.env` in the `cube-semantic/` directory:

```env
CUBEJS_DB_TYPE=bigquery
CUBEJS_DB_BQ_PROJECT_ID=ecommerce-analytics-bruin
CUBEJS_DB_BQ_KEY_FILE=../ecommerce-analytics-bruin-16913ecd84b7.json
CUBEJS_DB_BQ_LOCATION=US
CUBEJS_API_SECRET=local-dev-secret
CUBEJS_DEV_MODE=true

# SQL API — required for any BI tool connecting via PostgreSQL wire protocol
CUBEJS_PG_SQL_PORT=15432
CUBEJS_SQL_USER=cube
CUBEJS_SQL_PASSWORD=local-dev-password
```

> [!NOTE]  
> `CUBEJS_DB_BQ_LOCATION` should match where your BigQuery dataset is located. Check the GCP console if unsure — use `EU` or `US`.

### Step 3: Start the dev server

```bash
npm run dev
```

Expected: Dev Playground opens at **<http://localhost:4000>**

- [x] Cube project initialized (`cubejs-cli@1.6.25`, 776 packages)
- [x] `.env` configured with BigQuery credentials + SQL API vars
- [x] Dev server starts without errors
- [x] Dev Playground accessible at localhost:4000 ✓ confirmed

---

## Task 2: Data Model — Cube Definitions (Physical Tables)

Create YAML files in `cube-semantic/model/cubes/`. Each file = one BigQuery serving table.

### `kpi_daily.yml`

```yaml
cubes:
  - name: kpi_daily
    sql_table: ecommerce-analytics-bruin.de_pipeline.kpi_daily
    description: >
      Daily KPI aggregates per event_date, traffic_source, device_category, country.
      One row per (date, source, device, country) combination.

    dimensions:
      - name: event_date
        sql: event_date
        type: time
        primary_key: false

      - name: traffic_source
        sql: traffic_source
        type: string

      - name: device_category
        sql: device_category
        type: string

      - name: country
        sql: country
        type: string

    measures:
      - name: gross_revenue
        sql: gross_revenue
        type: sum
        description: Total revenue including taxes/shipping

      - name: orders
        sql: orders
        type: sum

      - name: unique_users
        sql: unique_users
        type: sum

      - name: sessions
        sql: sessions
        type: sum

      - name: avg_order_value
        sql: "SUM({gross_revenue}) / NULLIF(SUM({orders}), 0)"
        type: number
        format: currency
        description: >
          Revenue per order. Computed as SUM/SUM, not AVG of pre-computed daily values.
          Averaging pre-computed ratios produces incorrect weighted results.
```

> [!WARNING]
> `purchase_sessions` does not exist in `kpi_daily` (confirmed via BigQuery schema). It has been
> removed from this cube. `session_conversion_rate` is therefore not computable here via SUM/SUM.
> **Upstream fix required:** add `purchase_sessions` to the `kpi_daily` mart in BigQuery.
> Until then, use `funnel_daily` / `funnel_performance` view for conversion rate metrics.

### `funnel_daily.yml`

```yaml
cubes:
  - name: funnel_daily
    sql_table: ecommerce-analytics-bruin.de_pipeline.funnel_daily
    description: >
      Daily funnel stage counts per event_date, traffic_source, device_category, campaign.
      One row per (date, source, device, campaign) combination.

    dimensions:
      - name: event_date
        sql: event_date
        type: time

      - name: traffic_source
        sql: traffic_source
        type: string

      - name: device_category
        sql: device_category
        type: string

      - name: campaign
        sql: campaign
        type: string

    measures:
      - name: sessions
        sql: sessions
        type: sum

      - name: view_sessions
        sql: view_sessions
        type: sum

      - name: cart_sessions
        sql: cart_sessions
        type: sum

      - name: checkout_sessions
        sql: checkout_sessions
        type: sum

      - name: purchase_sessions
        sql: purchase_sessions
        type: sum

      - name: cart_rate
        sql: "SUM({cart_sessions}) / NULLIF(SUM({view_sessions}), 0)"
        type: number
        format: percent
        description: Share of view sessions that added to cart.

      - name: checkout_rate
        sql: "SUM({checkout_sessions}) / NULLIF(SUM({cart_sessions}), 0)"
        type: number
        format: percent

      - name: purchase_rate
        sql: "SUM({purchase_sessions}) / NULLIF(SUM({checkout_sessions}), 0)"
        type: number
        format: percent

      - name: session_conversion_rate
        sql: "SUM({purchase_sessions}) / NULLIF(SUM({sessions}), 0)"
        type: number
        format: percent
```

### `rfm_segments.yml`

```yaml
cubes:
  - name: rfm_segments
    sql_table: ecommerce-analytics-bruin.de_pipeline.rfm_segments
    description: >
      One row per customer (user_pseudo_id). RFM scores, segment label,
      lifetime activity metrics. Grain: customer.

    dimensions:
      - name: user_pseudo_id
        sql: user_pseudo_id
        type: string
        primary_key: true

      - name: customer_segment
        sql: customer_segment
        type: string

      - name: r_score
        sql: r_score
        type: number

      - name: f_score
        sql: f_score
        type: number

      - name: m_score
        sql: m_score
        type: number

    measures:
      - name: customer_count
        sql: user_pseudo_id
        type: count_distinct
        description: Number of unique customers.

      - name: avg_monetary
        sql: monetary
        type: avg
        description: Average historical revenue per customer within a segment.

      - name: avg_recency_days
        sql: recency_days
        type: avg

      - name: avg_frequency
        sql: frequency
        type: avg
```

### `ltv_predictions.yml`

```yaml
cubes:
  - name: ltv_predictions
    sql_table: ecommerce-analytics-bruin.de_pipeline.ltv_predictions
    description: >
      One row per scored customer. predicted_ltv is a proxy score (historical revenue fit),
      NOT a true future revenue forecast. Use for relative customer ranking only.

    dimensions:
      - name: user_pseudo_id
        sql: user_pseudo_id
        type: string
        primary_key: true

      - name: r_score
        sql: r_score
        type: number

      - name: f_score
        sql: f_score
        type: number

      - name: m_score
        sql: m_score
        type: number

      - name: predicted_ltv
        sql: predicted_ltv
        type: number
        description: >
          Raw LTV proxy score per customer. Expose as a dimension to enable individual
          customer ranking and histogram bucketing in BI tools.

      - name: scored_at
        sql: scored_at
        type: time

      - name: model_name
        sql: model_name
        type: string

      - name: scoring_run_id
        sql: scoring_run_id
        type: string

    measures:
      - name: avg_predicted_ltv
        sql: predicted_ltv
        type: avg

      - name: max_predicted_ltv
        sql: predicted_ltv
        type: max

      - name: customer_count
        sql: user_pseudo_id
        type: count_distinct
```

### `rai_model_eval.yml`

```yaml
cubes:
  - name: rai_model_eval
    sql_table: ecommerce-analytics-bruin.de_pipeline.rai_model_eval
    description: >
      Model evaluation metrics (R², MAE, MSE) per evaluation run.
      One row per (model_name, model_version, evaluated_at).

    dimensions:
      - name: model_name
        sql: model_name
        type: string

      - name: model_version
        sql: model_version
        type: string

      - name: evaluated_at
        sql: evaluated_at
        type: time

    measures:
      - name: r2_score
        sql: r2_score
        type: max

      - name: mean_absolute_error
        sql: mean_absolute_error
        type: max

      - name: mean_squared_error
        sql: mean_squared_error
        type: max
```

### `rai_feature_importance.yml`

```yaml
cubes:
  - name: rai_feature_importance
    sql_table: ecommerce-analytics-bruin.de_pipeline.rai_feature_importance
    description: >
      Feature importance from ML.FEATURE_IMPORTANCE().
      Columns: feature, importance_weight, importance_gain, importance_cover.
      Use importance_gain as primary metric (improvement in loss per split).

    dimensions:
      - name: feature
        sql: feature
        type: string

      - name: model_version
        sql: model_version
        type: string

      - name: evaluated_at
        sql: evaluated_at
        type: time

    measures:
      - name: importance_gain
        sql: importance_gain
        type: sum
        description: Improvement in loss function per feature split. Primary importance metric.

      - name: importance_weight
        sql: importance_weight
        type: sum

      - name: importance_cover
        sql: importance_cover
        type: sum
```

### `rai_segment_parity.yml`

```yaml
cubes:
  - name: rai_segment_parity
    sql_table: ecommerce-analytics-bruin.de_pipeline.rai_segment_parity
    description: >
      Pre-aggregated: one row per customer segment. Shows avg, median, stddev of
      predicted_ltv and parity_gap (deviation from global average).
      Use for model monitoring — not business segmentation.

    dimensions:
      - name: segment_name
        sql: segment_name
        type: string

      - name: model_version
        sql: model_version
        type: string

    measures:
      - name: avg_predicted_ltv
        sql: avg_predicted_ltv
        type: max

      - name: parity_gap
        sql: parity_gap
        type: max
        description: >
          Deviation of segment avg_predicted_ltv from global average.
          Positive = over-predicted vs baseline; negative = under-predicted.

      - name: segment_size
        sql: segment_size
        type: max
```

### `rai_prediction_drift.yml`

```yaml
cubes:
  - name: rai_prediction_drift
    sql_table: ecommerce-analytics-bruin.de_pipeline.rai_prediction_drift
    description: >
      One row per scoring run. Tracks distribution of predicted_ltv across runs.
      Use to detect if model output distribution shifts over time.

    dimensions:
      - name: scoring_run_id
        sql: scoring_run_id
        type: string

      - name: model_name
        sql: model_name
        type: string

      - name: evaluation_date
        sql: evaluation_date
        type: time

    measures:
      - name: mean_prediction
        sql: mean_prediction
        type: max

      - name: stddev_prediction
        sql: stddev_prediction
        type: max

      - name: total_predictions
        sql: total_predictions
        type: max
```

- [x] All 7 cube YAML files created
- [x] Dev Playground shows all cubes loaded (no schema errors) ✓ confirmed

---

## Task 3: Views — Business Topic Definitions

Create YAML files in `cube-semantic/model/views/`. Each file = one business topic. Views expose a curated subset of measures + dimensions from one or more cubes.

### `executive_kpis.yml`

```yaml
views:
  - name: executive_kpis
    description: >
      Top-line business performance: revenue, orders, users, conversion.
      Source: kpi_daily. Consumers: Executive KPIs dashboard.
    cubes:
      - join_path: kpi_daily
        includes:
          - event_date
          - traffic_source
          - device_category
          - country
          - gross_revenue
          - orders
          - unique_users
          - sessions
          - avg_order_value
```

> [!NOTE]
> `purchase_sessions` and `session_conversion_rate` removed from `executive_kpis` until
> `purchase_sessions` is added to the `kpi_daily` upstream mart. Use `funnel_performance`
> view for conversion rate in the interim.

### `funnel_performance.yml`

```yaml
views:
  - name: funnel_performance
    description: >
      Stage-by-stage funnel progression and drop-off rates.
      Source: funnel_daily. Consumers: Funnel dashboard.
    cubes:
      - join_path: funnel_daily
        includes:
          - event_date
          - traffic_source
          - device_category
          - campaign
          - sessions
          - view_sessions
          - cart_sessions
          - checkout_sessions
          - purchase_sessions
          - cart_rate
          - checkout_rate
          - purchase_rate
          - session_conversion_rate
```

### `customer_segments.yml`

```yaml
views:
  - name: customer_segments
    description: >
      Business segmentation view — who are our customers by RFM?
      Source: rfm_segments. Consumers: Customer Segments dashboard.
      Note: `country` removed — not present in rfm_segments table (verified via BigQuery schema).
    cubes:
      - join_path: rfm_segments
        includes:
          - user_pseudo_id
          - customer_segment
          - r_score
          - f_score
          - m_score
          - customer_count
          - avg_monetary
          - avg_recency_days
          - avg_frequency
```

### `predictive_ltv.yml`

```yaml
views:
  - name: predictive_ltv
    description: >
      Business use of customer value scores — who is high-value?
      Source: ltv_predictions. Consumers: Predictive LTV dashboard.
      IMPORTANT: predicted_ltv is a proxy score (historical revenue fit),
      not a future revenue forecast. Use for relative ranking only.
    cubes:
      - join_path: ltv_predictions
        includes:
          - user_pseudo_id
          - predicted_ltv
          - r_score
          - f_score
          - m_score
          - scored_at
          - model_name
          - scoring_run_id
          - avg_predicted_ltv
          - max_predicted_ltv
          - customer_count
```

> [!IMPORTANT]
> `model_monitoring.yml` has been **split into 4 separate views**.
> Reason: Cube views reference cubes via join paths. The four RAI cubes have no defined joins
> and incompatible grains (per-run, per-feature, per-segment, per-scoring-run). A single
> multi-cube view would produce a Cartesian join or fail at query time.

### `model_eval.yml`

```yaml
views:
  - name: model_eval
    description: >
      Model evaluation metrics per run: R², MAE, MSE.
      Source: rai_model_eval. Consumers: Model Monitoring dashboard.
    cubes:
      - join_path: rai_model_eval
        includes:
          - model_name
          - model_version
          - evaluated_at
          - r2_score
          - mean_absolute_error
          - mean_squared_error
```

### `feature_importance.yml`

```yaml
views:
  - name: feature_importance
    description: >
      Feature importance from the ML model. Use importance_gain as primary ranking metric.
      Source: rai_feature_importance. Consumers: Model Monitoring dashboard.
    cubes:
      - join_path: rai_feature_importance
        includes:
          - feature
          - model_version
          - evaluated_at
          - importance_gain
          - importance_weight
          - importance_cover
```

### `segment_monitoring.yml`

```yaml
views:
  - name: segment_monitoring
    description: >
      Segment-level prediction parity — tracks whether the model scores customer segments
      proportionally relative to the global average. Source: rai_segment_parity.
      DISCLAIMER: Not a regulated Responsible AI framework.
    cubes:
      - join_path: rai_segment_parity
        includes:
          - segment_name
          - model_version
          - avg_predicted_ltv
          - parity_gap
          - segment_size
```

### `prediction_drift.yml`

```yaml
views:
  - name: prediction_drift
    description: >
      Distribution of predicted_ltv values per scoring run. Use to detect if model
      output distribution shifts over time. Source: rai_prediction_drift.
    cubes:
      - join_path: rai_prediction_drift
        includes:
          - scoring_run_id
          - model_name
          - evaluation_date
          - mean_prediction
          - stddev_prediction
          - total_predictions
```

- [x] All 8 view YAML files created (4 business + 4 RAI monitoring)

- [x] Dev Playground shows all views with correct measures/dimensions ✓ confirmed (no compile errors)

---

## Task 4: Verification

### Step 1: Validate cubes load in Dev Playground

- Open <http://localhost:4000>
- In the "Build" tab, select view `executive_kpis`
- Add measures: `gross_revenue`, `avg_order_value`, `session_conversion_rate`
- Add dimension: `event_date` (by month)
- Run query → verify numbers match BigQuery MCP spot-check

### Step 2: Verify calculated measures are correct

Run these spot-check values against the Cube Dev Playground and compare to BigQuery:

| Measure | Expected (from Phase 7 BigQuery check) |
|---|---|
| `executive_kpis.gross_revenue` (total) | Match `SUM(gross_revenue)` from `kpi_daily` |
| `executive_kpis.avg_order_value` | Match `SUM(gross_revenue) / SUM(orders)` |
| `funnel_performance.cart_rate` | Match `SUM(cart_sessions) / SUM(view_sessions)` |

### Step 3: Verify RAI monitoring views

- Select view `feature_importance` → query `feature`, `importance_gain`, sort descending — top feature visible
- Select view `model_eval` → query `r2_score`, `mean_absolute_error` per `model_version`
- Select view `segment_monitoring` → query `segment_name`, `parity_gap`
- Select view `prediction_drift` → query `mean_prediction`, `stddev_prediction` over time

### Step 4: Commit

```bash
git add cube-semantic/
git commit -m "feat: add Cube semantic layer — 7 cubes, 8 views (4 business + 4 RAI monitoring)"
```

- [x] Dev Playground queries produce correct results ✓ gross_revenue by month verified
- [x] Spot-check values match BigQuery ✓ total 362,165 matches in both
- [ ] Committed to repo

---

## File Structure

```
cube-semantic/
├── .env                          ← BigQuery credentials (git-ignored)
├── package.json
├── cube.js                       ← Cube config (generated by CLI)
└── model/
    ├── cubes/
    │   ├── kpi_daily.yml
    │   ├── funnel_daily.yml
    │   ├── rfm_segments.yml
    │   ├── ltv_predictions.yml
    │   ├── rai_model_eval.yml
    │   ├── rai_feature_importance.yml
    │   ├── rai_segment_parity.yml
    │   └── rai_prediction_drift.yml
    └── views/
        ├── executive_kpis.yml
        ├── funnel_performance.yml
        ├── customer_segments.yml
        ├── predictive_ltv.yml
        ├── model_eval.yml             ← replaces model_monitoring.yml
        ├── feature_importance.yml
        ├── segment_monitoring.yml
        └── prediction_drift.yml
```

> [!IMPORTANT]
> Add `.env` to `.gitignore` — it contains the path to the service account key file. The key file itself (`ecommerce-analytics-bruin-16913ecd84b7.json`) should also be in `.gitignore` and not committed to the repo.

## Connecting Looker Studio to Cube

> [!IMPORTANT]
> **For portfolio/demo use the Cube Dev Playground** at `http://localhost:4000` — it demonstrates
> the semantic layer directly without any networking challenge. Looker Studio is cloud-hosted and
> **cannot reach `localhost`** in a standard setup.

### If you want the PostgreSQL SQL API connection

Cube Core's SQL API is **disabled by default**. Enable it by adding to `.env`:

```env
CUBEJS_PG_SQL_PORT=15432
CUBEJS_SQL_USER=cube
CUBEJS_SQL_PASSWORD=local-dev-password
```

Then connect from any PostgreSQL-compatible client:

- Host: `localhost`
- Port: `15432` (value of `CUBEJS_PG_SQL_PORT`)
- Driver: PostgreSQL
- User/Password: as set above

For Looker Studio to reach this endpoint you need either:

- **ngrok**: `ngrok tcp 15432` → use the tunnel host/port in Looker Studio
- **Cube Cloud**: deploy the project and use the cloud endpoint
- **Direct BigQuery**: for public dashboards, connecting Looker Studio directly to BigQuery
  remains the simpler option; Cube adds value at the semantic layer / Dev Playground level.
