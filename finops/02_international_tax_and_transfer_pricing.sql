-- =============================================================================
-- MOTOR FISCAL INTERNACIONAL: IVA B2B REVERSE CHARGE, US NEXUS Y OCDE BEPS
-- Cumplimiento: Directiva IVA UE 2006/112/CE Art. 196 | OCDE BEPS | Control TAX-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.international_tax_ledger (
    tax_record_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    invoice_id UUID NOT NULL,
    customer_jurisdiction CHAR(2) NOT NULL,
    customer_tax_id_verified BOOLEAN NOT NULL DEFAULT TRUE,
    tax_regime VARCHAR(32) NOT NULL CHECK (tax_regime IN ('EU_VAT_REVERSE_CHARGE_ART196', 'US_ECONOMIC_NEXUS_SALES_TAX', 'EXPORT_ZERO_RATED')),
    net_amount_cents BIGINT NOT NULL CHECK (net_amount_cents > 0),
    tax_rate_bps INT NOT NULL CHECK (tax_rate_bps >= 0 AND tax_rate_bps <= 5000),
    tax_amount_cents BIGINT NOT NULL CHECK (tax_amount_cents >= 0),
    oecd_arms_length_royalty_bps INT NOT NULL DEFAULT 1500 CHECK (oecd_arms_length_royalty_bps BETWEEN 0 AND 3000),
    withholding_tax_article VARCHAR(32) NOT NULL DEFAULT 'OECD_MODEL_ART_12_ROYALTIES',
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_reverse_charge_zero_tax CHECK (
        tax_regime <> 'EU_VAT_REVERSE_CHARGE_ART196' OR (customer_tax_id_verified = TRUE AND tax_amount_cents = 0)
    )
);

ALTER TABLE core.international_tax_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.international_tax_ledger FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_tax_ledger ON core.international_tax_ledger
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT ON core.international_tax_ledger TO saas_app_runtime;

COMMIT;
