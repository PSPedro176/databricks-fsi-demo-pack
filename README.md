# Databricks FSI Demo Pack

A single [Databricks Asset Bundle](https://docs.databricks.com/dev-tools/bundles/index.html)
(`fsi_demo_pack`) that packages three Financial Services (FSI) demos with **centralized
variables**, a **shared managed ML cluster**, and `dev` / `staging` / `prod` targets.

Deploy it into any workspace with a plain `databricks bundle deploy` — the catalog is chosen
at deploy time and injected everywhere (including dashboards and Genie spaces).

## The three demos

| Demo | Folder | Schema | Volume | Key resources |
|------|--------|--------|--------|---------------|
| **Credit Decisioning** — BNPL credit scoring: ingestion → feature engineering → AutoML → batch scoring → explainability & fairness → model serving → GenAI functions. | `lakehouse-fsi-credit/` | `fsi_credit` | `credit_raw_data` | Pipeline (SDP, SQL) · jobs `credit_job`, `credit_init_job` · **1 dashboard** · **1 Genie space** |
| **Smart Claims** — insurance claims automation: ingestion → accident-severity model → batch scoring → dynamic rule engine → GenAI functions. | `lakehouse-fsi-smart-claims/` | `fsi_smart_claims` | `volume_claims` | Pipeline (SDP, Python) · job `smart_claims_job` (6 tasks) · **2 dashboards** |
| **AI/BI Portfolio Assistant** — portfolio & market analytics via an AI/BI dashboard and a Genie space. | `aibi-portfolio-assistant/` | `fsi_portfolio_assistant` | `portfolio_raw_data` | job `portfolio_assistant_init` · **1 dashboard** · **1 Genie space** |

**Bundle resources:** 4 jobs · 2 pipelines · **4 dashboards** · **2 Genie spaces** · 1 shared ML cluster.

## How the catalog is injected (no hard-coded catalogs)

Everything is driven by the `catalog` bundle variable. Job/pipeline parameters use
`${var.catalog}`, and the dashboards and Genie spaces are stored **inline** as
`serialized_dashboard` / `serialized_space` fields (in `resources/dashboards.yml` and
`resources/genies.yml`) so bundle variable substitution rewrites `${var.catalog}` at deploy
time. (Databricks does not substitute variables inside `file_path`-referenced JSON, which is
why the content is inline.) Pick the catalog with `--var catalog=...`.

## Prerequisites

- **Databricks CLI** ≥ v0.230 (`databricks --version`)
- Authenticated CLI: `databricks auth login --host <workspace-url> --profile <name>`
- An existing **Unity Catalog catalog** you can create schemas in
- A **SQL Warehouse** (required by all dashboards and Genie spaces)
- Permission to create clusters, pipelines, jobs, dashboards and Genie spaces

## Deploy

```bash
databricks bundle deploy -t dev \
  --var catalog=<your_catalog> \
  --var warehouse_id=<your_sql_warehouse_id>
```

Use a specific profile with `-p <profile>` (or `DATABRICKS_CONFIG_PROFILE`). Targets: `dev`
(default, development mode), `staging`, `prod` (production mode).

> **Order note:** Genie spaces validate that their tables exist at creation time. On a brand-new
> catalog, deploy first (dashboards/jobs/pipelines create fine; the Genie spaces will error
> until data exists), run the jobs below to populate the tables, then re-run `bundle deploy`
> to create the Genie spaces.

## Run the demos

```bash
databricks bundle run credit_job              -t dev --var catalog=<cat> --var warehouse_id=<id>
databricks bundle run smart_claims_job        -t dev --var catalog=<cat> --var warehouse_id=<id>
databricks bundle run portfolio_assistant_init -t dev --var catalog=<cat> --var warehouse_id=<id>
```

These create the schemas/volumes and populate the tables the dashboards and Genie spaces read.

## Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `catalog` | `perdomo_tests_catalog` | Unity Catalog catalog for all demos |
| `credit_schema` | `fsi_credit` | Schema for Credit Decisioning |
| `smart_claims_schema` | `fsi_smart_claims` | Schema for Smart Claims |
| `credit_volume` | `credit_raw_data` | Volume for credit raw data |
| `claims_volume` | `volume_claims` | Volume for claims data |
| `ml_cluster_id` | *(bundle-managed)* | Set automatically to the `ml_cluster` created by the bundle |
| `warehouse_id` | *(empty)* | SQL Warehouse for dashboards & Genie spaces — pass at deploy |

## Repository layout

```
databricks.yml              # bundle name, variables, shared ML cluster, targets
resources/
  credit.yml                # credit pipeline + 2 jobs
  smart_claims.yml          # smart-claims pipeline + job
  portfolio_assistant.yml   # portfolio init job
  dashboards.yml            # 4 dashboards (inline serialized_dashboard)
  genies.yml                # 2 Genie spaces (inline serialized_space)
lakehouse-fsi-credit/       # notebooks + SDP transformations
lakehouse-fsi-smart-claims/ # notebooks + SDP transformations
aibi-portfolio-assistant/   # notebook
```
