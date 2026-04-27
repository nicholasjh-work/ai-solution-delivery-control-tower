-- AI Solution Delivery Control Tower
-- Data quality checks: writes results to audit.dq_check_results
-- Run after each load; expected to pass on clean seed data.
-- Nicholas Hidalgo | Portfolio Project | Synthetic Data

-- ── Helper: insert one DQ result row ─────────────────────────────────────────
-- Each check follows the pattern:
--   INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
--   SELECT ..., CASE WHEN <condition> THEN 'PASS' ELSE 'FAIL' END, ...

-- ── 1. Null checks on required dimension columns ──────────────────────────────

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_business_unit: no null unit_code'                  AS check_name,
    CASE WHEN COUNT(*) FILTER (WHERE unit_code IS NULL) = 0
         THEN 'PASS' ELSE 'FAIL' END                        AS status,
    '0 nulls'                                               AS expected,
    COUNT(*) FILTER (WHERE unit_code IS NULL)::TEXT || ' nulls' AS actual,
    'Error'                                                 AS severity,
    NULL                                                    AS notes
FROM raw.dim_business_unit;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_ai_use_case: no null use_case_code',
    CASE WHEN COUNT(*) FILTER (WHERE use_case_code IS NULL) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    '0 nulls',
    COUNT(*) FILTER (WHERE use_case_code IS NULL)::TEXT || ' nulls',
    'Error', NULL
FROM raw.dim_ai_use_case;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_model: no null model_code',
    CASE WHEN COUNT(*) FILTER (WHERE model_code IS NULL) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    '0 nulls',
    COUNT(*) FILTER (WHERE model_code IS NULL)::TEXT || ' nulls',
    'Error', NULL
FROM raw.dim_model;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_owner: no null owner_name',
    CASE WHEN COUNT(*) FILTER (WHERE owner_name IS NULL) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    '0 nulls',
    COUNT(*) FILTER (WHERE owner_name IS NULL)::TEXT || ' nulls',
    'Error', NULL
FROM raw.dim_owner;

-- ── 2. Uniqueness checks ──────────────────────────────────────────────────────

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_business_unit: unit_code is unique',
    CASE WHEN COUNT(*) = COUNT(DISTINCT unit_code)
         THEN 'PASS' ELSE 'FAIL' END,
    'No duplicates',
    CASE WHEN COUNT(*) = COUNT(DISTINCT unit_code)
         THEN 'OK'
         ELSE (COUNT(*) - COUNT(DISTINCT unit_code))::TEXT || ' duplicate(s)' END,
    'Error', NULL
FROM raw.dim_business_unit;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_ai_use_case: use_case_code is unique',
    CASE WHEN COUNT(*) = COUNT(DISTINCT use_case_code)
         THEN 'PASS' ELSE 'FAIL' END,
    'No duplicates',
    CASE WHEN COUNT(*) = COUNT(DISTINCT use_case_code)
         THEN 'OK'
         ELSE (COUNT(*) - COUNT(DISTINCT use_case_code))::TEXT || ' duplicate(s)' END,
    'Error', NULL
FROM raw.dim_ai_use_case;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_model: model_code is unique',
    CASE WHEN COUNT(*) = COUNT(DISTINCT model_code)
         THEN 'PASS' ELSE 'FAIL' END,
    'No duplicates',
    CASE WHEN COUNT(*) = COUNT(DISTINCT model_code)
         THEN 'OK'
         ELSE (COUNT(*) - COUNT(DISTINCT model_code))::TEXT || ' duplicate(s)' END,
    'Error', NULL
FROM raw.dim_model;

-- ── 3. Referential integrity checks (raw layer) ───────────────────────────────

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_ai_delivery_stage: all use_case_ids exist in dim_ai_use_case',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    '0 orphans',
    COUNT(*)::TEXT || ' orphan(s)',
    'Error', NULL
FROM raw.fact_ai_delivery_stage s
WHERE NOT EXISTS (
    SELECT 1 FROM raw.dim_ai_use_case uc WHERE uc.use_case_id = s.use_case_id
);

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_model_monitoring: all model_ids exist in dim_model',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    '0 orphans',
    COUNT(*)::TEXT || ' orphan(s)',
    'Error', NULL
FROM raw.fact_model_monitoring m
WHERE NOT EXISTS (
    SELECT 1 FROM raw.dim_model d WHERE d.model_id = m.model_id
);

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_governance_review: all reviewer_ids exist in dim_owner',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    '0 orphans',
    COUNT(*)::TEXT || ' orphan(s)',
    'Error', NULL
FROM raw.fact_governance_review gr
WHERE NOT EXISTS (
    SELECT 1 FROM raw.dim_owner o WHERE o.owner_id = gr.reviewer_id
);

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_sla_breach: all stage_ids exist in fact_ai_delivery_stage',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    '0 orphans',
    COUNT(*)::TEXT || ' orphan(s)',
    'Error', NULL
FROM raw.fact_sla_breach sb
WHERE NOT EXISTS (
    SELECT 1 FROM raw.fact_ai_delivery_stage s WHERE s.stage_id = sb.stage_id
);

-- ── 4. Domain / range checks ──────────────────────────────────────────────────

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_ai_use_case: priority in allowed values',
    CASE WHEN COUNT(*) FILTER (
              WHERE priority NOT IN ('High','Medium','Low')
         ) = 0 THEN 'PASS' ELSE 'FAIL' END,
    '0 invalid',
    COUNT(*) FILTER (WHERE priority NOT IN ('High','Medium','Low'))::TEXT || ' invalid',
    'Error', NULL
