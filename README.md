# DE-PROJECT — GA4 Ecommerce Analytics Pipeline

**Why:** Transform raw GA4 ecommerce events into trusted analytics, ML predictions, and BI-ready serving tables — with a semantic layer enforcing consistent metrics across all dashboards.

**What:** An end-to-end data pipeline that reads GA4 events from BigQuery, runs them through Bruin (ELT), trains a customer LTV model in BigQuery ML, evaluates it with Responsible AI monitoring, and exposes everything through a Cube semantic layer for Looker Studio dashboards.

---

## System Flow

```mermaid
flowchart LR
    A["GA4 Sample Dataset<br/>BigQuery Public Data"]
    B["Bruin Pipeline<br/>staging → intermediate → marts"]
    C["BigQuery ML + RAI<br/>features, scoring, monitoring"]
    D["Serving Tables<br/>analytics + ML ops + observability"]
    E["Cube Semantic Layer<br/>cubes + views"]
    F["BI Consumption<br/>Looker Studio"]

    A --> B --> C --> D --> E --> F
```

```mermaid
flowchart LR
    S["Source<br/>GA4 events_*"]
    STG["Staging<br/>stg_events_flat"]
    INT["Intermediate<br/>int_sessions<br/>int_customers"]
    MART["Marts<br/>kpi_daily<br/>funnel_daily<br/>rfm_segments"]
    ML["ML Layer<br/>ltv_features<br/>ltv_predictions<br/>ml_*"]
    RAI["RAI + Observability<br/>rai_*<br/>model_monitoring_status"]

    S --> STG --> INT --> MART --> ML --> RAI
```

```mermaid
flowchart LR
    G["Developer / CI"]
    H["GitHub Actions<br/>validate + scheduled run"]
    I["Bruin Environments<br/>dev: de_pipeline_dev<br/>prod: de_pipeline"]
    J["Cube Cloud"]
    K["Looker Studio"]

    G --> H --> I
    I --> J --> K
```

---

## Quick Navigation

### Source of Truth

| Layer | Location |
|-------|----------|
| Real truth | `assets/` — Bruin SQL assets |
| Feature contracts | `docs/features/*.yaml` |
| Feature history | `docs/features/<feature_id>/history.md` |
| Cross-cutting docs | `docs/*.md` |
| Implementation plans | `plans/` |
| This overview | `README.md` |

### Active Features

| Feature | Status | Description |
|---------|--------|-------------|
| [data-pipeline](docs/features/data-pipeline.yaml) | active | GA4 → BigQuery ELT pipeline |
| [analytics-serving-layer](docs/features/analytics-serving-layer.yaml) | active | BigQuery serving tables |
| [cube-semantic-layer](docs/features/cube-semantic-layer.yaml) | active | Cube semantic model |
| [lineage-and-observability](docs/features/lineage-and-observability.yaml) | active | Lineage docs + monitoring tables |
| [deployment-cicd](docs/features/deployment-cicd.yaml) | building | GitHub Actions CI/CD + scheduled runs; GitHub secret is managed outside the repo |

### Key Docs

- [High-level Pipeline](docs/DE%20PROJECT%20-%20High-level%20Pipeline.md) — full architecture overview
- [Lineage](docs/lineage.md) — 4 Mermaid diagrams: data, ML, semantic, observability
- [Dataset](docs/bigquery-public-data.ga4_obfuscated_sample_ecommerce%20Dataset.md) — source data notes

### Getting Started

```bash
# Install Bruin (Windows)
run_bruin.bat --version

# Validate all assets
bruin validate .

# Run full pipeline (requires GCP credentials)
bruin run --environment prod .
```

See `plans/deployment-layer-plan.md` for full local developer setup and CI/CD configuration.

---

## Tech Stack

```
GA4 (BigQuery Public) → Bruin (ELT) → BigQuery ML (LTV model)
                                       → BigQuery (serving tables)
                                       → Cube (semantic layer, Cube Cloud)
                                       → Looker Studio (BI dashboards)
```

**Storage + compute:** BigQuery
**Pipeline framework:** Bruin
**ML:** BigQuery ML (BOOSTED_TREE_REGRESSOR)
**Semantic layer:** Cube (open-source, deployed to Cube Cloud)
**BI:** Looker Studio (PostgreSQL via Cube Cloud SQL API)
**CI/CD:** GitHub Actions
