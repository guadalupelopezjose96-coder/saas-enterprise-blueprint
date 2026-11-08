#!/usr/bin/env bash
# =============================================================================
# MOTOR DE EMISION Y FIRMA CRIPTOGRAFICA ED25519 DE LICENCIAS COMERCIALES B2B
# Uso: ./commercial/issue_customer_license_package.sh "Acme Corp" "TIER_2_ENTERPRISE_4900_USD" [github_user]
# =============================================================================
set -euo pipefail

CLIENT_NAME="${1:-Demo Enterprise Corp}"
LICENSE_TIER="${2:-TIER_2_ENTERPRISE_4900_USD}"
CLIENT_GITHUB_USER="${3:-}"
ISSUE_TS=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
LICENSE_UUID=$(python3 -c 'import uuid; print(uuid.uuid4())')
MERKLE_ROOT=$(python3 -c "import json; print(json.load(open('compliance/MERKLE_ROOT_ATTESTATION.json'))['merkle_root_sha256'])")
COMMIT_SHA=$(git rev-parse HEAD)

OUT_DIR="${HOME}/b2b_dispatched_licenses/license_${LICENSE_UUID}"
mkdir -p "${OUT_DIR}"

CERT_PATH="${OUT_DIR}/COMMERCIAL_LICENSE_CERTIFICATE.json"

cat << JSON > "${CERT_PATH}"
{
  "licensor": "Standard 1979 Holdings, LLC / Jose Emanuel Guadalupe Lopez",
  "license_agreement_standard": "17 U.S.C. 501 & UCC 2-316 Proprietary Commercial License",
  "license_id": "${LICENSE_UUID}",
  "issued_at_utc": "${ISSUE_TS}",
  "licensee_legal_name": "${CLIENT_NAME}",
  "licensee_github_user": "${CLIENT_GITHUB_USER:-PENDING_ASSIGNMENT}",
  "commercial_tier": "${LICENSE_TIER}",
  "authorized_release": "v4.0.0 (55/55 Controls | 36/36 Lifecycle Phases)",
  "git_commit_sha": "${COMMIT_SHA}",
  "rfc6962_merkle_root_sha256": "${MERKLE_ROOT}",
  "ed25519_authority_fingerprint": "SHA256:KwUySdN/G/MP10KULN+FYsyZ9XyNS9osjmNHbBEvE3s",
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

if [[ -n "${CLIENT_GITHUB_USER}" && "${CLIENT_GITHUB_USER}" != "USUARIO_GITHUB_CLIENTE" ]]; then
  echo "[INFO] Otorgando acceso de lectura (pull) en la boveda privada a @${CLIENT_GITHUB_USER}..."
  gh api --method PUT "repos/guadalupelopezjose96-coder/saas-enterprise-blueprint/collaborators/${CLIENT_GITHUB_USER}" -f permission=pull >/dev/null
  echo "[OK] Invitacion de acceso enviada a @${CLIENT_GITHUB_USER}."
fi

echo "============================================================================"
echo " [OK] LICENCIA COMERCIAL B2B EMITIDA Y FIRMADA CON ED25519 EN TERMUX:"
echo "  - Cliente:   ${CLIENT_NAME}"
echo "  - Tier:      ${LICENSE_TIER}"
echo "  - Carpeta:   ${OUT_DIR}"
echo "  - Licencia:  ${CERT_PATH}"
echo "  - Firma:     ${CERT_PATH}.sig"
echo "============================================================================"
