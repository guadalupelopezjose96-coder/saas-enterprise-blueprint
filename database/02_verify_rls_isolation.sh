#!/usr/bin/env bash
# EVIDENCIA DE AUDITORÍA SOC 2 (CC6.1) / ISO 27001 (A.8.3)
# Prueba determinista de no contaminación cruzada entre Tenant A y Tenant B
set -euo pipefail

DB_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:5432/saas_prod}"

TENANT_A="11111111-1111-1111-1111-111111111111"
TENANT_B="22222222-2222-2222-2222-222222222222"

echo "[TEST] Inicializando datos semilla para Tenant A y Tenant B..."
psql "${DB_URL}" -v ON_ERROR_STOP=1 <<SQL
INSERT INTO core.tenants (tenant_id, legal_name, tax_id_vies, data_residency_region, kms_key_arn)
VALUES 
  ('${TENANT_A}', 'Alpha Corp EU', 'DE123456789', 'eu-central-1', 'arn:aws:kms:eu-central-1:1111:key/alpha'),
  ('${TENANT_B}', 'Beta Global Inc', 'IE987654321', 'eu-central-1', 'arn:aws:kms:eu-central-1:2222:key/beta')
ON CONFLICT (tenant_id) DO NOTHING;

SET ROLE saas_app_runtime;
SET LOCAL app.current_tenant_id = '${TENANT_A}';
INSERT INTO core.ledger_transactions (tenant_id, idempotency_key, operation_type, amount_cents, currency, encrypted_payload, created_by_user_id)
VALUES ('${TENANT_A}', 'idem-alpha-001', 'SUBSCRIPTION_CHARGE', 500000, 'EUR', decode('deadbeef', 'hex'), '${TENANT_A}')
ON CONFLICT DO NOTHING;
SQL

echo "[TEST] Autenticando sesión como Tenant B e intentando leer transacciones de Tenant A..."
LEAKED_ROWS=$(psql "${DB_URL}" -t -A -v ON_ERROR_STOP=1 <<SQL
SET ROLE saas_app_runtime;
SET LOCAL app.current_tenant_id = '${TENANT_B}';
SELECT count(*) FROM core.ledger_transactions WHERE tenant_id = '${TENANT_A}';
SQL
)

if [[ "${LEAKED_ROWS}" -ne 0 ]]; then
  echo "[CRITICAL FAILURE] Violación de aislamiento RLS detectada: Tenant B leyó ${LEAKED_ROWS} filas de Tenant A."
  exit 1
fi

echo "[PASS] Aislamiento RLS verificado exitosamente (0 filas filtradas entre inquilinos)."
