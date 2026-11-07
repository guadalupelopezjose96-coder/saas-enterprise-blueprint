# PAQUETE CONTRACTUAL MAESTRO SAAS B2B (MSA + DPA + SLA)
**Identificador Documental:** `LEGAL-MSA-DPA-SLA-2026-V4.0`

## PARTE I: CONTRATO MAESTRO DE SUSCRIPCIÓN (MSA)
1. **Naturaleza del Servicio (No Licencia de Copia):** Otorgamiento de derecho de acceso y uso remoto limitado, no exclusivo, intransferible, no sublicenciable y revocable. No aplica doctrina de agotamiento (*First Sale Doctrine*).
2. **Política de Uso Aceptable (AUP):** Prohibición de ingeniería inversa, evasión de aislamiento Multi-Tenant Row-Level Security (RLS), pentesting no autorizado y entrenamiento de modelos de IA competidores.
3. **Régimen Financiero y Tributario (ASC 606 / IFRS 15):** Reconocimiento lineal de ingresos diferidos. Pagos vía pasarela PCI-DSS Nivel 1 (SAQ-A / 3DS2). Impuestos indirectos por Inversión del Sujeto Pasivo B2B (VIES) o Sales Tax por Nexo Económico. Cláusula de Gross-Up obligatoria ante retenciones en la fuente (WHT).
4. **Limitación de Responsabilidad (LoL):** Exclusión de daños indirectos y lucro cesante. Tope General (*General Cap*) de 12 meses de tarifas pagadas; Tope Incrementado (*Super Cap*) de 3x para brechas de DPA o confidencialidad.
5. **Portabilidad (EU Data Act) y Borrado Criptográfico:** 30 días de transición con exportación gratuita en JSON/Parquet/CSV sin cargos por cambio de proveedor, seguido de destrucción irreversible mediante Crypto-Shredding (NIST SP 800-88).

## PARTE II: ANEXO DE PROCESAMIENTO DE DATOS (DPA - GDPR Art. 28 / CCPA)
1. **Roles:** Cliente como Responsable del Tratamiento (*Controller*); Proveedor como Encargado del Tratamiento (*Processor*). Prohibición absoluta de venta o uso secundario de datos personales.
2. **Medidas Técnicas y Organizativas (TOMs):** TLS 1.3, mTLS interno, AES-256-GCM en HSM FIPS 140-3 Nivel 3 con soporte BYOK, IAM con FIDO2/WebAuthn y política Zero Standing Privileges (ZSP) con elevación Just-In-Time (JIT).
3. **Subencargados y Transferencias Internacionales:** Preaviso obligatorio de 30 días para nuevos subencargados. Transferencias amparadas por el EU-U.S. Data Privacy Framework (DPF) y Cláusulas Contractuales Tipo (SCCs Módulo 2 y 3).
4. **Notificación de Brechas de Seguridad:** Plazo máximo vinculante de 36 horas desde la confirmación del incidente.

## PARTE III: ACUERDO DE NIVEL DE SERVICIO (SLA - SRE)
1. **Compromiso de Disponibilidad Mensual:** >= 99.95% medido en el API Gateway.
2. **Objetivos BCDR y Rendimiento:** Latencia p99 < 300 ms; RPO < 5 minutos; RTO < 30 minutos.
3. **Tiempos de Respuesta CSIRT/SRE:** P1 < 15 min (24x7); P2 < 1 hora; entrega de Blameless Post-Mortem (RCA) definitivo en <= 5 días hábiles.
4. **Créditos de Servicio y Fallo Crónico:** Escala del 10% al 100% de la cuota mensual. Derecho de resolución inmediata con reembolso íntegro si la disponibilidad cae bajo 99.00% durante 3 meses consecutivos.
