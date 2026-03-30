# Lineage + Observability — Remaining Implementation Plan

## Context: What Already Exists

After auditing the 20 BigQuery tables and 4 observability SQL assets, most of the observability
infrastructure is already in place. The actual remaining work is smaller than it looks:

| Pipeline Step Item | Status |
|---|---|
| Pipeline run status | ✅ `pipeline_run_log` table (placeholder SQL, synthetic row) |
| Data freshness / latency | ✅ `table_freshness_status` (queries INFORMATION_SCHEMA) |
| Row-count / volume monitoring | ✅ `data_quality_results` table |
| Data quality check results | ✅ `data_quality_results` table |
| Model training status | ✅ `ml_training_runs` table (populated from BQML) |
| Model scoring freshness | ✅ `ml_scoring_runs` table (has `scoring_ended_at`) — **but not exposed in Cube** |
| Prediction drift monitoring | ✅ `rai_prediction_drift` + Cube `prediction_drift` view |
| Parity / fairness threshold alerts | ⚠️ `rai_segment_parity` exists but **no `parity_alert` boolean flag** |
| Dashboard source freshness status | ⚠️ `model_monitoring_status` exists but **no scoring freshness field** |
| Source-to-table lineage | ❌ Not documented |
| Table-to-mart lineage | ❌ Not documented |
| Mart-to-metric lineage | ❌ Not documented |
| Metric-to-dashboard lineage | ❌ Not documented |
| Source-to-model-feature lineage | ❌ Not documented |
| Source-to-prediction lineage | ❌ Not documented |

---

## Proposed Changes

### Task A: Lineage Documentation

**Goal:** Document all 6 lineage hops as a single Mermaid diagram in `docs/lineage.md`.

No new BQ tables or Bruin assets needed — lineage is already implicit in Bruin `depends_on`
declarations and the Cube model structure.

---

#### [NEW] `docs/lineage.md`

A Mermaid `flowchart TD` diagram tracing:

```
ga4_obfuscated_sample_ecommerce (BigQuery Public)
  → stg_events_flat            [Bruin asset: 1_staging]
  → int_sessions, int_customers [Bruin: 2_intermediate]
  → kpi_daily, funnel_daily    [Bruin: 3_marts]
  → rfm_segments               [Bruin: 3_marts]
  → ltv_features               [Bruin: 4_ml]
  → LTV BQML Model             [BigQuery ML]
  → ltv_predictions            [Bruin: 4_ml]
  → rai_model_eval, rai_feature_importance,
    rai_segment_parity, rai_prediction_drift [Bruin: 5_rai]
  → Cube executive_kpis, funnel_performance,
    customer_segments, predictive_ltv,
    model_eval, feature_importance,
    segment_monitoring, prediction_drift  [Cube views]
  → Dev Playground / Looker Studio        [BI]
```

Split into 3 sub-diagrams:
1. **Data lineage** (source → staging → intermediate → marts)
2. **ML lineage** (marts → features → model → predictions → RAI)
3. **Semantic lineage** (BigQuery tables → Cube cubes → Cube views → BI)

---

### Task B: Parity Alert Flag

**Goal:** Add a `parity_alert` boolean to `rai_segment_parity` to flag segments where
`|parity_gap| / global_avg > 0.20` (20% relative gap threshold). Expose it in the
existing `segment_monitoring` Cube view.

Current data shows gaps ranging from 0.056 (Loyal) to 3.26 (Champions) — the Champions
segment would fire an alert.

---

#### [MODIFY] [assets/5_rai/rai_segment_parity.sql](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/assets/5_rai/rai_segment_parity.sql)

Add a computed column:
```sql
ROUND(ABS(parity_gap) / NULLIF(global_avg, 0), 4) AS relative_gap,
ABS(parity_gap) / NULLIF(global_avg, 0) > 0.20    AS parity_alert
```

---

#### [MODIFY] [cube-semantic/model/cubes/rai_segment_parity.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/model/cubes/rai_segment_parity.yml) *(currently missing — needs to be created)*

> [!IMPORTANT]
> `rai_segment_parity` has **no cube file** yet. The `segment_monitoring` view references it
> but there is no backing cube. This was a gap in Task 2. The cube must be created as part of this task.

New cube file needed:
- dimensions: `segment_name`, `model_name`, `model_version`, `parity_alert` (type: boolean), `evaluated_at`
- measures: `avg_parity_gap`, `alert_count` (count_distinct where parity_alert = true)

---

#### [MODIFY] [cube-semantic/model/views/segment_monitoring.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/model/views/segment_monitoring.yml)

