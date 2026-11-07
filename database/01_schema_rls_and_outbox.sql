-- =============================================================================
-- ARQUITECTURA DE BASE DE DATOS MULTI-TENANT CON AISLAMIENTO ESTRICTO (RLS)
-- Cumplimiento: SOC 2 (CC6.1, PI1.1, C1.2) | ISO/IEC 27001:2022 (8.3, 8.10, 8.24)
-- =============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Rol de aplicación sin privilegios de superusuario ni bypass de RLS
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'saas_app_runtime') THEN
        CREATE ROLE saas_app_runtime NOINHERIT LOGIN PASSWORD 'CHANGE_VIA_VAULT_DYNAMIC_SECRET_ROTATION';
    END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS core;
GRANT USAGE ON SCHEMA core TO saas_app_runtime;

-- 2. Función de extracción segura del contexto criptográfico del Tenant
CREATE OR REPLACE FUNCTION core.current_tenant_id() RETURNS UUID AS $$
DECLARE
    v_tenant_id TEXT;
BEGIN
    v_tenant_id := current_setting('app.current_tenant_id', true);
    IF v_tenant_id IS NULL OR v_tenant_id = '' THEN
        RAISE EXCEPTION 'SECURITY_VIOLATION: Contexto app.current_tenant_id no establecido en la transacción (Control TEN-01)';
    END IF;
    RETURN v_tenant_id::UUID;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 3. Tabla Maestra de Inquilinos (Tenants) y Gestión de Claves BYOK / Crypto-Shredding
