#!/usr/bin/env bash
# =============================================================================
# FSI Demo Pack — render + deploy
# =============================================================================
# Dashboards (.lvdash.json) and Genie spaces (.geniespace.json) keep the
# placeholder ${var.catalog} in the repo (no hard-coded catalog). Databricks
# Asset Bundles do NOT substitute variables inside those JSON files, so this
# script renders them into a gitignored .build/ copy with the catalog you pass
# at deploy time, then runs `databricks bundle deploy`.
#
# Usage:
#   ./deploy.sh <catalog> [target] [warehouse_id]
#
#   catalog       Unity Catalog catalog to deploy into (required)
#   target        Bundle target: dev (default) | staging | prod
#   warehouse_id  SQL Warehouse id for dashboards + Genie spaces (required to
#                 deploy those resources; can also be exported as WAREHOUSE_ID)
#
# Optional env:
#   DATABRICKS_CONFIG_PROFILE   CLI profile to use (else the default auth)
#
# Examples:
#   ./deploy.sh my_catalog dev 862f1dabc0000000
#   DATABRICKS_CONFIG_PROFILE=fe-vm-foo ./deploy.sh my_catalog prod abc123
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"

CATALOG="${1:?usage: ./deploy.sh <catalog> [target] [warehouse_id]}"
TARGET="${2:-dev}"
WAREHOUSE="${3:-${WAREHOUSE_ID:-}}"

echo "==> Rendering dashboards + Genie spaces with catalog='${CATALOG}'"
rm -rf .build
while IFS= read -r f; do
  mkdir -p ".build/$(dirname "$f")"
  sed "s|\${var.catalog}|${CATALOG}|g" "$f" > ".build/$f"
  echo "    rendered .build/$f"
done < <(find aibi-portfolio-assistant lakehouse-fsi-credit lakehouse-fsi-smart-claims \
              \( -name '*.lvdash.json' -o -name '*.geniespace.json' \) | sed 's|^\./||')

DEPLOY_ARGS=(--var "catalog=${CATALOG}")
[ -n "${WAREHOUSE}" ] && DEPLOY_ARGS+=(--var "warehouse_id=${WAREHOUSE}")

echo "==> Validating (target=${TARGET})"
databricks bundle validate -t "${TARGET}" "${DEPLOY_ARGS[@]}"

echo "==> Deploying (target=${TARGET})"
databricks bundle deploy -t "${TARGET}" "${DEPLOY_ARGS[@]}"

echo "==> Done. Run jobs with:  databricks bundle run <job_key> -t ${TARGET} ${DEPLOY_ARGS[*]}"