Add `parity_alert` boolean dimension and `alert_count` measure from the new cube.

---

### Task C: Scoring Freshness in Cube

**Goal:** Expose `ml_scoring_runs.scoring_ended_at` as a Cube view so the Dev Playground 
can show "model last scored X hours ago."

`ml_scoring_runs` already has `scoring_ended_at TIMESTAMP` and `rows_scored INT` — it just
isn't exposed via Cube yet.

---

#### [NEW] `cube-semantic/model/cubes/ml_scoring_runs.yml`

New cube:
- time dimension: `scored_at` (from `scoring_ended_at`)
- measures: `rows_scored` (sum), `run_count` (count)

---

#### [MODIFY] [cube-semantic/model/views/predictive_ltv.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/model/views/predictive_ltv.yml)

Add a `last_scored_at` time dimension from `ml_scoring_runs` via `includes` (or as a separate
joined cube references are not available in Cube views — keep as a separate view).

**Alternative (simpler):** Create a standalone `scoring_freshness` view from `ml_scoring_runs`.

#### [NEW] `cube-semantic/model/views/scoring_freshness.yml`

Simple view:
- `model_name` dimension
- `last_scored_at` time dimension  
- `rows_scored` measure

---

### Task D: Enrich `model_monitoring_status`

**Goal:** Extend the `model_monitoring_status` SQL asset to include scoring freshness from
`ml_scoring_runs` (currently it only joins `rai_model_eval` and `rai_prediction_drift`).

---

#### [MODIFY] [assets/6_observability/model_monitoring_status.sql](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/assets/6_observability/model_monitoring_status.sql)

Add a join to `ml_scoring_runs`:
```sql
LEFT JOIN (
  SELECT model_name, MAX(scoring_ended_at) AS last_scored_at, SUM(rows_scored) AS total_rows_scored
  FROM `ecommerce-analytics-bruin.de_pipeline.ml_scoring_runs`
  GROUP BY model_name
) s USING (model_name)
```

Add `last_scored_at` and `total_rows_scored` to the SELECT.

---

## Summary of Files

| File | Action |
|------|--------|
| `docs/lineage.md` | [NEW] Full Mermaid lineage diagram |
| [assets/5_rai/rai_segment_parity.sql](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/assets/5_rai/rai_segment_parity.sql) | [MODIFY] Add `relative_gap`, `parity_alert` columns |
| [cube-semantic/model/cubes/rai_segment_parity.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/model/cubes/rai_segment_parity.yml) | [NEW] Missing cube (gap from Task 2) |
| `cube-semantic/model/cubes/ml_scoring_runs.yml` | [NEW] Expose scoring run metadata to Cube |
| [cube-semantic/model/views/segment_monitoring.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/model/views/segment_monitoring.yml) | [MODIFY] Add `parity_alert`, `alert_count` |
| `cube-semantic/model/views/scoring_freshness.yml` | [NEW] Standalone scoring freshness view |
| [assets/6_observability/model_monitoring_status.sql](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/assets/6_observability/model_monitoring_status.sql) | [MODIFY] Add scoring freshness join |

Total: **4 new files**, **3 modifications**.

---

## Verification Plan

### A — Lineage

**Manual:** Open `docs/lineage.md` in any Markdown renderer (VS Code Preview, Obsidian, GitHub).
Verify all 3 Mermaid diagrams render without syntax errors and trace the full path from
source to BI.

### B — Parity Alert

**BigQuery query:**
```sql
SELECT segment_name, parity_gap, relative_gap, parity_alert
FROM `ecommerce-analytics-bruin.de_pipeline.rai_segment_parity`
ORDER BY relative_gap DESC
```
Expected: Champions row has `parity_alert = TRUE` (gap ~3.26 / global_avg ~1.27 → relative ~2.57).

**Cube Playground:**
- Open `segment_monitoring` view → add `parity_alert` dimension + `alert_count` measure → Run Query
- Expected: at least 1 segment shows alert = true

### C — Scoring Freshness

**BigQuery query:**
```sql
SELECT model_name, MAX(scoring_ended_at) AS last_scored
FROM `ecommerce-analytics-bruin.de_pipeline.ml_scoring_runs`
GROUP BY model_name
```

**Cube Playground:** Open `scoring_freshness` view → add `last_scored_at` and `rows_scored` → Run Query.

### D — Model Monitoring Status

**BigQuery query:**
```sql
SELECT * FROM `ecommerce-analytics-bruin.de_pipeline.model_monitoring_status`
```
Expected: row now includes `last_scored_at` and `total_rows_scored` columns.
