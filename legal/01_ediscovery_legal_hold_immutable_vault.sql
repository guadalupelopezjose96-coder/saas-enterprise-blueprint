-- =============================================================================
-- MOTOR DE RETENCION JUDICIAL INMUTABLE (LEGAL HOLD / FRCP RULE 37(e) & GDPR 17.3)
-- Previene destruccion de evidencia durante litigios o auditorias regulatorias
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.regulatory_legal_holds (
    hold_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(tenant_id) ON DELETE RESTRICT,
    matter_reference_code VARCHAR(128) NOT NULL,
    issuing_authority VARCHAR(128) NOT NULL,
    legal_hold_active BOOLEAN NOT NULL DEFAULT TRUE,
    issued_by_general_counsel VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE OR REPLACE FUNCTION core.prevent_deletion_under_legal_hold()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.legal_hold_active = TRUE THEN
        RAISE EXCEPTION 'BLOQUEO ESTATUTARIO LGH-01 (FRCP Rule 37e): Prohibido eliminar registros bajo Legal Hold activo (%).', OLD.matter_reference_code;
    END IF;
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_legal_hold_immutability ON core.regulatory_legal_holds;
CREATE TRIGGER trg_enforce_legal_hold_immutability
    BEFORE DELETE ON core.regulatory_legal_holds
    FOR EACH ROW EXECUTE FUNCTION core.prevent_deletion_under_legal_hold();

ALTER TABLE core.regulatory_legal_holds ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.regulatory_legal_holds FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_legal_holds ON core.regulatory_legal_holds
    AS RESTRICTIVE
    FOR ALL
    TO saas_app_runtime
    USING (tenant_id = core.current_tenant_id())
    WITH CHECK (tenant_id = core.current_tenant_id());

GRANT SELECT, INSERT ON core.regulatory_legal_holds TO saas_app_runtime;

COMMIT;
