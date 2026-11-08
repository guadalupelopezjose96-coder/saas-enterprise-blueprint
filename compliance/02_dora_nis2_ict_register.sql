-- =============================================================================
-- REGISTRO DE PROVEEDORES TIC CRITICOS Y ESTRATEGIA DE SALIDA (DORA UE 2022/2554)
-- Cumplimiento: DORA Art. 28 & 30 | Directiva NIS2 Art. 21 | Control DOR-01
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS core.dora_ict_subprocessor_register (
    provider_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_legal_name VARCHAR(128) NOT NULL,
    ict_service_category VARCHAR(64) NOT NULL,
    primary_region VARCHAR(32) NOT NULL,
    failover_region VARCHAR(32) NOT NULL,
    certification_posture VARCHAR(128) NOT NULL,
    rto_minutes INT NOT NULL CHECK (rto_minutes <= 30),
    rpo_minutes INT NOT NULL CHECK (rpo_minutes <= 5),
    substitutability_rating VARCHAR(32) NOT NULL CHECK (substitutability_rating IN ('EASILY_SUBSTITUTABLE', 'MODERATE_COMPLEXITY')),
    documented_exit_plan_uri VARCHAR(256) NOT NULL,
    last_tlpt_penetration_test DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

GRANT SELECT ON core.dora_ict_subprocessor_register TO saas_app_runtime;

COMMIT;
