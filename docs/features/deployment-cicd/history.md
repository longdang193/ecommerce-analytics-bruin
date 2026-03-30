# Deployment + CI/CD — History

## Post-Execution Review

**Feature type:** ADD
**Status:** repo implementation present as of 2026-03-30; GitHub secret remains environment-managed

---

### Classification Accurate

Yes. The deployment layer is a net-new CI/CD capability. No automated pipeline runs or environment separation existed before this feature.

---

### Key Decisions

1. **No Docker for Bruin.** Bruin runs as a CLI binary calling BigQuery over HTTPS — there is no local database to containerize. The existing `cube-semantic/docker-compose.yml` is for Cube local dev only.

2. **Environment separation via `pipeline.yml` environments block.** `dev` targets `de_pipeline_dev`; `prod` targets `de_pipeline`. Prevents accidental writes to production during development.

3. **`bruin validate` is a local structural check.** It parses YAML headers, dependency graphs, and SQL syntax — no BigQuery credentials needed. Safe to run on every PR in CI.

4. **`cubejs-cli validate` requires BQ credentials in CI.** The compile step resolves types from BigQuery. GCP credentials are passed via GitHub Secret `GCP_SERVICE_ACCOUNT_KEY` — not the service account JSON file path.

5. **`workflow_dispatch` enabled on scheduled run.** Allows manual re-runs from GitHub Actions UI without code changes — useful when data issues require a backfill.

6. **Cube Cloud auto-deploy replaces a manual Cube deployment workflow.** GitHub integration on Cube Cloud means semantic model changes deploy automatically on `git push origin main` — no separate Cube deployment step needed.

---

### Current State Notes

- `pipeline.yml` now uses explicit `dev` and `prod` environments with separate dataset targets
- `.github/workflows/ci.yml` and `.github/workflows/scheduled-run.yml` are present in the repo
- `.env.local.example` is present as the local developer template
- GitHub Secret `GCP_SERVICE_ACCOUNT_KEY` is still managed outside the repo and cannot be verified from the checkout alone

---

### Docs Updated

- `docs/features/deployment-cicd.yaml` — created as feature contract
- `plans/deployment-layer-plan.md` — referenced as plan
