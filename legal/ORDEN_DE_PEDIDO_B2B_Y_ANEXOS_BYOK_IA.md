# ORDEN DE PEDIDO COMERCIAL B2B (ORDER FORM) Y ANEXOS ESPECIALES (BYOK & IA)

**Identificador de Orden de Pedido:** `OF-2026-ENT-00948`
**Contrato Rector Vinculado:** Contrato Maestro de Suscripción (`MSA`), Anexo de Procesamiento de Datos (`DPA`) y Acuerdo de Nivel de Servicio (`SLA`).

---

## 1. IDENTIFICACIÓN DE LAS PARTES Y METADATOS FISCALES

| Campo | Datos del Proveedor SaaS | Datos del Cliente Corporativo |
| :--- | :--- | :--- |
| **Razón Social** | `[Nombre Legal del Proveedor SaaS]` | `[Nombre Legal del Cliente]` |
| **Jurisdicción y NIF / VIES / EIN** | `[NIF/EIN del Proveedor]` | `[Número IVA VIES / EIN Validado]` |
| **Dirección Fiscal** | `[Dirección Completa]` | `[Dirección Completa]` |
| **Región Soberana de Datos (Geo-Fencing)** | N/A | `[X] Unión Europea (eu-central-1 / eu-west-1)` / `[ ] EE. UU. (us-east-1 / us-west-2)` |
| **Régimen de Impuestos Indirectos** | Liquidación Directa / Motor Fiscal | `[X] Inversión del Sujeto Pasivo B2B (Reverse Charge 0% IVA)` / `[ ] Sales Tax Según Nexo` |

---

## 2. ESTRUCTURA DE SUSCRIPCIÓN Y PRECIOS HÍBRIDOS (CUMPLIMIENTO ASC 606 / IFRS 15)

* **Fecha de Inicio del Servicio:** `[YYYY-MM-DD]` | **Fecha de Fin del Plazo Inicial:** `[YYYY-MM-DD]` (36 Meses).
* **Periodicidad de Facturación Base:** Anual por adelantado (Reconocimiento contable lineal mensual desde cuenta de Ingresos Diferidos).
* **Periodicidad de Facturación por Consumo Excedente (*Usage-Based*):** Mensual a mes vencido según medición determinista de la tabla `core.usage_metering_events`.

| Código SKU | Descripción de la Obligación de Desempeño | Métrica / Cuota Incluida | Precio Unitario / Anual | Total Anual Comprometido |
| :--- | :--- | :--- | :--- | :--- |
| `SAAS-ENT-CORE` | Plataforma Enterprise Multi-Tenant (SLA 99.95%, SSO/SCIM, RLS, RPO 5m / RTO 30m) | Hasta 250 Usuarios Autorizados | $120,000.00 USD / año | $120,000.00 USD |
| `SAAS-ADD-BYOK` | Módulo Criptográfico Soberano *Bring Your Own Key* (HSM FIPS 140-3 Dual-Region) | 1 Tenant Corporativo | $18,000.00 USD / año | $18,000.00 USD |
| `SAAS-ADD-AI` | Módulo de Inferencia de IA Empresarial Aislada (Cero entrenamiento externo) | 10,000,000 Tokens / mes incluidos | $24,000.00 USD / año | $24,000.00 USD |
| `SAAS-USG-API` | Llamadas API Transaccionales Excedentes (Medición Idempotente) | Sobre 5,000,000 llamadas / mes | $0.45 USD por cada 1,000 llamadas | *Según consumo medido* |
| `SAAS-USG-TOK` | Tokens de Inferencia de IA Excedentes | Sobre 10,000,000 Tokens / mes | $2.50 USD por cada 1,000,000 Tokens | *Según consumo medido* |
| **TOTAL ANUAL BASE** | **(Excluyendo impuestos indirectos y consumos variables excedentes)** | | | **$162,000.00 USD** |