CREATE TABLE IF NOT EXISTS core.tenants (
    tenant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    legal_name VARCHAR(255) NOT NULL,
    tax_id_vies VARCHAR(64) NOT NULL,
    data_residency_region VARCHAR(32) NOT NULL CHECK (data_residency_region IN ('eu-central-1', 'us-east-1')),
    kms_key_arn VARCHAR(512) NOT NULL,
    byok_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    crypto_shredded_at TIMESTAMPTZ NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'PORTABILITY_TRANSITION', 'CRYPTO_SHREDDED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

-- 4. Tabla de Registro de Aceptación Contractual Inmutable (Control GOV / MSA)
CREATE TABLE IF NOT EXISTS core.contract_acceptances (
    acceptance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    document_type VARCHAR(32) NOT NULL CHECK (document_type IN ('MSA', 'DPA', 'SLA', 'ORDER_FORM')),
    document_version VARCHAR(32) NOT NULL,
    document_sha256_hash CHAR(64) NOT NULL,
    signatory_email VARCHAR(255) NOT NULL,
    signatory_ip INET NOT NULL,
    accepted_at_utc TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

-- 5. Tabla Transaccional Principal Multi-Tenant con Control de Idempotencia
CREATE TABLE IF NOT EXISTS core.ledger_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE CASCADE,
    idempotency_key VARCHAR(128) NOT NULL,
    operation_type VARCHAR(64) NOT NULL,
    amount_cents BIGINT NOT NULL CHECK (amount_cents >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    encrypted_payload BYTEA NOT NULL,
    payload_key_version INTEGER NOT NULL DEFAULT 1,
    created_by_user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_tenant_idempotency UNIQUE (tenant_id, idempotency_key)
);

-- 6. Tabla de Patrón Transactional Outbox (Despacho Garantizado de Eventos - Control INT-01)
CREATE TABLE IF NOT EXISTS core.transactional_outbox (
    event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE CASCADE,
    aggregate_type VARCHAR(64) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(128) NOT NULL,
    payload JSONB NOT NULL,
    dispatched BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    dispatched_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_outbox_undispatched ON core.transactional_outbox (created_at) WHERE dispatched = FALSE;

-- 7. Tabla de Medición Determinista para Facturación Basada en Uso (ASC 606 / Usage-Based Billing)
CREATE TABLE IF NOT EXISTS core.usage_metering_events (
    metering_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE CASCADE,
    idempotency_key VARCHAR(128) NOT NULL,
    metric_code VARCHAR(64) NOT NULL,
    quantity NUMERIC(20, 6) NOT NULL CHECK (quantity > 0),
    recorded_at_utc TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_metering_idempotency UNIQUE (tenant_id, idempotency_key)
);

-- =============================================================================
-- ACTIVACIÓN Y FORZADO ESTRICTO DE ROW-LEVEL SECURITY (RLS)
-- =============================================================================

ALTER TABLE core.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.tenants FORCE ROW LEVEL SECURITY;

ALTER TABLE core.contract_acceptances ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.contract_acceptances FORCE ROW LEVEL SECURITY;

ALTER TABLE core.ledger_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.ledger_transactions FORCE ROW LEVEL SECURITY;

ALTER TABLE core.transactional_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.transactional_outbox FORCE ROW LEVEL SECURITY;

ALTER TABLE core.usage_metering_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.usage_metering_events FORCE ROW LEVEL SECURITY;

-- Políticas de Aislamiento: un Tenant jamás puede leer ni escribir filas de otro Tenant
CREATE POLICY tenant_isolation_policy_tenants ON core.tenants
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id() AND status != 'CRYPTO_SHREDDED')
    WITH CHECK (tenant_id = core.current_tenant_id());

CREATE POLICY tenant_isolation_policy_contracts ON core.contract_acceptances
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

CREATE POLICY tenant_isolation_policy_ledger ON core.ledger_transactions
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

CREATE POLICY tenant_isolation_policy_outbox ON core.transactional_outbox
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

CREATE POLICY tenant_isolation_policy_metering ON core.usage_metering_events
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

-- Permisos Mínimos para el Rol de Aplicación (Sin permisos de DROP ni TRUNCATE)
GRANT SELECT, INSERT, UPDATE ON core.tenants TO saas_app_runtime;
GRANT SELECT, INSERT ON core.contract_acceptances TO saas_app_runtime;
GRANT SELECT, INSERT ON core.ledger_transactions TO saas_app_runtime;
GRANT SELECT, INSERT, UPDATE ON core.transactional_outbox TO saas_app_runtime;
GRANT SELECT, INSERT ON core.usage_metering_events TO saas_app_runtime;

-- =============================================================================
-- PROCEDIMIENTO DE BORRADO CRIPTOGRÁFICO Y PURGA EN CASCADA (CLÁUSULA 9.3 MSA)
-- =============================================================================

CREATE OR REPLACE FUNCTION core.execute_tenant_crypto_shredding(
    p_tenant_id UUID,
    p_kms_destruction_receipt VARCHAR(512)
) RETURNS JSONB AS $$
DECLARE
    v_deleted_tx BIGINT;
    v_deleted_metering BIGINT;
    v_certificate JSONB;
BEGIN
    -- 1. Purgar cargas útiles cifradas y registros operativos
    DELETE FROM core.ledger_transactions WHERE tenant_id = p_tenant_id;
    GET DIAGNOSTICS v_deleted_tx = ROW_COUNT;

    DELETE FROM core.transactional_outbox WHERE tenant_id = p_tenant_id;

    DELETE FROM core.usage_metering_events WHERE tenant_id = p_tenant_id;
    GET DIAGNOSTICS v_deleted_metering = ROW_COUNT;

    -- 2. Marcar Tenant como destruido criptográficamente e invalidar referencia KMS
    UPDATE core.tenants
    SET kms_key_arn = 'SHREDDED::' || p_kms_destruction_receipt,
        status = 'CRYPTO_SHREDDED',
        crypto_shredded_at = clock_timestamp(),
        updated_at = clock_timestamp()
    WHERE tenant_id = p_tenant_id;

    -- 3. Emitir Certificado de Destrucción Auditable (Control PRI-01 / ISO 8.10)
    v_certificate := jsonb_build_object(
        'certificate_type', 'NIST_SP_800_88_CRYPTO_SHREDDING',
        'tenant_id', p_tenant_id,
        'kms_destruction_receipt', p_kms_destruction_receipt,
        'purged_ledger_rows', v_deleted_tx,
        'purged_metering_rows', v_deleted_metering,
        'executed_at_utc', clock_timestamp()
    );

    RETURN v_certificate;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
