# Deployment Layer — Implementation Plan

## What Already Exists

| Item | Status |
|---|---|
| [pipeline.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/pipeline.yml) | Minimal — name + schedule + 1 connection, no environments |
| [.gitignore](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/.gitignore) | Correctly excludes [.env](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/.env) and key files |
| [cube-semantic/docker-compose.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/docker-compose.yml) | Cube scaffold only — not used for Bruin |
| Cube Cloud auto-deploy | ✅ Active — pushes to `main` trigger rebuild |
| GitHub repo | `longdang193/ecommerce-analytics-bruin` |

## Scope

> [!IMPORTANT]
> Docker is skipped for Bruin — it runs as a CLI binary calling BigQuery over HTTPS.
> No local database to containerize. The existing [docker-compose.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/docker-compose.yml) stays for Cube local dev only.

---

## Proposed Changes

### Task 1: Environment Separation

**Goal:** Add `dev` environment to [pipeline.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/pipeline.yml) that targets `de_pipeline_dev` dataset
instead of `de_pipeline`. Prevents CI or developer mistakes from writing to the prod dataset.

---

#### [MODIFY] [pipeline.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/pipeline.yml)

```yaml
name: ecommerce-analytics-bruin
schedule: daily

default_connections:
  google_cloud_platform: "gcp"

environments:
  - name: dev
    connections:
      - name: google_cloud_platform
        type: google_cloud_platform
        project_id: ecommerce-analytics-bruin
        dataset_id: de_pipeline_dev
        service_account_key: $GCP_SERVICE_ACCOUNT_KEY
  - name: prod
    connections:
      - name: google_cloud_platform
        type: google_cloud_platform
        project_id: ecommerce-analytics-bruin
        dataset_id: de_pipeline
        service_account_key: $GCP_SERVICE_ACCOUNT_KEY
```

The `$GCP_SERVICE_ACCOUNT_KEY` env var is injected from GitHub Secrets in CI and
from a local `.env.local` (gitignored) for developers.

---

### Task 2: GitHub Secrets

**Goal:** Store the GCP service account JSON as a GitHub Secret so CI can authenticate
to BigQuery without committing credentials.

**Steps (manual, done once in GitHub UI):**

1. Go to: `https://github.com/longdang193/ecommerce-analytics-bruin/settings/secrets/actions`
2. Add secret: `GCP_SERVICE_ACCOUNT_KEY` → paste the full JSON content of
   `ecommerce-analytics-bruin-16913ecd84b7.json`

This is used by all 3 GitHub Actions workflows below.

---

### Task 3: CI Validation Workflow

**Goal:** Validate every pull request / push to `main`. Runs `bruin validate` (structure
check — free, no BQ connection needed) and a lightweight Cube YAML syntax check.

---

#### [NEW] `.github/workflows/ci.yml`

```yaml
name: CI — Validate Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  bruin-validate:
    name: Bruin Asset Validation
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Bruin
        run: curl -LsSf https://raw.githubusercontent.com/bruin-data/bruin/main/install.sh | sh

      - name: Validate pipeline definitions
        run: bruin validate .
        working-directory: .

  cube-validate:
    name: Cube YAML Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: cube-semantic/package-lock.json

      - name: Install Cube deps
        run: npm ci
        working-directory: cube-semantic

      - name: Validate Cube model (dry-run compile)
        env:
          CUBEJS_DB_TYPE: bigquery
          CUBEJS_DB_BQ_PROJECT_ID: ecommerce-analytics-bruin
          CUBEJS_DB_BQ_LOCATION: US
          CUBEJS_DB_BQ_CREDENTIALS: ${{ secrets.GCP_SERVICE_ACCOUNT_KEY }}
          CUBEJS_API_SECRET: ci-validation-secret
          CUBEJS_DEV_MODE: "false"
        run: npx cubejs-cli validate
        working-directory: cube-semantic
```

> [!NOTE]
> `bruin validate` is a **local structural check** — it validates asset YAML headers,
> dependency graph, and SQL syntax using a parser. It does NOT run queries or need BQ credentials.
>
> `cubejs-cli validate` compiles the Cube model (YAML → JS schema) and reports schema errors.
> It requires BQ credentials to resolve types but does not run actual queries.

