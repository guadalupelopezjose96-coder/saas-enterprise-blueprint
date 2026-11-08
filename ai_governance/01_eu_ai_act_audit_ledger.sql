-- =============================================================================
-- LEDGER CRIPTOGRÁFICO DE AUDITORÍA E INFERENCIA DE IA (EU AI ACT ART. 12 & 14)
-- Cumplimiento: ISO/IEC 42001:2023 | EU AI Act | Control AIG-01 | RLS Strict
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.ai_inference_audit_ledger (
    inference_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    model_provider VARCHAR(64) NOT NULL,
    model_version VARCHAR(64) NOT NULL,
    prompt_sha256 CHAR(64) NOT NULL,
    response_sha256 CHAR(64) NOT NULL,
    prompt_tokens INT NOT NULL CHECK (prompt_tokens >= 0),
    completion_tokens INT NOT NULL CHECK (completion_tokens >= 0),
    pii_redacted BOOLEAN NOT NULL DEFAULT TRUE CHECK (pii_redacted = TRUE),
    zero_data_retention_enforced BOOLEAN NOT NULL DEFAULT TRUE CHECK (zero_data_retention_enforced = TRUE),
    risk_classification VARCHAR(32) NOT NULL DEFAULT 'LIMITED_RISK' CHECK (risk_classification IN ('MINIMAL_RISK', 'LIMITED_RISK', 'HIGH_RISK')),
    human_oversight_verified BOOLEAN NOT NULL DEFAULT FALSE,
    reviewer_principal VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_eu_ai_act_art14_hitl CHECK (
        risk_classification <> 'HIGH_RISK' OR (human_oversight_verified = TRUE AND reviewer_principal IS NOT NULL)
    )
);

ALTER TABLE core.ai_inference_audit_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.ai_inference_audit_ledger FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_ai_ledger ON core.ai_inference_audit_ledger
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT ON core.ai_inference_audit_ledger TO saas_app_runtime;

COMMIT;
