# Enterprise SaaS B2B Master Blueprint (Technical, Legal, GRC & FinOps)

Repositorio de arquitectura de referencia, contratos marco e infraestructura inmutable validado al 100% bajo controles **SOC 2 Tipo II**, **ISO/IEC 27001:2022**, **GDPR**, **EU Data Act**, **EU AI Act** y **ASC 606 / IFRS 15**.

## Estructura del Repositorio Auditado

* `cmd/api/main.go`: Microservicio en Go con transacciones atómicas, inyección de contexto `app.current_tenant_id` (RLS), `Idempotency-Key` y patrón *Transactional Outbox*.
* `database/01_schema_rls_and_outbox.sql`: Esquema PostgreSQL Multi-Tenant con `FORCE ROW LEVEL SECURITY` y procedimiento de borrado criptográfico `execute_tenant_crypto_shredding` (NIST SP 800-88).
* `database/02_verify_rls_isolation.sh`: Suite automatizada de regresión contra contaminación cruzada entre inquilinos.
* `.github/workflows/ci-cd-slsa3-pipeline.yml`: Pipeline DevSecOps SLSA Nivel 3 con bloqueo de licencias virales (AGPL/GPL/SSPL), generación de SBOM CycloneDX y firma sin claves Cosign.
* `Dockerfile`: Imagen de producción Multi-Stage basada en `gcr.io/distroless/static-debian12:nonroot` (UID `65532:65532`).
* `kubernetes/01_kyverno_zero_trust_policies.yaml`: Controlador de admisión Kyverno (verificación de firmas Cosign/SBOM y contenedores no-root), Istio `PeerAuthentication` (`STRICT` mTLS) y `NetworkPolicy` default-deny.
* `observability/otel-collector-pii-redaction.yaml`: Colector OpenTelemetry con sanitización mediante expresiones regulares de PII, tarjetas PAN y JWT antes de exportar a almacenamiento WORM.
* `terraform/main.tf`: Infraestructura como Código Multi-Región (`eu-central-1` y `eu-west-1`), claves AWS KMS HSM FIPS 140-3 con rotación anual, S3 Object Lock en modo `COMPLIANCE` (365 días) y Aurora Global Database (RPO < 5 min, RTO < 30 min).
* `legal/PAQUETE_CONTRACTUAL_MAESTRO_MSA_DPA_SLA.md`: Contrato Maestro de Suscripción (MSA), Anexo de Procesamiento de Datos (DPA con SCCs y notificación < 36h) y SLA (99.95%).
* `legal/ORDEN_DE_PEDIDO_B2B_Y_ANEXOS_BYOK_IA.md`: Orden de Pedido B2B con precios híbridos (ASC 606), anexo criptográfico BYOK y anexo de gobernanza de IA (EU AI Act).
* `compliance/ISO27001_SOA_AND_IRP_BCDR_MASTER.md`: Declaración de Aplicabilidad (SoA - 93 controles Anexo A) y Plan Maestro de Respuesta a Incidentes (IRP) y BCDR.
* `compliance/SHA256_AUDIT_MANIFEST.txt`: Manifiesto criptográfico SHA-256 de todos los artefactos.
* `verify_compliance_posture.sh`: Verificador automatizado de los 12 controles críticos del ecosistema.
