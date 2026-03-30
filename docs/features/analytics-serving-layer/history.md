# Analytics Serving Layer — History

## Post-Execution Review

**Feature type:** ADD
**Status transitioned to active:** 2026-03-30

---

### Classification Accurate

Yes. The serving layer is a new capability. Tables existed only as SQL assets before this classification — they are now tracked as a managed feature with stable schemas and documented ownership.

---

### Invariants Valid

All invariants held:

- All tables are confirmed to exist in BigQuery after Phase 7 full pipeline run
- Schemas match the Bruin `@bruin` column declarations
- The `rai_segment_parity` parity_alert boolean was added in the lineage-and-observability feature

---

### Schema Notes

| Table | Key Columns | Notes |
|-------|-------------|-------|
| `kpi_daily` | event_date, sessions, orders, gross_revenue, avg_order_value | Missing `purchase_sessions` — conversion rate uses `funnel_daily` |
| `funnel_daily` | event_date, view_sessions, cart_sessions, checkout_sessions, purchase_sessions | Full funnel coverage |
| `rfm_segments` | user_pseudo_id, rfm_segment, customer_segment | Champions segment has ~3.26x parity gap vs global avg |
| `ltv_features` | 14 features + proxy ltv_label | All RFM scores + behavioral counters + derived ratios |
| `ltv_predictions` | user_pseudo_id, predicted_ltv_label, model_name, scoring_run_id | Proxy LTV score (historical revenue fit) |
| `rai_model_eval` | r2_score, mean_absolute_error, mean_squared_error | Per-run evaluation metrics |
| `rai_feature_importance` | feature, importance_gain | Primary ranking metric: importance_gain |
| `rai_segment_parity` | segment_name, parity_gap, parity_alert | Alert fires at >20% relative gap |
| `rai_prediction_drift` | scoring_run_id, mean_prediction, drift_score | drift_score is a placeholder (0.0) |

---

### Docs Updated

- `docs/features/analytics-serving-layer.yaml` — created as feature contract
- `docs/DE PROJECT - High-level Pipeline.md` — updated to reference serving layer
