-- AI Solution Delivery Control Tower
-- Reconciliation checks: row-count and aggregate comparisons across layers
-- Writes results to audit.reconciliation_results
-- Nicholas Hidalgo | Portfolio Project | Synthetic Data

-- ── Layer-to-layer row count reconciliation ───────────────────────────────────
-- Each check compares raw vs staging (views) vs silver (views).
-- left = raw count, right = staging/silver count; difference should be 0.

-- dim_business_unit: raw vs staging
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'dim_business_unit: raw vs staging',
    (SELECT COUNT(*) FROM raw.dim_business_unit),
    (SELECT COUNT(*) FROM staging.stg_dim_business_unit),
    (SELECT COUNT(*) FROM raw.dim_business_unit) - (SELECT COUNT(*) FROM staging.stg_dim_business_unit),
    CASE WHEN (SELECT COUNT(*) FROM raw.dim_business_unit) = (SELECT COUNT(*) FROM staging.stg_dim_business_unit)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- dim_ai_use_case: raw vs staging
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'dim_ai_use_case: raw vs staging',
    (SELECT COUNT(*) FROM raw.dim_ai_use_case),
    (SELECT COUNT(*) FROM staging.stg_dim_ai_use_case),
    (SELECT COUNT(*) FROM raw.dim_ai_use_case) - (SELECT COUNT(*) FROM staging.stg_dim_ai_use_case),
    CASE WHEN (SELECT COUNT(*) FROM raw.dim_ai_use_case) = (SELECT COUNT(*) FROM staging.stg_dim_ai_use_case)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- dim_risk_tier: raw vs staging
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'dim_risk_tier: raw vs staging',
    (SELECT COUNT(*) FROM raw.dim_risk_tier),
    (SELECT COUNT(*) FROM staging.stg_dim_risk_tier),
    (SELECT COUNT(*) FROM raw.dim_risk_tier) - (SELECT COUNT(*) FROM staging.stg_dim_risk_tier),
    CASE WHEN (SELECT COUNT(*) FROM raw.dim_risk_tier) = (SELECT COUNT(*) FROM staging.stg_dim_risk_tier)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- dim_model: raw vs staging
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'dim_model: raw vs staging',
    (SELECT COUNT(*) FROM raw.dim_model),
    (SELECT COUNT(*) FROM staging.stg_dim_model),
    (SELECT COUNT(*) FROM raw.dim_model) - (SELECT COUNT(*) FROM staging.stg_dim_model),
    CASE WHEN (SELECT COUNT(*) FROM raw.dim_model) = (SELECT COUNT(*) FROM staging.stg_dim_model)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- dim_owner: raw vs staging
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'dim_owner: raw vs staging',
    (SELECT COUNT(*) FROM raw.dim_owner),
    (SELECT COUNT(*) FROM staging.stg_dim_owner),
    (SELECT COUNT(*) FROM raw.dim_owner) - (SELECT COUNT(*) FROM staging.stg_dim_owner),
    CASE WHEN (SELECT COUNT(*) FROM raw.dim_owner) = (SELECT COUNT(*) FROM staging.stg_dim_owner)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- fact_ai_delivery_stage: raw vs staging
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'fact_ai_delivery_stage: raw vs staging',
    (SELECT COUNT(*) FROM raw.fact_ai_delivery_stage),
    (SELECT COUNT(*) FROM staging.stg_fact_ai_delivery_stage),
    (SELECT COUNT(*) FROM raw.fact_ai_delivery_stage) - (SELECT COUNT(*) FROM staging.stg_fact_ai_delivery_stage),
    CASE WHEN (SELECT COUNT(*) FROM raw.fact_ai_delivery_stage) = (SELECT COUNT(*) FROM staging.stg_fact_ai_delivery_stage)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- fact_model_monitoring: raw vs staging
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'fact_model_monitoring: raw vs staging',
    (SELECT COUNT(*) FROM raw.fact_model_monitoring),
    (SELECT COUNT(*) FROM staging.stg_fact_model_monitoring),
    (SELECT COUNT(*) FROM raw.fact_model_monitoring) - (SELECT COUNT(*) FROM staging.stg_fact_model_monitoring),
    CASE WHEN (SELECT COUNT(*) FROM raw.fact_model_monitoring) = (SELECT COUNT(*) FROM staging.stg_fact_model_monitoring)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- fact_value_realization: raw vs staging
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'fact_value_realization: raw vs staging',
    (SELECT COUNT(*) FROM raw.fact_value_realization),
    (SELECT COUNT(*) FROM staging.stg_fact_value_realization),
    (SELECT COUNT(*) FROM raw.fact_value_realization) - (SELECT COUNT(*) FROM staging.stg_fact_value_realization),
    CASE WHEN (SELECT COUNT(*) FROM raw.fact_value_realization) = (SELECT COUNT(*) FROM staging.stg_fact_value_realization)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- fact_sla_breach: raw vs staging
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'fact_sla_breach: raw vs staging',
    (SELECT COUNT(*) FROM raw.fact_sla_breach),
    (SELECT COUNT(*) FROM staging.stg_fact_sla_breach),
    (SELECT COUNT(*) FROM raw.fact_sla_breach) - (SELECT COUNT(*) FROM staging.stg_fact_sla_breach),
    CASE WHEN (SELECT COUNT(*) FROM raw.fact_sla_breach) = (SELECT COUNT(*) FROM staging.stg_fact_sla_breach)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- fact_governance_review: raw vs staging
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'fact_governance_review: raw vs staging',
    (SELECT COUNT(*) FROM raw.fact_governance_review),
    (SELECT COUNT(*) FROM staging.stg_fact_governance_review),
    (SELECT COUNT(*) FROM raw.fact_governance_review) - (SELECT COUNT(*) FROM staging.stg_fact_governance_review),
    CASE WHEN (SELECT COUNT(*) FROM raw.fact_governance_review) = (SELECT COUNT(*) FROM staging.stg_fact_governance_review)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- ── Silver view coverage checks ───────────────────────────────────────────────
