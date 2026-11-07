#!/usr/bin/env bash
# =============================================================================
# SELLADO CRIPTOGRÁFICO Y VERIFICACIÓN DE INTEGRIDAD DEL REPOSITORIO SAAS
# Cumplimiento: ISO/IEC 27001:2022 (A.5.1, A.5.33, A.8.32) | SOC 2 Tipo II
# =============================================================================
set -euo pipefail

BASE_DIR="$HOME/saas-enterprise-blueprint"
MANIFEST_FILE="${BASE_DIR}/compliance/SHA256_AUDIT_MANIFEST.txt"

mkdir -p "${BASE_DIR}/database" \
         "${BASE_DIR}/kubernetes" \
         "${BASE_DIR}/observability" \
         "${BASE_DIR}/legal" \
         "${BASE_DIR}/compliance" \
         "${BASE_DIR}/.github/workflows"

echo "==================================================================" > "${MANIFEST_FILE}"
echo " MANIFIESTO DE INTEGRIDAD CRIPTOGRÁFICA (SHA-256) - SAAS BLUEPRINT" >> "${MANIFEST_FILE}"
echo " Generado en UTC: $(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "${MANIFEST_FILE}"
echo " Nodo de Auditoría: $(whoami)@$(hostname)" >> "${MANIFEST_FILE}"
echo "==================================================================" >> "${MANIFEST_FILE}"
echo "" >> "${MANIFEST_FILE}"

# Calcular hashes SHA-256 de todos los archivos desplegados excluyendo el propio manifiesto y .git
find "${BASE_DIR}" -type f \
  ! -path "*/.git/*" \
  ! -name "SHA256_AUDIT_MANIFEST.txt" \
  -print0 | sort -z | xargs -0 sha256sum >> "${MANIFEST_FILE}"

echo "[OK] Manifiesto criptográfico generado exitosamente en: ${MANIFEST_FILE}"
cat "${MANIFEST_FILE}"

# Inicializar repositorio Git inmutable si no existe
if [ ! -d "${BASE_DIR}/.git" ]; then
  git init "${BASE_DIR}"
  git -C "${BASE_DIR}" branch -M main
fi

git -C "${BASE_DIR}" add -A
git -C "${BASE_DIR}" status -s