FROM raw.dim_ai_use_case;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_ai_delivery_stage: stage_sequence between 1 and 6',
    CASE WHEN COUNT(*) FILTER (WHERE stage_sequence NOT BETWEEN 1 AND 6) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    '0 out-of-range',
    COUNT(*) FILTER (WHERE stage_sequence NOT BETWEEN 1 AND 6)::TEXT || ' out-of-range',
    'Warning', NULL
FROM raw.fact_ai_delivery_stage;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_model_monitoring: accuracy_score between 0 and 1',
    CASE WHEN COUNT(*) FILTER (WHERE accuracy_score NOT BETWEEN 0 AND 1) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    '0 out-of-range',
    COUNT(*) FILTER (WHERE accuracy_score NOT BETWEEN 0 AND 1)::TEXT || ' out-of-range',
    'Error', NULL
FROM raw.fact_model_monitoring;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_model_monitoring: drift_score between 0 and 1',
    CASE WHEN COUNT(*) FILTER (WHERE drift_score NOT BETWEEN 0 AND 1) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    '0 out-of-range',
    COUNT(*) FILTER (WHERE drift_score NOT BETWEEN 0 AND 1)::TEXT || ' out-of-range',
    'Error', NULL
FROM raw.fact_model_monitoring;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_value_realization: realized_value >= 0',
    CASE WHEN COUNT(*) FILTER (WHERE realized_value < 0) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    '0 negative values',
    COUNT(*) FILTER (WHERE realized_value < 0)::TEXT || ' negative',
    'Error', NULL
FROM raw.fact_value_realization;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_governance_review: risk_score between 0 and 100',
    CASE WHEN COUNT(*) FILTER (WHERE risk_score NOT BETWEEN 0 AND 100) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    '0 out-of-range',
    COUNT(*) FILTER (WHERE risk_score NOT BETWEEN 0 AND 100)::TEXT || ' out-of-range',
    'Warning', NULL
FROM raw.fact_governance_review;

-- ── 5. Business logic checks ──────────────────────────────────────────────────

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_ai_delivery_stage: exit_date >= entry_date when both present',
    CASE WHEN COUNT(*) FILTER (WHERE exit_date < entry_date) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    '0 violations',
    COUNT(*) FILTER (WHERE exit_date < entry_date)::TEXT || ' violation(s)',
    'Error', NULL
FROM raw.fact_ai_delivery_stage
WHERE exit_date IS NOT NULL;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_sla_breach: days_over_sla > 0',
    CASE WHEN COUNT(*) FILTER (WHERE days_over_sla <= 0) = 0
         THEN 'PASS' ELSE 'FAIL' END,
    '0 non-positive values',
    COUNT(*) FILTER (WHERE days_over_sla <= 0)::TEXT || ' non-positive',
    'Warning', NULL
FROM raw.fact_sla_breach;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_model_monitoring: no duplicate model_id + monitoring_date',
    CASE WHEN COUNT(*) = COUNT(DISTINCT (model_id, monitoring_date))
         THEN 'PASS' ELSE 'FAIL' END,
    'No duplicates',
    CASE WHEN COUNT(*) = COUNT(DISTINCT (model_id, monitoring_date))
         THEN 'OK'
         ELSE (COUNT(*) - COUNT(DISTINCT (model_id, monitoring_date)))::TEXT || ' duplicate(s)' END,
    'Error', NULL
FROM raw.fact_model_monitoring;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_model: all Production models are active',
    CASE WHEN COUNT(*) FILTER (
              WHERE deployment_env = 'Production' AND NOT is_active
         ) = 0 THEN 'PASS' ELSE 'WARN' END,
    '0 inactive production models',
    COUNT(*) FILTER (WHERE deployment_env = 'Production' AND NOT is_active)::TEXT || ' found',
    'Warning', NULL
FROM raw.dim_model;

-- ── 6. Volume checks (warn if counts fall below expected thresholds) ───────────

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_business_unit: at least 5 rows',
    CASE WHEN COUNT(*) >= 5 THEN 'PASS' ELSE 'FAIL' END,
    '>= 5',
    COUNT(*)::TEXT,
    'Error', NULL
FROM raw.dim_business_unit;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'dim_ai_use_case: at least 10 rows',
    CASE WHEN COUNT(*) >= 10 THEN 'PASS' ELSE 'FAIL' END,
    '>= 10',
    COUNT(*)::TEXT,
    'Error', NULL
FROM raw.dim_ai_use_case;

INSERT INTO audit.dq_check_results (check_name, status, expected, actual, severity, notes)
SELECT
    'fact_model_monitoring: at least 50 rows',
    CASE WHEN COUNT(*) >= 50 THEN 'PASS' ELSE 'FAIL' END,
    '>= 50',
    COUNT(*)::TEXT,
    'Warning', NULL
FROM raw.fact_model_monitoring;

-- ── Summary of this run ───────────────────────────────────────────────────────
SELECT
    status,
    severity,
    COUNT(*)  AS check_count
FROM audit.dq_check_results
WHERE check_timestamp >= NOW() - INTERVAL '10 minutes'
GROUP BY status, severity
ORDER BY status, severity;
