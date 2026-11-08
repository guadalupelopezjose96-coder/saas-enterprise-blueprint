-- =============================================================================
-- BOVEDA HIPAA / HITECH (45 CFR 164.312 & 164.514 SAFE HARBOR) PARA DATOS ePHI
-- Cumplimiento: HIPAA Security Rule | HITECH Act | SOC 2 CC6.1 | Control HIP-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.hipaa_ephi_clinical_vault (
    record_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    baa_contract_signed BOOLEAN NOT NULL DEFAULT TRUE CHECK (baa_contract_signed = TRUE),
    safe_harbor_18_identifiers_stripped BOOLEAN NOT NULL DEFAULT TRUE CHECK (safe_harbor_18_identifiers_stripped = TRUE),
    encrypted_ephi_payload_kms BYTEA NOT NULL,
    kms_key_arn VARCHAR(256) NOT NULL,
    access_reason VARCHAR(64) NOT NULL CHECK (access_reason IN ('TREATMENT', 'PAYMENT', 'HEALTHCARE_OPERATIONS', 'BREAK_GLASS_EMERGENCY')),
    attending_clinician_npi VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE core.hipaa_ephi_clinical_vault ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.hipaa_ephi_clinical_vault FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_hipaa_vault ON core.hipaa_ephi_clinical_vault
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT ON core.hipaa_ephi_clinical_vault TO saas_app_runtime;

COMMIT;
