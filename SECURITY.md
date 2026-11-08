# Política de Seguridad y Divulgación de Vulnerabilidades (ISO/IEC 29147)

## Versiones Soportadas y Postura Criptográfica
| Versión | Estado de Soporte | Cumplimiento Normativo | Firma Criptográfica |
| :--- | :--- | :--- | :--- |
| `v4.0.x` | Soporte Activo (LTS) | SOC 2 Tipo II, ISO 27001:2022, GDPR, EU AI Act, ASC 606 | SSH Ed25519 + Sigstore Cosign OIDC |

## Reporte de Vulnerabilidades (SLA de Respuesta)
- **Críticas (CVSS 9.0 - 10.0):** Acuse de recibo en `< 4 horas`, mitigación o parche en `< 24 horas`.
- **Altas (CVSS 7.0 - 8.9):** Acuse de recibo en `< 12 horas`, parche en `< 72 horas`.
- **Verificación de Artefactos de Auditoría:** Ejecute `./verify_external_audit_bundle.sh` para validar criptográficamente el paquete `.tar.gz`, su digest `.sha256` y su firma asimétrica `.sig` contra `compliance/allowed_signers`.
