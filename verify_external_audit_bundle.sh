#!/usr/bin/env bash
set -euo pipefail

BUNDLE_FILE="${1:-../saas-enterprise-audit-bundle-$(date -u '+%Y%m%d').tar.gz}"
SIGNER_IDENTITY=$(awk '{print $1}' compliance/allowed_signers)

echo "============================================================================"
echo " VERIFICACIÓN CRIPTOGRÁFICA DE PAQUETE DE AUDITORÍA (ED25519 + SHA-256)"
echo "============================================================================"

if [ ! -f "${BUNDLE_FILE}" ]; then
  echo "[ERROR] No se encontró el paquete: ${BUNDLE_FILE}"
  exit 1
fi

echo "[1/2] Verificando integridad SHA-256 de ${BUNDLE_FILE}..."
sha256sum -c "${BUNDLE_FILE}.sha256"

echo "[2/2] Verificando firma asimétrica Ed25519 contra compliance/allowed_signers..."
ssh-keygen -Y verify \
  -f compliance/allowed_signers \
  -I "${SIGNER_IDENTITY}" \
  -n file \
  -s "${BUNDLE_FILE}.sig" < "${BUNDLE_FILE}"

echo "----------------------------------------------------------------------------"
echo " [OK] VERIFICACIÓN MATEMÁTICA EXITOSA: Firma Ed25519 y Hash SHA-256 Auténticos"
echo "============================================================================"
