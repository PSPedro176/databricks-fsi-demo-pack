# Databricks FSI Demo Pack

One [Databricks Asset Bundle](https://docs.databricks.com/dev-tools/bundles/index.html) (`fsi_demo_pack`) packaging three Financial Services demos with centralized variables and a shared ML cluster.

> The three demos are adapted from **[dbdemos](https://www.dbdemos.ai)** (Databricks' demo catalog).

## The three demos

| Demo | Folder | Schema | Key resources |
|------|--------|--------|---------------|
| **Credit Decisioning** — BNPL credit scoring: ingestion → AutoML → batch scoring → model serving → GenAI functions | `lakehouse-fsi-credit/` | `fsi_credit` | 2 jobs · 1 pipeline · 1 dashboard · 1 Genie space |
| **Smart Claims** — insurance claims automation: ingestion → severity model → batch scoring → GenAI functions | `lakehouse-fsi-smart-claims/` | `fsi_smart_claims` | 1 job · 1 pipeline · 2 dashboards |
| **AI/BI Portfolio Assistant** — portfolio analytics via AI/BI dashboard and Genie space | `aibi-portfolio-assistant/` | `fsi_portfolio_assistant` | 1 job · 1 dashboard · 1 Genie space |

**Total:** 4 jobs · 2 pipelines · 4 dashboards · 2 Genie spaces · 1 shared ML cluster.

## Prerequisites

- Databricks CLI ≥ v0.230
- Authenticated: `databricks auth login --host <workspace-url> --profile <name>`
- A Unity Catalog catalog you can create schemas in
- A SQL Warehouse

## Deploy

**1. Authenticate** (creates a CLI profile named `my-ws`):
```bash
databricks auth login --host <workspace-url> --profile my-ws
```

**2. Deploy** — supply your catalog and SQL Warehouse id:
```bash
databricks bundle deploy -t dev -p my-ws \
  --var catalog=<your_catalog> \
  --var warehouse_id=<your_sql_warehouse_id>
```
On **GCP/Azure**, also pass a cloud node type and disable the AWS attribute:
```bash
# GCP:   ... --var node_type_id=n2-standard-4    --var 'aws_attributes={}'
# Azure: ... --var node_type_id=Standard_DS3_v2  --var 'aws_attributes={}'
```

> On a fresh catalog, this first deploy **reports errors for the 2 Genie spaces** (their tables don't exist yet) — that's expected. **Don't re-run this deploy**; deploy from a single working copy and just continue to step 3. (Re-running a failed deploy, or deploying from a fresh clone without the prior state, can create duplicate jobs.)

**3. Run the jobs** to populate the tables (catalog/warehouse are baked in at deploy — no vars needed):
```bash
databricks bundle run credit_job -t dev -p my-ws
databricks bundle run smart_claims_job -t dev -p my-ws
databricks bundle run portfolio_assistant_init -t dev -p my-ws
```

**4. Deploy again** to create the Genie spaces (they require their tables to exist):
```bash
databricks bundle deploy -t dev -p my-ws \
  --var catalog=<your_catalog> --var warehouse_id=<your_sql_warehouse_id>
```

## Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `catalog` | `perdomo_tests_catalog` | UC catalog for all demos |
| `warehouse_id` | *(empty)* | SQL Warehouse for dashboards & Genie spaces (required) |
| `node_type_id` | `r6id.xlarge` | ML cluster node type (override per cloud) |
| `aws_attributes` | `{availability: ON_DEMAND}` | AWS-only; set `{}` on GCP/Azure |
| `credit_schema` | `fsi_credit` | Schema for Credit Decisioning |
| `smart_claims_schema` | `fsi_smart_claims` | Schema for Smart Claims |
| `credit_volume` | `credit_raw_data` | Volume for credit raw data |
| `claims_volume` | `volume_claims` | Volume for claims data |

**Choosing `node_type_id`** (it's cloud-specific): list valid types with
`databricks clusters list-node-types -p my-ws`, or use a ~4-vCPU/16–32 GB type:

| Cloud | `node_type_id` | `aws_attributes` |
|-------|----------------|------------------|
| AWS   | `r6id.xlarge` (default) | keep default (`ON_DEMAND`) |
| GCP   | `n2-standard-4` | `--var 'aws_attributes={}'` |
| Azure | `Standard_DS3_v2` | `--var 'aws_attributes={}'` |

Deploys on AWS, GCP, and Azure — pass the cloud-specific variables above.
