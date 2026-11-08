-- =============================================================================
-- MOTOR GOOGLE CLOUD MARKETPLACE (SSO/JWT), PLAY INTEGRITY API Y PLAY RTDN PUSH
-- Ecosistema: Fourphonix / AuraIntelCore (gcp-marketplace-saas v1.0.0) | GCP-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.gcp_marketplace_and_play_entitlements (
    entitlement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    subsidiary_domain VARCHAR(64) NOT NULL CHECK (subsidiary_domain IN ('AuraIntelCore.com', 'AuraTetrax.com', 'AuraIntelStudios3D.com', 'fourphonix.com', 'prophonix.com', 'standard1979.com')),
    channel_source VARCHAR(32) NOT NULL CHECK (channel_source IN ('GCP_MARKETPLACE_JWT', 'GOOGLE_PLAY_RTDN_OIDC', 'STRIPE_AUTOMATIC_TAX')),
    external_procurement_account_id VARCHAR(128) NOT NULL UNIQUE,
    play_integrity_device_verdict VARCHAR(64) NOT NULL DEFAULT 'MEETS_STRONG_INTEGRITY' CHECK (play_integrity_device_verdict IN ('MEETS_STRONG_INTEGRITY', 'MEETS_DEVICE_INTEGRITY')),
    x_gcp_marketplace_token_sha256 CHAR(64) NOT NULL,
    metered_billing_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE core.gcp_marketplace_and_play_entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.gcp_marketplace_and_play_entitlements FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_gcp_play ON core.gcp_marketplace_and_play_entitlements
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT, UPDATE ON core.gcp_marketplace_and_play_entitlements TO saas_app_runtime;

COMMIT;
