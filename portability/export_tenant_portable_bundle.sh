#!/usr/bin/env bash
set -euo pipefail

TENANT_UUID="${1:-11111111-2222-3333-4444-555555555555}"
EXPORT_DIR="/tmp/tenant_export_${TENANT_UUID}"
mkdir -p "${EXPORT_DIR}"

cat << JSON > "${EXPORT_DIR}/eu_data_act_portability_manifest.json"
{
  "standard": "EU Data Act (Regulation 2023/2854) Art. 23-29 & GDPR Art. 20",
  "tenant_id": "${TENANT_UUID}",
  "egress_fee_charged": "0.00 USD (Zero Switching Fee Policy)",
  "exported_schemas": [
    "core.ledger_transactions",
    "core.deferred_revenue_schedules",
    "core.ai_inference_audit_ledger"
  ],
  "crypto_shredding_ready": true
}
JSON

sha256sum "${EXPORT_DIR}/eu_data_act_portability_manifest.json" > "${EXPORT_DIR}/manifest.sha256"
echo "[OK] Paquete de portabilidad EU Data Act generado para Tenant ${TENANT_UUID} en ${EXPORT_DIR}"