---

### Task 4: Scheduled Pipeline Run Workflow

**Goal:** Run the full Bruin pipeline on a daily schedule automatically. Writes to `prod`
environment (the real `de_pipeline` dataset in BigQuery).

---

#### [NEW] `.github/workflows/scheduled-run.yml`

```yaml
name: Scheduled Pipeline Run

on:
  schedule:
    - cron: '0 6 * * *'   # Daily at 06:00 UTC
  workflow_dispatch:        # Allow manual trigger from GitHub UI

jobs:
  run-pipeline:
    name: Run Bruin Pipeline (prod)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Bruin
        run: curl -LsSf https://raw.githubusercontent.com/bruin-data/bruin/main/install.sh | sh

      - name: Write GCP credentials
        run: echo '${{ secrets.GCP_SERVICE_ACCOUNT_KEY }}' > /tmp/gcp-key.json

      - name: Run pipeline (prod environment)
        env:
          GOOGLE_APPLICATION_CREDENTIALS: /tmp/gcp-key.json
        run: bruin run --environment prod .

      - name: Cleanup credentials
        if: always()
        run: rm -f /tmp/gcp-key.json
```

> [!IMPORTANT]
> `workflow_dispatch` allows manual runs from the GitHub Actions UI — useful for
> re-running after data issues without writing code.

---

### Task 5: Local Developer Secret Setup

**Goal:** Document how a developer (or the user) runs the pipeline locally without
modifying the env-var-driven [pipeline.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/pipeline.yml).

---

#### [NEW] `.env.local.example`

```bash
# Copy this to .env.local (gitignored) and fill in your credentials
# .env.local is loaded by bruin automatically when running locally

GCP_SERVICE_ACCOUNT_KEY='{"type":"service_account","project_id":"ecommerce-analytics-bruin",...}'
```

#### [MODIFY] [.gitignore](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/.gitignore) (root)

Add `.env.local` to ensure it's never committed.

---

## Summary of Files

| File | Action |
|------|--------|
| [pipeline.yml](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/pipeline.yml) | [MODIFY] Add `environments: dev + prod` blocks |
| `.github/workflows/ci.yml` | [NEW] Validation CI on push/PR |
| `.github/workflows/scheduled-run.yml` | [NEW] Daily Bruin run (prod) |
| `.env.local.example` | [NEW] Developer credentials template |
| [.gitignore](file:///c:/Users/HOANG%20PHI%20LONG%20DANG/OneDrive/OBSIDIAN%2024%2009%2001/24%2009%2001%20obsidian-go-obsidian_v.0.3.1/Demo%20Vault%202/1.%20PROJECT/DE-PROJECT/cube-semantic/.gitignore) | [MODIFY] Add `.env.local` |
| GitHub Secret `GCP_SERVICE_ACCOUNT_KEY` | [MANUAL] Add once in GitHub UI |

---

## Verification Plan

### Task 1 — Environment separation
```bash
# Locally: dry-run against dev environment (validates env config is parsed)
bruin validate --environment dev .
bruin validate --environment prod .
# Expected: no errors
```

### Task 3 — CI Validation
**Automated:** The `ci.yml` workflow runs on every push to `main`.
After merging, go to:
`https://github.com/longdang193/ecommerce-analytics-bruin/actions`
and confirm both jobs (`bruin-validate`, `cube-validate`) pass with green checkmarks.

**To test a broken state:** Introduce a syntax error in any asset YAML header,
push to a branch, open a PR — the CI should fail and block the merge.

### Task 4 — Scheduled run
**Manual trigger:** After merging, go to:
`https://github.com/longdang193/ecommerce-analytics-bruin/actions/workflows/scheduled-run.yml`
→ click **"Run workflow"** → confirm it completes successfully.
Then verify in BigQuery that `de_pipeline.kpi_daily` `last_modified_time` updated.

### Task 5 — Secrets
Verify the secret is registered:
`https://github.com/longdang193/ecommerce-analytics-bruin/settings/secrets/actions`
Confirm `GCP_SERVICE_ACCOUNT_KEY` appears in the list (value is hidden by design).
