# Pipeline Lineage

End-to-end data lineage for the ecommerce analytics pipeline.

> **Semantic layer deployed**: Cube Cloud · GCP us-central1 · `rose-fowl.sql.gcp-us-central1.cubecloudapp.dev:5432`  
> **Looker Studio**: connected ✓ via PostgreSQL connector — data source `rose-fowl`

---

## 1. Data Lineage — Source → Marts

```mermaid
flowchart TD
    A["☁️ BigQuery Public Data\nbigquery-public-data\n.ga4_obfuscated_sample_ecommerce"]

    A -->|"Bruin ingest\n(bq.sql)"| B["stg_events_flat\n≈3.5M rows\n1_staging"]

    B -->|"Bruin transform\n(bq.sql)"| C["int_sessions\n2_intermediate"]
    B -->|"Bruin transform\n(bq.sql)"| D["int_customers\n2_intermediate"]

    C -->|"Bruin mart\n(bq.sql)"| E["kpi_daily\n2,515 rows\n3_marts"]
    C -->|"Bruin mart\n(bq.sql)"| F["funnel_daily\n2,515 rows\n3_marts"]
    D -->|"Bruin mart\n(bq.sql)"| G["rfm_segments\n270k customers\n3_marts"]

    style A fill:#4285F4,color:#fff
    style B fill:#34A853,color:#fff
    style C fill:#34A853,color:#fff
    style D fill:#34A853,color:#fff
    style E fill:#FBBC05,color:#000
    style F fill:#FBBC05,color:#000
    style G fill:#FBBC05,color:#000
```

---

## 2. ML Lineage — Marts → Features → Model → Predictions → RAI

```mermaid
flowchart TD
    G["rfm_segments\n3_marts"]
    D["int_customers\n2_intermediate"]

    G -->|"feature engineering\n(bq.sql)"| H["ltv_features\n4_ml"]
    D -->|"feature engineering\n(bq.sql)"| H

    H -->|"BQML CREATE MODEL\n(bq.sql)"| I["LTV BQML Model\n(ltv_model v1)\nBigQuery ML"]

    I -->|"ML.PREDICT\n(bq.sql)"| J["ltv_predictions\n270k rows\n4_ml"]
    I -->|"ML.EVALUATE\n(bq.sql)"| K["rai_model_eval\nR², MAE, MSE\n5_rai"]
    I -->|"ML.FEATURE_IMPORTANCE\n(bq.sql)"| L["rai_feature_importance\n5_rai"]

    J -->|"distribution tracking\n(bq.sql)"| M["rai_prediction_drift\n5_rai"]
    J & G -->|"parity analysis\n(bq.sql)"| N["rai_segment_parity\n6 segments\n5_rai"]

    style G fill:#FBBC05,color:#000
    style D fill:#34A853,color:#fff
    style H fill:#FF6D00,color:#fff
    style I fill:#AA00FF,color:#fff
    style J fill:#FF6D00,color:#fff
    style K fill:#EA4335,color:#fff
    style L fill:#EA4335,color:#fff
    style M fill:#EA4335,color:#fff
    style N fill:#EA4335,color:#fff
```

---

## 3. Semantic Lineage — BigQuery Tables → Cube → BI

```mermaid
flowchart LR
    subgraph BQ["BigQuery de_pipeline"]
        T1["kpi_daily"]
        T2["funnel_daily"]
        T3["rfm_segments"]
        T4["ltv_predictions"]
        T5["rai_model_eval"]
        T6["rai_feature_importance"]
        T7["rai_segment_parity"]
        T8["rai_prediction_drift"]
        T9["ml_scoring_runs"]
    end

    subgraph Cubes["Cube — Cubes (physical)"]
        C1["kpi_daily"]
        C2["funnel_daily"]
        C3["rfm_segments"]
        C4["ltv_predictions"]
        C5["rai_model_eval"]
        C6["rai_feature_importance"]
        C7["rai_segment_parity"]
        C8["rai_prediction_drift"]
        C9["ml_scoring_runs"]
    end

    subgraph Views["Cube — Views (business)"]
        V1["executive_kpis"]
        V2["funnel_performance"]
        V3["customer_segments"]
        V4["predictive_ltv"]
        V5["model_eval"]
        V6["feature_importance"]
        V7["segment_monitoring"]
        V8["prediction_drift"]
        V9["scoring_freshness"]
    end

    subgraph BI["BI Layer"]
        B1["Dev Playground\nlocalhost:4000\n(local dev)"]
        B2["Looker Studio\nPostgreSQL connector\nrose-fowl:5432 ✓"]
    end

    T1 --> C1 --> V1
    T2 --> C2 --> V2
    T3 --> C3 --> V3
    T4 --> C4 --> V4
    T5 --> C5 --> V5
    T6 --> C6 --> V6
    T7 --> C7 --> V7
    T8 --> C8 --> V8
    T9 --> C9 --> V9

    V1 & V2 & V3 & V4 & V5 & V6 & V7 & V8 & V9 --> B1
    V1 & V2 & V3 & V4 & V5 & V6 & V7 & V8 & V9 --> B2
```

---

## 4. Observability Lineage — Pipeline → Monitoring Tables

```mermaid
flowchart TD
    BR["Bruin Pipeline Run"] -->|"run metadata"| PRL["pipeline_run_log"]
    BR -->|"row counts + DQ checks"| DQR["data_quality_results"]

    BQ["BigQuery INFORMATION_SCHEMA"] -->|"last_modified_time"| TFS["table_freshness_status"]

    ML["BQML ML.TRAINING_INFO"] -->|"loss / iteration"| MTR["ml_training_runs"]
    SCORE["LTV Scoring Run\n(ML.PREDICT)"] -->|"rows_scored, timing"| MSR["ml_scoring_runs"]

    MTR & MSR & RAI_D["rai_prediction_drift"] & RAI_E["rai_model_eval"] -->|"JOIN"| MMS["model_monitoring_status"]

    style PRL fill:#607D8B,color:#fff
    style DQR fill:#607D8B,color:#fff
    style TFS fill:#607D8B,color:#fff
    style MTR fill:#607D8B,color:#fff
    style MSR fill:#607D8B,color:#fff
    style MMS fill:#607D8B,color:#fff
```
