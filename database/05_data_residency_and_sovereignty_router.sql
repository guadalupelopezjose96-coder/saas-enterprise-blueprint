-- =============================================================================
-- ENRUTADOR DE SOBERANIA Y RESIDENCIA DE DATOS (GDPR CAP. V / SCHREMS II / FINMA)
-- Garantiza confinamiento geografico estricto por jurisdiccion | Control SOV-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.tenant_data_sovereignty_policy (
    tenant_id UUID PRIMARY KEY REFERENCES core.tenants(tenant_id) ON DELETE CASCADE,
    sovereign_jurisdiction VARCHAR(32) NOT NULL CHECK (sovereign_jurisdiction IN ('EU_SOVEREIGN_FRANKFURT', 'US_FEDRAMP_EAST', 'CH_ZURICH_FINMA')),
    cross_border_transfer_allowed BOOLEAN NOT NULL DEFAULT FALSE CHECK (cross_border_transfer_allowed = FALSE),
    eu_scc_2021_914_signed BOOLEAN NOT NULL DEFAULT TRUE,
    dedicated_kms_hsm_region VARCHAR(32) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE core.tenant_data_sovereignty_policy ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.tenant_data_sovereignty_policy FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_sovereignty ON core.tenant_data_sovereignty_policy
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT, UPDATE ON core.tenant_data_sovereignty_policy TO saas_app_runtime;

COMMIT;
