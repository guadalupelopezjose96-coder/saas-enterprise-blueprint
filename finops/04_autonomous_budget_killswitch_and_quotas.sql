-- =============================================================================
-- FRENO AUTONOMO DE PRESUPUESTO FINOPS Y PROTECCION DENIAL-OF-WALLET (FKS-01)
-- Cumplimiento: FinOps Framework | ISO 27001 A.8.6 | SOC 2 A1.1 | Control FKS-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.tenant_budget_killswitch_quotas (
    quota_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE CASCADE,
    monthly_hard_cap_cents BIGINT NOT NULL CHECK (monthly_hard_cap_cents > 0),
    current_month_spend_cents BIGINT NOT NULL DEFAULT 0 CHECK (current_month_spend_cents >= 0),
    alert_threshold_80_triggered BOOLEAN NOT NULL DEFAULT FALSE,
    killswitch_circuit_breaker_tripped BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_hard_cap_denial_of_wallet_guard CHECK (
        current_month_spend_cents <= monthly_hard_cap_cents OR killswitch_circuit_breaker_tripped = TRUE
    )
);

ALTER TABLE core.tenant_budget_killswitch_quotas ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.tenant_budget_killswitch_quotas FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_budget_quotas ON core.tenant_budget_killswitch_quotas
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT, UPDATE ON core.tenant_budget_killswitch_quotas TO saas_app_runtime;

COMMIT;
