-- =============================================================================
-- MOTOR DE CUMPLIMIENTO DE CONTROL DE EXPORTACIONES (EAR ECCN 5D002) Y OFAC
-- Cumplimiento: 15 CFR Part 740.17 (ENC) | OFAC SDN List | EU Sanctions | EXP-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.export_control_and_sanctions_ledger (
    screening_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    country_iso_alpha2 CHAR(2) NOT NULL,
    eccn_classification VARCHAR(16) NOT NULL DEFAULT '5D002.c.1' CHECK (eccn_classification = '5D002.c.1'),
    license_exception_applied VARCHAR(32) NOT NULL DEFAULT 'EAR_740_17_ENC_UNRESTRICTED',
    ofac_sdn_clear BOOLEAN NOT NULL DEFAULT TRUE CHECK (ofac_sdn_clear = TRUE),
    eu_uk_un_sanctions_clear BOOLEAN NOT NULL DEFAULT TRUE CHECK (eu_uk_un_sanctions_clear = TRUE),
    screened_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_prohibited_embargoed_jurisdictions CHECK (
        country_iso_alpha2 NOT IN ('CU', 'IR', 'KP', 'SY', 'RU', 'BY')
    )
);

ALTER TABLE core.export_control_and_sanctions_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.export_control_and_sanctions_ledger FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_export_control ON core.export_control_and_sanctions_ledger
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT ON core.export_control_and_sanctions_ledger TO saas_app_runtime;

COMMIT;
