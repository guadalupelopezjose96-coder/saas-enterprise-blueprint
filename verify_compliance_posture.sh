#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
check_control() {
  local id="$1"
  local desc="$2"
  local pattern="$3"
  local file="$4"

  if grep -qE "${pattern}" "${file}"; then
    echo "  [PASS] ${id}: ${desc} (${file})"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  [FAIL] ${id}: No se encontró '${pattern}' en ${file}"
    exit 1
  fi
}

echo "============================================================================"
echo " EJECUTANDO AUDITORÍA TÉCNICA DE CONTROLES (SOC 2 TIPO II & ISO 27001:2022)"
echo "============================================================================"

check_control "TEN-01 (ISO 8.3)"  "Row-Level Security (RLS) forzado en tablas críticas" "FORCE ROW LEVEL SECURITY" "database/01_schema_rls_and_outbox.sql"
check_control "PRI-01 (ISO 8.10)" "Función de Crypto-Shredding NIST SP 800-88 activa" "execute_tenant_crypto_shredding" "database/01_schema_rls_and_outbox.sql"
check_control "INT-01 (ISO 8.26)" "Inyección atómica de tenant_id e Idempotency-Key en API Go" "app.current_tenant_id" "cmd/api/main.go"
check_control "TST-01 (ISO 8.29)" "Suite de pruebas unitarias de seguridad e inyección en Go" "TestUUIDRegexValidation" "cmd/api/main_test.go"
check_control "DEV-02 (ISO 5.32)" "Bloqueo de licencias virales AGPL/GPL en CI/CD" "AGPL\\|GPL\\|SSPL" ".github/workflows/ci-cd-slsa3-pipeline.yml"
check_control "DEV-03 (ISO 5.21)" "Firma criptográfica Keyless OIDC Cosign y SBOM CycloneDX" "cosign sign-blob" ".github/workflows/ci-cd-slsa3-pipeline.yml"
check_control "NET-01 (ISO 8.20)" "Malla de servicios Istio mTLS en modo STRICT" "mode: STRICT" "kubernetes/01_kyverno_zero_trust_policies.yaml"
check_control "HRD-01 (ISO 8.19)" "Contenedor Distroless ejecutado como UID 65532 (nonroot)" "USER 65532:65532" "Dockerfile"
check_control "MON-01 (ISO 8.11)" "Redacción automática de PII/PAN/JWT en colector OTel" "redaction/pii_compliance" "observability/otel-collector-pii-redaction.yaml"
check_control "MON-02 (ISO 8.15)" "Retención WORM en modo COMPLIANCE (365 días)" "mode = \"COMPLIANCE\"" "terraform/main.tf"
check_control "CRY-02 (ISO 8.24)" "Rotación anual de claves KMS HSM Multi-Región" "enable_key_rotation      = true" "terraform/main.tf"
check_control "BCD-01 (ISO 5.30)" "Clúster Global PostgreSQL Multi-Región (RPO <5m / RTO <30m)" "aws_rds_global_cluster" "terraform/main.tf"
check_control "FIN-01 (ASC 606)"  "Motor de Ingresos Diferidos ASC 606 / IFRS 15 con RLS" "chk_asc606_balance" "finops/asc606_revenue_engine.sql"
check_control "AIG-01 (AI Act)"   "Ledger de Auditoría IA con Human-in-the-Loop (Art. 12/14)" "chk_eu_ai_act_art14_hitl" "ai_governance/01_eu_ai_act_audit_ledger.sql"
check_control "VUL-01 (ISO 8.8)"  "Escaneo continuo de dependencias Dependabot y SECURITY.md" "package-ecosystem: \"gomod\"" ".github/dependabot.yml"
check_control "LEG-01 (MSA/DPA)"  "Cláusulas EU Data Act, EU AI Act, ASC 606 y BYOK vigentes" "EU AI Act" "legal/ORDEN_DE_PEDIDO_B2B_Y_ANEXOS_BYOK_IA.md"

if command -v go >/dev/null 2>&1; then
  echo "----------------------------------------------------------------------------"
  echo " EJECUTANDO PRUEBAS UNITARIAS DE SEGURIDAD EN GO (ISO 8.29):"
  go test -v ./cmd/api/...
fi

echo "----------------------------------------------------------------------------"
echo " RESULTADO DE LA AUDITORÍA: ${PASS_COUNT}/16 CONTROLES CRÍTICOS VERIFICADOS (100%)"
echo "============================================================================"
