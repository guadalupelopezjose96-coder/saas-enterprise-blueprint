-- =============================================================================
-- LEDGER FINOPS FOCUS 1.0 (UNIT ECONOMICS) Y HUELLA DE CARBONO ESG (UE CSRD)
-- Cumplimiento: FinOps FOCUS 1.0 | Directiva UE CSRD (GHG Scope 2/3) | FOC-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.focus_cost_and_carbon_ledger (
    record_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    focus_service_category VARCHAR(64) NOT NULL CHECK (focus_service_category IN ('COMPUTE', 'STORAGE', 'DATABASE', 'AI_INFERENCE', 'NETWORK')),
    billed_cost_micros BIGINT NOT NULL CHECK (billed_cost_micros >= 0),
    effective_cost_micros BIGINT NOT NULL CHECK (effective_cost_micros >= 0),
    carbon_emissions_grams_co2e NUMERIC(12, 4) NOT NULL CHECK (carbon_emissions_grams_co2e >= 0),
    renewable_energy_pct NUMERIC(5, 2) NOT NULL DEFAULT 100.00 CHECK (renewable_energy_pct BETWEEN 0.00 AND 100.00),
    ghg_protocol_scope VARCHAR(16) NOT NULL DEFAULT 'SCOPE_3' CHECK (ghg_protocol_scope IN ('SCOPE_2', 'SCOPE_3')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE core.focus_cost_and_carbon_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.focus_cost_and_carbon_ledger FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_focus_ledger ON core.focus_cost_and_carbon_ledger
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT ON core.focus_cost_and_carbon_ledger TO saas_app_runtime;

COMMIT;
