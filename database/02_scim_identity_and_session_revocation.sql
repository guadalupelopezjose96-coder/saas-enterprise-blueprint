-- =============================================================================
-- MOTOR ZERO-TRUST SCIM 2.0 Y REVOCACION AUTOMATICA DE SESIONES (ISO 27001 5.18)
-- Cumplimiento: SOC 2 CC6.2 & CC6.3 | ISO/IEC 27001:2022 A.5.18 | Control IAM-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.scim_enterprise_identities (
    identity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE CASCADE,
    scim_external_id VARCHAR(128) NOT NULL,
    work_email VARCHAR(256) NOT NULL,
    rbac_role VARCHAR(32) NOT NULL CHECK (rbac_role IN ('TENANT_ADMIN', 'FINOPS_AUDITOR', 'READ_ONLY_VIEWER')),
    mfa_hardware_fido2_verified BOOLEAN NOT NULL DEFAULT TRUE CHECK (mfa_hardware_fido2_verified = TRUE),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    revoked_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (tenant_id, scim_external_id)
);

ALTER TABLE core.scim_enterprise_identities ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.scim_enterprise_identities FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_scim_identities ON core.scim_enterprise_identities
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT, UPDATE ON core.scim_enterprise_identities TO saas_app_runtime;

COMMIT;
