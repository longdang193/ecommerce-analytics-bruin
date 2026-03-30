# Cube Semantic Layer — History

## Post-Execution Review

**Feature type:** ADD
**Status transitioned to active:** 2026-03-30

---

### Classification Accurate

Yes. Cube is a net-new semantic layer — no prior semantic model existed for this project.

---

### Key Decisions

1. **Cube over LookML / Power BI.** LookML requires a paid Looker instance. Power BI is Windows-only with a different ecosystem. Cube is free, open-source, runs locally via `npx`, connects natively to BigQuery, and has a YAML model format nearly identical to LookML in concept.

2. **Deployed to Cube Cloud (GCP us-central1, free tier).** The local Dev Playground at `localhost:4000` is for development only. Cube Cloud provides a stable PostgreSQL SQL API endpoint (`rose-fowl.sql.gcp-us-central1.cubecloudapp.dev:5432`) that Looker Studio can reach without tunneling.

3. **Looker Studio connects via PostgreSQL, not direct BigQuery.** This is intentional — it ensures all BI queries go through the semantic layer so measures are enforced consistently. The direct BigQuery connector is intentionally avoided.

4. **Single-cube views only.** The four RAI cubes (model_eval, feature_importance, segment_parity, prediction_drift) have incompatible grains and no defined joins. A single multi-cube view would produce a Cartesian join. They were split into four separate views.

5. **`purchase_sessions` missing from `kpi_daily`.** The `executive_kpis` view cannot show `session_conversion_rate` because `kpi_daily` lacks `purchase_sessions`. This is documented in the view YAML and in the upstream data-pipeline history.

---

### Known Limitations

- `predicted_ltv` in `ltv_predictions` is a **proxy score** (historical revenue fit), not a true forward-looking LTV prediction. This is documented in the Cube view description and enforced as a dimension (not a measure) to prevent misuse in aggregations.

- `drift_score` in `rai_prediction_drift` is a **placeholder (0.0)**. Each full prediction run appends rows with a shared `scoring_run_id` — drift would be computed by comparing `mean_prediction` across runs in production.

- `parity_alert` is a **business insight**, not a regulated ML fairness metric. The 20% threshold is a business rule. The view description includes a disclaimer.

---

### Docs Updated

- `docs/features/cube-semantic-layer.yaml` — created as feature contract
- `docs/DE PROJECT - High-level Pipeline.md` — updated to reference Cube deployment
- `plans/cube-semantic-layer-implementation-plan.md` — referenced as spec + plan
