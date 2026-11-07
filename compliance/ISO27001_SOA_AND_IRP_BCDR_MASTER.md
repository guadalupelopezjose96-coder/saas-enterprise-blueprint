# DECLARACIÓN DE APLICABILIDAD (SoA ISO/IEC 27001:2022) Y PLAN MAESTRO IRP/BCDR
**Identificador Documental:** `ISMS-SOA-IRP-BCDR-2026-V4.0`

## 1. RESUMEN DE APLICABILIDAD DEL ANEXO A (ISO/IEC 27001:2022)
* **Dominio 5 (Controles Organizacionales - 37/37 Aplicables):** Políticas como código, segregación de funciones en Git/Cloud, SBOM SLSA Nivel 3 (5.21), TPRM (5.19-5.22), gestión de incidentes (5.24-5.28), BCDR (5.29-5.30), protección de registros WORM (5.33) y privacidad ROPA/DSAR (5.34).
* **Dominio 6 (Controles de Personas - 8/8 Aplicables):** Background checks previos al ingreso (6.1), contratos PIIA/NDA (6.6), formación anual OWASP/Phishing (6.3) y trabajo remoto Zero Trust con MDM/EDR (6.7).
* **Dominio 7 (Controles Físicos - 13/14 Aplicables, 1 Excluido):** Controles de centros de datos (7.1-7.6, 7.11) heredados contractualmente de AWS/GCP auditados vía SOC 2 Tipo II. Controles de pantalla limpia, cifrado FileVault/BitLocker y borrado NIST SP 800-88 aplicados vía MDM. Control 7.12 (Seguridad del cableado) excluido justificadamente por arquitectura 100% Cloud-Native sin oficinas físicas.
* **Dominio 8 (Controles Tecnológicos - 34/34 Aplicables):** Zero Standing Privileges (8.2), aislamiento RLS (8.3), FIDO2 (8.5), auto-escalado Karpenter (8.6), SLA de parches <48h para críticas (8.8), IaC/GitOps (8.9), Crypto-Shredding (8.10), redacción PII en OpenTelemetry (8.11), logs WORM (8.15), contenedores Distroless no-root (8.18-8.19), mTLS y NetworkPolicies (8.20-8.22), HSM FIPS 140-3 (8.24) y bloqueo SAST/SCA/Cosign en CI/CD (8.25-8.32).

## 2. PLAN DE RESPUESTA A INCIDENTES (IRP) Y BCDR
* **Comando de Incidentes (ICS):** Incident Commander (SRE), Security Lead (CISO), Legal/DPO y Scribe forense.
* **Preservación Forense (ISO 5.28):** Captura automatizada de NetworkPolicy de cuarentena, snapshots EBS y volcado de logs firmados con SHA-256 hacia bucket S3 con Object Lock en modo COMPLIANCE (WORM).
* **Cronograma Legal:** Alerta temprana NIS2/DORA (<24h), Notificación a Clientes DPA (<36h), Notificación Autoridad GDPR Art. 33 (<72h), RCA Post-Mortem (<5 días hábiles).
* **Topología BCDR:** Multi-AZ Activo-Activo y Multi-Región Warm Standby con replicación continua WAL y promoción automatizada verificando RPO < 5 minutos y RTO < 30 minutos.
