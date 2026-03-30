# Lineage + Observability — History

## Post-Execution Review

**Feature type:** ADD
**Status:** implemented in repo as of 2026-03-30

---

### Classification Accurate

Yes. Lineage and observability are net-new capabilities. The observability *tables* were partially built in Phase 6 of the data pipeline, but lineage was never documented and several gaps existed in the monitoring surface.

---

### Audit Gaps And Resolution

| Gap | Severity | Resolution |
|-----|----------|-----------|
| No `parity_alert` boolean on `rai_segment_parity` | Medium | Resolved: computed column added in SQL and exposed in Cube |
| `rai_segment_parity` cube missing in Cube model | High | Resolved: `cube-semantic/model/cubes/rai_segment_parity.yml` created |
| `ml_scoring_runs` not exposed in Cube | Low | Resolved: `cube-semantic/model/views/scoring_freshness.yml` created |
| `model_monitoring_status` lacks `last_scored_at` | Low | Resolved: SQL enriched from `ml_scoring_runs` |
| No lineage documentation | High | Resolved: `docs/lineage.md` created with 4 Mermaid diagrams |

---

### Invariants

- `parity_alert` fires when `ABS(parity_gap) / global_avg > 0.20`
- Champions segment consistently fires the alert (gap ~3.26 vs global ~1.27 → relative ~2.57)
- `drift_score` remains 0.0 placeholder; production would compare `mean_prediction` across `scoring_run_id` batches

---

### Docs Updated

- `docs/features/lineage-and-observability.yaml` — created as feature contract
- `docs/lineage.md` — created with 4 Mermaid diagrams covering data lineage, ML lineage, semantic lineage, and observability lineage
- `plans/lineage-observability-plan.md` — referenced as plan
