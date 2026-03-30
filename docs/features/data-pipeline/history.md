# Data Pipeline — History

## Post-Execution Review

**Feature type:** ADD
**Status transitioned to active:** 2026-03-30

---

### Classification Accurate

Yes. The pipeline is a net-new capability — there was no prior ELT pipeline for this dataset.

---

### Invariants Valid

All invariants held throughout implementation:

- Source table bounded correctly: `_TABLE_SUFFIX BETWEEN '20201101' AND '20210131'` — confirmed via `stg_events_flat` row count (~3.5M rows)
- `<PROJECT>` placeholder used consistently across all 20 SQL assets
- Batch read confirmed appropriate — the public sample is a fixed historical export, not a live streaming source

---

### Lessons

1. **GA4 nested schema requires careful flattening.** `event_params` is a `REPEATED STRUCT` — each key must be extracted via subquery `UNNEST`. Several keys are absent from some rows, so `COALESCE` and `SAFE_DIVIDE` are required throughout to prevent null propagation errors.

2. **`purchase_sessions` was missing from `kpi_daily`.** The mart aggregates sessions per dimension combination but had no `purchase_sessions` column. This meant `session_conversion_rate` was not computable from `kpi_daily` alone. The fix is documented in the Cube semantic layer plan: use `funnel_daily` / `funnel_performance` view for conversion rate until the upstream mart is updated.

3. **`has_purchase_history` is a useful leading indicator.** Computing this as a boolean from `int_customers` (based on whether a customer has any purchase events) enables the BQML model to weight zero-purchase customers differently.

4. **Proxy label for LTV is acceptable for MVP.** Using `total_revenue_usd` over the same observed period as features makes the model a *customer value scorer*, not a true forward-looking LTV predictor. This is documented clearly in `ltv_features.sql` and the Cube `predictive_ltv` view. Production would add a forward-looking prediction window.

5. **`SAFE_DIVIDE` / `NULLIF` required everywhere ratios are computed.** Division by zero is possible (zero orders, zero sessions). Using `SAFE_DIVIDE(a, NULLIF(b, 0))` throughout prevents runtime errors without verbose `CASE WHEN` guards.

6. **`DATE('2021-01-31')` is hardcoded as the snapshot date.** All recency fields in `int_customers` and RFM scoring in `rfm_segments` are anchored to this date. This is correct for the bounded sample but would need to be parameterized in a production incremental pipeline.

---

### Rule Updates Needed

No rule updates needed. The doc-system-lifecycle and feature-lifecycle rules correctly covered the ADD classification and 5-layer doc system.

---

### Docs Updated

- `docs/features/data-pipeline.yaml` — created as feature contract
- `docs/features/analytics-serving-layer.yaml` — updated (serving tables are the pipeline output)
- `plans/de-pipeline-implementation-plan.md` — referenced as spec + plan

---

### Notes

The observability layer tables (`pipeline_run_log`, `data_quality_results`) are **placeholder SQL assets** — they produce synthetic rows but are not wired to real Bruin Cloud telemetry. This is acceptable for MVP and documented in the implementation plan. Production would replace these with a Python asset that calls the Bruin API or BigQuery procedures.