* **Límite de Gasto Variable Configurable (*Hard / Soft Spend Cap*):** El Cliente establece un límite de alerta (*Soft Cap*) del consumo mensual variable en `$5,000.00 USD` y un límite de bloqueo preventivo (*Hard Cap*) en `$10,000.00 USD`, modificable en tiempo real por el administrador del Cliente en la consola FinOps del SaaS.

---

## 3. ANEXO ESPECIAL A: GOBERNANZA CRIPTOGRÁFICA "BRING YOUR OWN KEY" (BYOK)

1. **Arquitectura de Custodia Soberana:** El Cliente proporcionará al Proveedor el identificador de recurso (**ARN / URI**) de su clave maestra alojada en su propio servicio de gestión de claves (**AWS KMS / GCP Cloud KMS HSM FIPS 140-3 Nivel 3**) tanto en la Región Primaria como en la Región Secundaria de contingencia BCDR dentro de la misma jurisdicción elegida.
2. **Efecto de la Revocación Criptográfica (*Kill-Switch Soberano*):** El Cliente puede suspender o revocar el permiso de desencriptación del Proveedor sobre su clave KMS en cualquier instante. En el momento en que el Cliente revoque dicho permiso:
   * Todas las cargas útiles (`encrypted_payload`) y copias de seguridad del Cliente quedarán matemáticamente ilegibles para el Proveedor en menos de cinco (5) minutos (tiempo de expiración de la caché de claves de datos en memoria *Data Key Caching*).
   * Cualquier interrupción del servicio o error `HTTP 5xx` derivado de la revocación, eliminación o mala configuración de la clave KMS por parte del Cliente quedará **expresamente excluido del cómputo de disponibilidad del SLA** (conforme a la Sección 3.2 del Anexo SLA) y eximirá al Proveedor de toda responsabilidad operativa.

---

## 4. ANEXO ESPECIAL B: GOBERNANZA DE INTELIGENCIA ARTIFICIAL (CUMPLIMIENTO EU AI ACT)

1. **Garantía de Cero Entrenamiento (*Zero Data Retention & Zero Training Guarantee*):** El Proveedor garantiza técnica y contractualmente que ni las entradas (*Prompts / Inputs*), ni los Datos del Cliente, ni las salidas (*Outputs*) procesadas por los módulos de Inteligencia Artificial serán utilizados para entrenar, reentrenar o mejorar modelos fundacionales propios o de terceros. Las inferencias se ejecutan a través de puntos de enlace empresariales privados sin retención de registros por parte del proveedor del modelo subyacente.
2. **Transparencia y Supervisión Humana (Art. 14 y Art. 50 EU AI Act):**
   * El sistema etiqueta automáticamente en sus metadatos API todo contenido generado o sintetizado mediante Inteligencia Artificial.
   * Si el Cliente utiliza la Plataforma SaaS para casos de uso clasificados como de **Alto Riesgo** según el Anexo III del Reglamento (UE) 2024/1689 (**EU AI Act**) —tales como selección de personal, evaluación crediticia o infraestructuras críticas—, el Cliente se obliga a mantener activa la bandera de configuración `require_human_in_the_loop_approval = true`, asegurando que ninguna decisión automatizada produzca efectos jurídicos sobre personas físicas sin la validación previa de un operador humano competente del Cliente.
3. **Indemnización de Propiedad Intelectual sobre Outputs de IA:** Sujeto a que el Cliente no desactive los filtros de seguridad de derechos de autor (*Copyright Shields*) integrados en la Plataforma, la indemnización de Propiedad Intelectual del Proveedor (Cláusula 7.2 del MSA) se extiende a los resultados generados por los módulos de IA del SaaS.

---

**FIRMAS ELECTRÓNICAS DE EJECUCIÓN DE LA ORDEN DE PEDIDO:**

* **POR EL PROVEEDOR:** `___________________________` | Cargo: `VP of Global Sales / Legal` | Fecha UTC: `[Fecha]`
* **POR EL CLIENTE:** `___________________________` | Cargo: `CIO / CFO / Representante Legal` | Fecha UTC: `[Fecha]`
