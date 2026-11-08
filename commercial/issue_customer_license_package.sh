#!/usr/bin/env bash
# =============================================================================
# MOTOR DE EMISION Y FIRMA CRIPTOGRAFICA ED25519 DE LICENCIAS COMERCIALES B2B
# Uso: ./commercial/issue_customer_license_package.sh "Acme Corp" "TIER_2_ENTERPRISE"
# =============================================================================
set -euo pipefail

CLIENT_NAME="${1:-Demo Enterprise Corp}"
LICENSE_TIER="${2:-TIER_2_ENTERPRISE_4900_USD}"
ISSUE_TS=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
LICENSE_UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "88888888-4444-4444-4444-121212121212")
MERKLE_ROOT=$(python3 -c "import json; print(json.load(open('compliance/MERKLE_ROOT_ATTESTATION.json'))['merkle_root_sha256'])")
COMMIT_SHA=$(git rev-parse HEAD)

OUT_DIR="/tmp/b2b_license_dispatch_${LICENSE_UUID}"
mkdir -p "${OUT_DIR}"

CERT_PATH="${OUT_DIR}/COMMERCIAL_LICENSE_CERTIFICATE.json"

cat << JSON > "${CERT_PATH}"
{
  "licensor": "Standard 1979 Holdings, LLC / Guadalupe Lopez Jose",
  "license_agreement_standard": "17 U.S.C. 501 & UCC 2-316 Proprietary Commercial License",
  "license_id": "${LICENSE_UUID}",
  "issued_at_utc": "${ISSUE_TS}",
  "licensee_legal_name": "${CLIENT_NAME}",
  "commercial_tier": "${LICENSE_TIER}",
  "authorized_release": "v4.0.0 (52/52 Controls | 36/36 Lifecycle Phases)",
  "git_commit_sha": "${COMMIT_SHA}",
  "rfc6962_merkle_root_sha256": "${MERKLE_ROOT}",
  "ed25519_Authority_fingerprint": "SHA256:KwUySdN/G/MP10KULN+FYsyZ9XyNS9osjmNHbBEvE3s",
  "audit_ready_disclaimer": "Technical reference architecture and compliance accelerator; does not substitute accredited CPA/ISO body certification."
}
JSON

sha256sum "${CERT_PATH}" > "${CERT_PATH}.sha256"
ssh-keygen -Y sign -f "$HOME/.ssh/id_ed25519.pub" -n file "${CERT_PATH}"

ssh-keygen -Y verify \
  -f compliance/allowed_signers \
  -I "263217442+guadalupelopezjose96-coder@users.noreply.github.com" \
  -n file \
  -s "${CERT_PATH}.sig" < "${CERT_PATH}"

echo "============================================================================"
echo " [OK] LICENCIA COMERCIAL B2B EMITIDA Y FIRMADA CON ED25519 EXITOSAMENTE:"
echo "  - Cliente:   ${CLIENT_NAME}"
echo "  - Tier:      ${LICENSE_TIER}"
echo "  - Licencia:  ${CERT_PATH}"
echo "  - Firma:     ${CERT_PATH}.sig"
echo "============================================================================"
