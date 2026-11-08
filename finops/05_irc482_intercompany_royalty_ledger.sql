-- =============================================================================
-- LIBRO MAYOR DE REGALIAS INTERCOMPANIA IRS IRC SECTION 482 & ASC 606 (ROY-01)
-- Titular IP: Standard 1979 Holdings, LLC / Jose Emanuel Guadalupe Lopez
-- Subsidiarias: Aura Technologies Operating, LLC (15% AGR) | Phonix Communications Operating, LLC (10% AGR)
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.irc482_intercompany_royalty_settlements (
    settlement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    ip_licensor_holding VARCHAR(128) NOT NULL DEFAULT 'Standard 1979 Holdings, LLC' CHECK (ip_licensor_holding = 'Standard 1979 Holdings, LLC'),
    operating_subsidiary VARCHAR(128) NOT NULL CHECK (operating_subsidiary IN ('Aura Technologies Operating, LLC', 'Phonix Communications Operating, LLC')),
    adjusted_gross_revenue_cents BIGINT NOT NULL CHECK (adjusted_gross_revenue_cents >= 0),
    irc482_royalty_rate_bps INTEGER NOT NULL CHECK (irc482_royalty_rate_bps IN (1000, 1500)),
    royalty_payable_to_holding_cents BIGINT NOT NULL CHECK (royalty_payable_to_holding_cents >= 0),
    settled_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_exact_irc482_royalty_math CHECK (
        royalty_payable_to_holding_cents = (adjusted_gross_revenue_cents * irc482_royalty_rate_bps) / 10000
    )
);

ALTER TABLE core.irc482_intercompany_royalty_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.irc482_intercompany_royalty_settlements FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_irc482_royalties ON core.irc482_intercompany_royalty_settlements
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT ON core.irc482_intercompany_royalty_settlements TO saas_app_runtime;

COMMIT;
