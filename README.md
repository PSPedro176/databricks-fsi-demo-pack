# Databricks FSI Demo Pack

One [Databricks Asset Bundle](https://docs.databricks.com/dev-tools/bundles/index.html) (`fsi_demo_pack`) packaging three Financial Services demos with centralized variables and a shared ML cluster.

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

```bash
databricks bundle deploy -t dev \
  --var catalog=<your_catalog> \
  --var warehouse_id=<your_sql_warehouse_id>
```

**Important:** Genie spaces validate tables at creation time. On a fresh catalog:
1. Deploy (dashboards/jobs/pipelines deploy; Genie spaces error until data exists)
2. Run the jobs (populates tables)
3. Deploy again (creates Genie spaces)

### Run the jobs

```bash
databricks bundle run credit_job -t dev --var catalog=<cat> --var warehouse_id=<id>
databricks bundle run smart_claims_job -t dev --var catalog=<cat> --var warehouse_id=<id>
databricks bundle run portfolio_assistant_init -t dev --var catalog=<cat> --var warehouse_id=<id>
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

Deploys on AWS, GCP, and Azure — pass cloud-specific variables as needed.
