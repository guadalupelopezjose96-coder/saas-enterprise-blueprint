-- =============================================================================
-- REGISTRO DMA/GDPR GOOGLE CONSENT MODE V2 (TCF V2.2) Y PLAY ACCOUNT DELETION
-- Endpoints: POST /compliance/google-consent-mode | POST /legal/account-deletion
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.google_consent_and_play_deletion_ledger (
    record_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE CASCADE,
    event_type VARCHAR(32) NOT NULL CHECK (event_type IN ('CONSENT_MODE_V2_SIGNAL', 'GOOGLE_PLAY_ACCOUNT_DELETION_TICKET')),
    tcf_v2_2_consent_string VARCHAR(256) NOT NULL,
    ad_storage_granted BOOLEAN NOT NULL DEFAULT FALSE,
    analytics_storage_granted BOOLEAN NOT NULL DEFAULT FALSE,
    ad_user_data_granted BOOLEAN NOT NULL DEFAULT FALSE,
    ad_personalization_granted BOOLEAN NOT NULL DEFAULT FALSE,
    deletion_crypto_shredding_completed BOOLEAN NOT NULL DEFAULT TRUE,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE core.google_consent_and_play_deletion_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.google_consent_and_play_deletion_ledger FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_consent_play ON core.google_consent_and_play_deletion_ledger
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT ON core.google_consent_and_play_deletion_ledger TO saas_app_runtime;

COMMIT;
