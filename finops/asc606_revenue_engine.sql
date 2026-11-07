-- =============================================================================
-- MOTOR FINOPS Y RECONOCIMIENTO CONTABLE DE INGRESOS (ASC 606 / IFRS 15)
-- Cumplimiento: Pilar 5 Financiero/Fiscal | Control FIN-01 | Conciliación O2C
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.deferred_revenue_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    order_form_id VARCHAR(64) NOT NULL,
    total_contract_cents BIGINT NOT NULL CHECK (total_contract_cents > 0),
    recognized_cents BIGINT NOT NULL DEFAULT 0 CHECK (recognized_cents >= 0),
    remaining_deferred_cents BIGINT NOT NULL CHECK (remaining_deferred_cents >= 0),
    service_start_date DATE NOT NULL,
    service_end_date DATE NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'FULLY_RECOGNIZED', 'TERMINATED_REFUNDED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_asc606_balance CHECK (recognized_cents + remaining_deferred_cents = total_contract_cents)
);

ALTER TABLE core.deferred_revenue_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.deferred_revenue_schedules FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_asc606 ON core.deferred_revenue_schedules
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT, UPDATE ON core.deferred_revenue_schedules TO saas_app_runtime;

COMMIT;
