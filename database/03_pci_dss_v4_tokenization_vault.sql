-- =============================================================================
-- BOVEDA DE TOKENIZACION PCI-DSS v4.0.1 (REQ. 3.3 & 3.5.1) CON BLOQUEO DE PAN
-- Cumplimiento: PCI-DSS v4.0.1 | SOC 2 CC6.1 | ISO 27001 A.8.11 | Control PCI-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.pci_dss_payment_tokens (
    token_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    psp_vault_token VARCHAR(128) NOT NULL UNIQUE,
    pan_hmac_sha256 CHAR(64) NOT NULL,
    card_last_four CHAR(4) NOT NULL CHECK (card_last_four ~ '^[0-9]{4}$'),
    card_brand VARCHAR(24) NOT NULL CHECK (card_brand IN ('VISA', 'MASTERCARD', 'AMEX', 'SEPA_DIRECT_DEBIT')),
    expiry_month SMALLINT NOT NULL CHECK (expiry_month BETWEEN 1 AND 12),
    expiry_year SMALLINT NOT NULL CHECK (expiry_year >= 2026),
    cvv_stored BOOLEAN NOT NULL DEFAULT FALSE CHECK (cvv_stored = FALSE),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_pci_dss_no_raw_pan_in_token CHECK (psp_vault_token !~ '^[0-9]{13,19}$')
);

ALTER TABLE core.pci_dss_payment_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.pci_dss_payment_tokens FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_pci_tokens ON core.pci_dss_payment_tokens
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT ON core.pci_dss_payment_tokens TO saas_app_runtime;

COMMIT;
