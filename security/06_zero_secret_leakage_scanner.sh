#!/usr/bin/env bash
set -euo pipefail

SECRET_REGEX='(BEGIN OPENSSH PRIVATE KEY|BEGIN RSA PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[0-9a-zA-Z]{36})'

if git grep -I -E "${SECRET_REGEX}" -- ':!security/06_zero_secret_leakage_scanner.sh' >/dev/null 2>&1; then
  echo "[FAIL] Violacion SEC-01 (ISO A.8.12): Se detecto un secreto o llave privada en el arbol Git."
  exit 1
fi

echo "[OK] Escaneo DLP SEC-01 completado: 0 credenciales estaticas o llaves privadas expuestas."
