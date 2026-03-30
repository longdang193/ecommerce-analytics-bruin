# BigQuery Public Data - GA4 Obfuscated Sample Ecommerce Dataset

`bigquery-public-data.ga4_obfuscated_sample_ecommerce` is the public BigQuery dataset `bigquery-public-data.ga4_obfuscated_sample_ecommerce`, built from the Google Merchandise Store’s GA4 web ecommerce implementation.

It contains **three months** of obfuscated event export data, from **2020-11-01 to 2021-01-31**, and Google notes that it emulates a real-world GA4 export but includes placeholder values like `<Other>`, `NULL`, and empty strings, with somewhat limited internal consistency because of obfuscation. ([Google for Developers][1])

So the pipeline becomes this in concrete terms:

```text
GA4 web ecommerce demo dataset in BigQuery
(bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*)
   ↓
Bruin pipeline
  - read bounded source tables in batch mode
  - flatten / normalize GA4 event fields
  - build base business tables
  - run data quality checks
  - build KPI / funnel / RFM / LTV marts
  - train + score model in BigQuery ML
  - compute Responsible AI monitoring tables
   ↓
BigQuery serving layer
  - kpi_daily
  - funnel_daily
  - rfm_segments
  - ltv_features
  - ltv_predictions
  - rai_model_eval
  - rai_feature_importance
  - rai_segment_parity
  - rai_prediction_drift
   ↓
BI dashboards
  - Executive KPIs
  - Funnel
  - Customer Segments
  - Predictive LTV
  - Responsible AI
```

A few practical implications for the build:

## The raw source is already in BigQuery

You do not need to build the GA4 ingestion part yourself for the demo. You can start directly from the public `events_*` tables and focus on transformation, BI, ML, Responsible AI, and RAG. Google explicitly says the dataset is available through BigQuery Public Datasets and can be explored with the BigQuery UI. ([Google for Developers][1])

## The first Bruin asset should flatten GA4 export structure

The most important early step is a flattened staging table like `stg_events_flat` that extracts the fields you need from the GA4 event export schema, especially from repeated/nested structures like `event_params`. Google’s sample page points to the GA4 BigQuery event export schema as the next step for working with the dataset. ([Google for Developers][1])

## You should design around the dataset’s limitations

Because the data is obfuscated and not fully internally consistent, you should avoid overclaiming precision in:

* customer segmentation,
* attribution-style interpretations,
* Responsible AI conclusions.

It is still excellent for pipeline design, marts, feature engineering, and BI prototyping. ([Google for Developers][1])

## Cost and access are friendly for a project

Google says a Google Cloud project with BigQuery API enabled is required, and that BigQuery Sandbox or the free usage tier should be sufficient to explore the dataset and run sample queries. ([Google for Developers][1])

[1]: https://developers.google.com/analytics/bigquery/web-ecommerce-demo-dataset "BigQuery sample dataset for Google Analytics ecommerce web implementation  |  Google for Developers"