-- Every use case in staging should appear in v_portfolio_summary (1:1).

INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'v_portfolio_summary: row count matches dim_ai_use_case',
    (SELECT COUNT(*) FROM staging.stg_dim_ai_use_case),
    (SELECT COUNT(*) FROM silver.v_portfolio_summary),
    (SELECT COUNT(*) FROM staging.stg_dim_ai_use_case) - (SELECT COUNT(*) FROM silver.v_portfolio_summary),
    CASE WHEN (SELECT COUNT(*) FROM staging.stg_dim_ai_use_case) = (SELECT COUNT(*) FROM silver.v_portfolio_summary)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- v_executive_delivery: one row per business unit
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'v_executive_delivery: row count matches dim_business_unit',
    (SELECT COUNT(*) FROM staging.stg_dim_business_unit),
    (SELECT COUNT(*) FROM silver.v_executive_delivery),
    (SELECT COUNT(*) FROM staging.stg_dim_business_unit) - (SELECT COUNT(*) FROM silver.v_executive_delivery),
    CASE WHEN (SELECT COUNT(*) FROM staging.stg_dim_business_unit) = (SELECT COUNT(*) FROM silver.v_executive_delivery)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- v_governance_status: matches fact_governance_review
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'v_governance_status: row count matches fact_governance_review',
    (SELECT COUNT(*) FROM staging.stg_fact_governance_review),
    (SELECT COUNT(*) FROM silver.v_governance_status),
    (SELECT COUNT(*) FROM staging.stg_fact_governance_review) - (SELECT COUNT(*) FROM silver.v_governance_status),
    CASE WHEN (SELECT COUNT(*) FROM staging.stg_fact_governance_review) = (SELECT COUNT(*) FROM silver.v_governance_status)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- v_model_health: matches fact_model_monitoring
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'v_model_health: row count matches fact_model_monitoring',
    (SELECT COUNT(*) FROM staging.stg_fact_model_monitoring),
    (SELECT COUNT(*) FROM silver.v_model_health),
    (SELECT COUNT(*) FROM staging.stg_fact_model_monitoring) - (SELECT COUNT(*) FROM silver.v_model_health),
    CASE WHEN (SELECT COUNT(*) FROM staging.stg_fact_model_monitoring) = (SELECT COUNT(*) FROM silver.v_model_health)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- v_sla_compliance: matches fact_sla_breach
INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'v_sla_compliance: row count matches fact_sla_breach',
    (SELECT COUNT(*) FROM staging.stg_fact_sla_breach),
    (SELECT COUNT(*) FROM silver.v_sla_compliance),
    (SELECT COUNT(*) FROM staging.stg_fact_sla_breach) - (SELECT COUNT(*) FROM silver.v_sla_compliance),
    CASE WHEN (SELECT COUNT(*) FROM staging.stg_fact_sla_breach) = (SELECT COUNT(*) FROM silver.v_sla_compliance)
         THEN 'PASS' ELSE 'FAIL' END,
    NULL;

-- ── Aggregate reconciliation: SLA breach counts ───────────────────────────────
-- Total SLA breaches in fact_sla_breach must equal total is_sla_breached=TRUE
-- in fact_ai_delivery_stage.

INSERT INTO audit.reconciliation_results (check_name, left_count, right_count, difference, status, notes)
SELECT
    'SLA breach count: fact_sla_breach vs is_sla_breached flag in delivery stages',
    (SELECT COUNT(*) FROM raw.fact_sla_breach),
    (SELECT COUNT(*) FROM raw.fact_ai_delivery_stage WHERE is_sla_breached = TRUE),
    (SELECT COUNT(*) FROM raw.fact_sla_breach)
        - (SELECT COUNT(*) FROM raw.fact_ai_delivery_stage WHERE is_sla_breached = TRUE),
    CASE WHEN (SELECT COUNT(*) FROM raw.fact_sla_breach)
              = (SELECT COUNT(*) FROM raw.fact_ai_delivery_stage WHERE is_sla_breached = TRUE)
         THEN 'PASS' ELSE 'FAIL' END,
    'Mismatch indicates a breach record without a corresponding flagged stage, or vice versa';

-- ── Summary ───────────────────────────────────────────────────────────────────
SELECT
    status,
    COUNT(*)  AS check_count
FROM audit.reconciliation_results
WHERE check_timestamp >= NOW() - INTERVAL '10 minutes'
GROUP BY status
ORDER BY status;
