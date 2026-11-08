-- =============================================================================
-- LIBRO MAYOR DE FACTURACION Y CONCILIACION DE LICENCIAS COMERCIALES B2B
-- Cumplimiento: ASC 606 | SOX 404 | PCI-DSS v4.0.1 | Control INV-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.b2b_commercial_license_orders (
    order_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    customer_legal_name VARCHAR(256) NOT NULL,
    customer_tax_id VARCHAR(64) NOT NULL,
    customer_github_handle VARCHAR(128) NOT NULL,
    commercial_tier VARCHAR(64) NOT NULL CHECK (commercial_tier IN ('STARTUP_1490_USD', 'ENTERPRISE_4900_USD', 'WHITELABEL_14900_USD')),
    amount_paid_cents BIGINT NOT NULL CHECK (amount_paid_cents IN (149000, 490000, 1490000)),
    payment_channel VARCHAR(32) NOT NULL CHECK (payment_channel IN ('STRIPE_CHECKOUT', 'ACH_SWIFT_WIRE', 'GITHUB_SPONSORS')),
    payment_gateway_ref VARCHAR(128) NOT NULL UNIQUE,
    ed25519_license_cert_sha256 CHAR(64) NOT NULL,
    fulfilled_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE core.b2b_commercial_license_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.b2b_commercial_license_orders FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_b2b_orders ON core.b2b_commercial_license_orders
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT ON core.b2b_commercial_license_orders TO saas_app_runtime;

COMMIT;
