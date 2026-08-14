# Databricks FSI Demo Pack

A single [Databricks Asset Bundle](https://docs.databricks.com/dev-tools/bundles/index.html)
(`fsi_demo_pack`) that packages three Financial Services (FSI) demos with **centralized
variables**, a **shared managed ML cluster**, and `dev` / `staging` / `prod` targets.

All demos write to one Unity Catalog catalog (chosen at deploy time), each into its own schema.

## The three demos

| Demo | Folder | Schema | Volume | Key resources |
|------|--------|--------|--------|---------------|
| **Credit Decisioning** — BNPL credit scoring: ingestion → feature engineering → AutoML → batch scoring → explainability & fairness → model serving → GenAI functions. | `lakehouse-fsi-credit/` | `fsi_credit` | `credit_raw_data` | Pipeline (SDP, SQL) · jobs `credit_job`, `credit_init_job` · **1 dashboard** · **1 Genie space** |
| **Smart Claims** — insurance claims automation: ingestion → accident-severity model → batch scoring → dynamic rule engine → GenAI functions. | `lakehouse-fsi-smart-claims/` | `fsi_smart_claims` | `volume_claims` | Pipeline (SDP, Python) · job `smart_claims_job` (6 tasks) · **2 dashboards** |
| **AI/BI Portfolio Assistant** — portfolio & market analytics via an AI/BI dashboard and a Genie space. | `aibi-portfolio-assistant/` | `fsi_portfolio_assistant` | `portfolio_raw_data` | job `portfolio_assistant_init` · **1 dashboard** · **1 Genie space** |

**Bundle resources:** 4 jobs · 2 pipelines · **4 dashboards** · **2 Genie spaces** · 1 shared ML cluster.

## How the catalog is injected (no hard-coded catalogs)

Dashboards (`.lvdash.json`) and Genie spaces (`.geniespace.json`) reference tables using the
placeholder `${var.catalog}`. Databricks Asset Bundles do **not** substitute variables *inside*
those JSON files, so [`deploy.sh`](./deploy.sh) renders them into a gitignored `.build/` copy
with the catalog you choose at deploy time, then runs `databricks bundle deploy`. Nothing in the
repo is tied to a specific catalog.

## Prerequisites

- **Databricks CLI** ≥ v0.230 (`databricks --version`)
- Authenticated CLI: `databricks auth login --host <workspace-url> --profile <name>`
- A **Unity Catalog catalog** you can write to
- A **SQL Warehouse** (required by all dashboards and Genie spaces)
- Permission to create clusters, pipelines, jobs, dashboards and Genie spaces

## Deploy

```bash
# ./deploy.sh <catalog> [target] [warehouse_id]
./deploy.sh my_catalog dev <sql_warehouse_id>
```

Use a specific CLI profile / workspace:

```bash
DATABRICKS_CONFIG_PROFILE=my_profile ./deploy.sh my_catalog dev <sql_warehouse_id>
```

`deploy.sh` renders the catalog into `.build/`, validates, then deploys. Targets: `dev`
(default, development mode), `staging`, `prod` (production mode).

> Deploying with a bare `databricks bundle deploy` skips the render step and the dashboards/
> Genie spaces will contain the literal `${var.catalog}` — always deploy via `./deploy.sh`.

## Run the demos

After deploy, run each demo's entrypoint job (pass the same catalog/warehouse vars):

```bash
databricks bundle run credit_job            -t dev --var catalog=my_catalog --var warehouse_id=<id>
databricks bundle run smart_claims_job      -t dev --var catalog=my_catalog --var warehouse_id=<id>
databricks bundle run portfolio_assistant_init -t dev --var catalog=my_catalog --var warehouse_id=<id>
```

The jobs create the schemas/volumes and populate the tables the dashboards and Genie spaces
read from, so run them before opening the dashboards.

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
  credit.yml                # credit pipeline + 2 jobs + 1 dashboard + 1 genie
  smart_claims.yml          # smart-claims pipeline + job + 2 dashboards
  portfolio_assistant.yml   # portfolio job + 1 dashboard + 1 genie
deploy.sh                   # render (${var.catalog} -> catalog) + validate + deploy
lakehouse-fsi-credit/       # notebooks, SDP transformations, _dashboards/, _genie_spaces/
lakehouse-fsi-smart-claims/ # notebooks, SDP transformations, _dashboards/
aibi-portfolio-assistant/   # notebook, _dashboards/, _genie_spaces/
```
