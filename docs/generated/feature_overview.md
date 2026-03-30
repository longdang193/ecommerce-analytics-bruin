# Feature Overview

> Generated — do not edit manually. Source: `docs/features/*.yaml`

## Active

| Feature | Version | Type | Owner | Summary |
|---|---|---|---|---|
| `analytics-serving-layer` | 1.0 | add |  | Curated physical BigQuery tables produced by the Bruin pipeline. Serves as the trusted single source of truth for all downstream consumers (Cube semantic layer, BI tools).
 |
| `cube-semantic-layer` | 1.0 | add |  | Open-source semantic layer (Cube, cube.dev) deployed on Cube Cloud. Defines cubes (physical table mappings), views (business topic facades), and shared measures/dimensions once in YAML — replacing per-dashboard metric redefinition and enabling consistent BI reporting via Looker Studio.
 |
| `data-pipeline` | 1.0 | add |  | End-to-end ELT pipeline that reads GA4 ecommerce events from BigQuery public data, flattens nested fields, builds intermediate customer/session base tables, and materializes analytics marts (KPIs, funnels, RFM segments), ML feature tables, and Responsible AI evaluation tables — all orchestrated by Bruin.
 |
| `lineage-and-observability` | 1.0 | add |  | First-class lineage traceability (source → mart → model → prediction → BI) and operational monitoring tables covering pipeline runs, data quality, freshness, model training/scoring, and Responsible AI alerts.
 |

## Building

| Feature | Version | Type | Owner | Summary |
|---|---|---|---|---|
| `deployment-cicd` | 1.0 | add |  | GitHub Actions-based deployment layer for the Bruin pipeline and Cube semantic model. Provides environment separation (dev/prod datasets), CI validation on every push/PR, daily scheduled production runs, and Cube Cloud auto-deploy on git push.
 |

## Dependency Graph

```text
data-pipeline
├── analytics-serving-layer
│   ├── cube-semantic-layer
│   │   ├── deployment-cicd
│   │   └── lineage-and-observability
│   └── lineage-and-observability
├── deployment-cicd
└── lineage-and-observability
```

## Status Legend

- **planned** — concept exists; entry created with invariants and domains
- **building** — implementation underway
- **active** — post-execution review complete
- **deprecated** — replaced or removed

## Feature Contracts

Each feature has a contract at `docs/features/<feature_id>.yaml` and optional focused docs under `docs/features/<feature_id>/`:

```text
docs/features/<feature_id>.yaml
docs/features/<feature_id>/history.md
```

For the machine-friendly index, see `docs/generated/features_index.yaml`.
