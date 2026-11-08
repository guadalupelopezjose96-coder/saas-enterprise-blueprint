# Sistema de Gestion de Inteligencia Artificial (AIMS) — ISO/IEC 42001:2023 & EU AI Act

- **Identificador de Control:** `ISO-42` (Integrado con `AIG-01` y `LLM-01`)
- **Alcance:** Gobernanza integral del ciclo de vida de inferencia IA multi-tenant, prevencion de alucinaciones contables y cero retencion de datos de entrenamiento (*Zero Data Retention*).

| Control ISO/IEC 42001:2023 | Requisito Estatutario | Implementacion Verificable en el Repositorio |
| :--- | :--- | :--- |
| **Anexo A.5 (Evaluacion de Impacto IA)** | Evaluar consecuencias sobre derechos fundamentales y exactitud financiera. | Clasificacion obligatoria en `ai_governance/01_eu_ai_act_audit_ledger.sql` (`MINIMAL`, `LIMITED`, `HIGH_RISK`). |
| **Anexo A.6 (Ciclo de Vida del Sistema IA)** | Garantizar robustez adversarial contra manipulacion de entradas. | Bloqueo determinista de *Prompt Injection* en `ai_governance/02_nist_ai_rmf_prompt_injection_guard.rego`. |
| **Anexo A.8 (Informacion para Interesados)** | Transparencia de version de modelo, proveedor y hashes de inferencia. | Registro inmutable SHA-256 de prompt/respuesta y *Human-in-the-Loop* (`chk_eu_ai_act_art14_hitl`). |
