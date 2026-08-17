# Databricks FSI Demo Pack

Two [Databricks Asset Bundles](https://docs.databricks.com/dev-tools/bundles/index.html) packaging three Financial Services demos with centralized variables and a shared ML cluster:

- **`fsi_demo_pack`** (repo root) — the **core** bundle: compute, pipelines, and the data jobs.
- **`fsi_demo_pack_bi`** (`resources-aibi/`) — the **BI** bundle: dashboards + Genie spaces.

They're split because the BI assets reference tables the data jobs create.

> The three demos are adapted from **[dbdemos](https://www.dbdemos.ai)** (Databricks' demo catalog).

## The three demos

| Demo | Folder | Schema | Key resources |
|------|--------|--------|---------------|
| **Credit Decisioning** — BNPL credit scoring: ingestion → AutoML → batch scoring → model serving → GenAI functions | `lakehouse-fsi-credit/` | `fsi_credit` | 1 job · 1 pipeline · 1 dashboard · 1 Genie space |
| **Smart Claims** — insurance claims automation: ingestion → severity model → batch scoring → GenAI functions | `lakehouse-fsi-smart-claims/` | `fsi_smart_claims` | 1 job · 1 pipeline · 2 dashboards |
| **AI/BI Portfolio Assistant** — portfolio analytics via AI/BI dashboard and Genie space | `aibi-portfolio-assistant/` | `fsi_portfolio_assistant` | 1 job · 1 dashboard · 1 Genie space |

**Total:** 3 data jobs (+1 orchestrator) · 2 pipelines · 4 dashboards · 2 Genie spaces · 1 shared ML cluster.

## Prerequisites

- Databricks CLI ≥ v0.230
- Authenticated: `databricks auth login --host <workspace-url> --profile <name>`
- A Unity Catalog catalog you can create schemas in
- A SQL Warehouse

## Deploy

The flow is **deploy core → populate data → deploy BI**. Each step is clean (no expected errors). Run all commands from the repo root except step 4, which runs from `resources-aibi/`.

**1. Authenticate** (creates a CLI profile named `my-ws`):
```bash
databricks auth login --host <workspace-url> --profile my-ws
```

**2. Deploy the core bundle** (compute, pipelines, jobs) — supply your catalog:
```bash
databricks bundle deploy -t dev -p my-ws --var catalog=<your_catalog>
```
On **GCP/Azure**, also pass a cloud node type and disable the AWS attribute:
```bash
# GCP:   ... --var node_type_id=n2-standard-4    --var 'aws_attributes={}'
# Azure: ... --var node_type_id=Standard_DS3_v2  --var 'aws_attributes={}'
```
> No `warehouse_id` needed here — the core bundle has no dashboards or Genie spaces.

**3. Populate the data** — one command runs all three data jobs in parallel (each creates its own schema, volume, and tables):
```bash
databricks bundle run populate_all_data -t dev -p my-ws
```

**4. Deploy the BI bundle** (dashboards + Genie spaces) — now that the tables exist. Use the **same** `catalog` as step 2, and pass your SQL Warehouse id:
```bash
cd resources-aibi
databricks bundle deploy -t dev -p my-ws \
  --var catalog=<your_catalog> \
  --var warehouse_id=<your_sql_warehouse_id>
```

## Variables

**Core bundle** (repo root):

| Variable | Default | Purpose |
|----------|---------|---------|
| `catalog` | *(none — **required**)* | UC catalog for all demos |
| `node_type_id` | `r6id.xlarge` | ML cluster node type (override per cloud) |
| `aws_attributes` | `{availability: ON_DEMAND}` | AWS-only; set `{}` on GCP/Azure |
| `credit_schema` | `fsi_credit` | Schema for Credit Decisioning |
| `smart_claims_schema` | `fsi_smart_claims` | Schema for Smart Claims |
| `credit_volume` | `credit_raw_data` | Volume for credit raw data |
| `claims_volume` | `volume_claims` | Volume for claims data |

**BI bundle** (`resources-aibi/`):

| Variable | Default | Purpose |
|----------|---------|---------|
| `catalog` | *(none — **required**)* | UC catalog — **must match** the core bundle |
| `warehouse_id` | *(none — **required**)* | SQL Warehouse for dashboards & Genie spaces |
| `credit_schema` | `fsi_credit` | Must match the core bundle |
| `smart_claims_schema` | `fsi_smart_claims` | Must match the core bundle |

**Choosing `node_type_id`** (it's cloud-specific): list valid types with
`databricks clusters list-node-types -p my-ws`, or use a ~4-vCPU/16–32 GB type:

| Cloud | `node_type_id` | `aws_attributes` |
|-------|----------------|------------------|
| AWS   | `r6id.xlarge` (default) | keep default (`ON_DEMAND`) |
| GCP   | `n2-standard-4` | `--var 'aws_attributes={}'` |
| Azure | `Standard_DS3_v2` | `--var 'aws_attributes={}'` |

Deploys on AWS, GCP, and Azure — pass the cloud-specific variables above.
