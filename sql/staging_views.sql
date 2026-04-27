-- AI Solution Delivery Control Tower
-- Staging schema views: source conformance, type casts, status normalization
-- Nicholas Hidalgo | Portfolio Project | Synthetic Data

DROP VIEW IF EXISTS staging.stg_fact_governance_review  CASCADE;
DROP VIEW IF EXISTS staging.stg_fact_sla_breach         CASCADE;
DROP VIEW IF EXISTS staging.stg_fact_value_realization  CASCADE;
DROP VIEW IF EXISTS staging.stg_fact_model_monitoring   CASCADE;
DROP VIEW IF EXISTS staging.stg_fact_ai_delivery_stage  CASCADE;
DROP VIEW IF EXISTS staging.stg_dim_owner               CASCADE;
DROP VIEW IF EXISTS staging.stg_dim_model               CASCADE;
DROP VIEW IF EXISTS staging.stg_dim_risk_tier           CASCADE;
DROP VIEW IF EXISTS staging.stg_dim_ai_use_case         CASCADE;
DROP VIEW IF EXISTS staging.stg_dim_business_unit       CASCADE;

CREATE VIEW staging.stg_dim_business_unit AS
SELECT
    business_unit_id,
    TRIM(unit_code)                                     AS unit_code,
    TRIM(unit_name)                                     AS unit_name,
    COALESCE(TRIM(division), 'Unassigned')              AS division,
    COALESCE(TRIM(region), 'Global')                    AS region,
    created_at::DATE                                    AS created_date
FROM raw.dim_business_unit;


CREATE VIEW staging.stg_dim_ai_use_case AS
SELECT
    use_case_id,
    TRIM(use_case_code)                                 AS use_case_code,
    TRIM(use_case_name)                                 AS use_case_name,
    business_unit_id,
    TRIM(use_case_type)                                 AS use_case_type,
    COALESCE(TRIM(description), '')                     AS description,
    CASE TRIM(priority)
        WHEN 'High'   THEN 'High'
        WHEN 'Medium' THEN 'Medium'
        WHEN 'Low'    THEN 'Low'
        ELSE 'Medium'
    END                                                 AS priority,
    TRIM(current_stage)                                 AS current_stage,
    created_at::DATE                                    AS intake_date,
    updated_at::DATE                                    AS last_updated_date
FROM raw.dim_ai_use_case;


CREATE VIEW staging.stg_dim_risk_tier AS
SELECT
    risk_tier_id,
    TRIM(tier_code)                                     AS tier_code,
    TRIM(tier_name)                                     AS tier_name,
    COALESCE(TRIM(description), '')                     AS description,
    COALESCE(TRIM(approval_level), 'Delivery Lead')     AS approval_level,
    COALESCE(TRIM(review_frequency), 'Annual')          AS review_frequency
FROM raw.dim_risk_tier;


CREATE VIEW staging.stg_dim_model AS
SELECT
    model_id,
    TRIM(model_code)                                    AS model_code,
    TRIM(model_name)                                    AS model_name,
    use_case_id,
    TRIM(model_type)                                    AS model_type,
    COALESCE(TRIM(framework), 'Unknown')                AS framework,
    COALESCE(TRIM(version), '1.0')                      AS version,
    risk_tier_id,
    CASE TRIM(deployment_env)
        WHEN 'Production'   THEN 'Production'
        WHEN 'Staging'      THEN 'Staging'
        WHEN 'Development'  THEN 'Development'
        ELSE 'Development'
    END                                                 AS deployment_env,
    COALESCE(performance_score, 0.0)                    AS performance_score,
    COALESCE(TRIM(bias_assessment), 'Not Assessed')     AS bias_assessment,
    COALESCE(TRIM(drift_status), 'None')                AS drift_status,
    is_active,
    created_at::DATE                                    AS created_date
FROM raw.dim_model;


CREATE VIEW staging.stg_dim_owner AS
SELECT
    owner_id,
    TRIM(owner_name)                                    AS owner_name,
    TRIM(owner_role)                                    AS owner_role,
    business_unit_id,
    LOWER(TRIM(COALESCE(email, '')))                    AS email,
    is_active
FROM raw.dim_owner;


CREATE VIEW staging.stg_fact_ai_delivery_stage AS
SELECT
    stage_id,
    use_case_id,
    owner_id,
    TRIM(stage_name)                                    AS stage_name,
    stage_sequence,
    entry_date,
    exit_date,
    COALESCE(actual_days, 0)                            AS actual_days,
    sla_target_days,
    CASE TRIM(stage_status)
        WHEN 'In Progress'  THEN 'In Progress'
        WHEN 'Completed'    THEN 'Completed'
        WHEN 'Blocked'      THEN 'Blocked'
        ELSE 'In Progress'
    END                                                 AS stage_status,
    COALESCE(TRIM(exit_reason), '')                     AS exit_reason,
    is_sla_breached,
    COALESCE(actual_days, 0) - sla_target_days          AS days_over_sla
FROM raw.fact_ai_delivery_stage;


CREATE VIEW staging.stg_fact_model_monitoring AS
SELECT
    monitoring_id,
    model_id,
    monitoring_date,
    COALESCE(accuracy_score, 0.0)                       AS accuracy_score,
    COALESCE(precision_score, 0.0)                      AS precision_score,
    COALESCE(recall_score, 0.0)                         AS recall_score,
    COALESCE(f1_score, 0.0)                             AS f1_score,
    COALESCE(drift_score, 0.0)                          AS drift_score,
    COALESCE(data_quality_score, 1.0)                   AS data_quality_score,
    COALESCE(prediction_volume, 0)                      AS prediction_volume,
    alert_triggered,
    COALESCE(TRIM(alert_type), 'None')                  AS alert_type,
    COALESCE(TRIM(alert_severity), 'None')              AS alert_severity,
    retrain_required
FROM raw.fact_model_monitoring;


CREATE VIEW staging.stg_fact_value_realization AS
SELECT
    value_id,
    use_case_id,
    measurement_date,
    TRIM(measurement_period)                            AS measurement_period,
    TRIM(metric_name)                                   AS metric_name,
    TRIM(metric_category)                               AS metric_category,
    COALESCE(baseline_value, 0.0)                       AS baseline_value,
    COALESCE(realized_value, 0.0)                       AS realized_value,
    COALESCE(target_value, 0.0)                         AS target_value,
    COALESCE(TRIM(unit_of_measure), 'Units')            AS unit_of_measure,
    CASE TRIM(confidence_level)
        WHEN 'High'   THEN 'High'
        WHEN 'Medium' THEN 'Medium'
        WHEN 'Low'    THEN 'Low'
        ELSE 'Medium'
    END                                                 AS confidence_level,
    is_validated,
    COALESCE(TRIM(validated_by), '')                    AS validated_by,
    CASE
        WHEN target_value > 0
        THEN ROUND(100.0 * realized_value / target_value, 1)
        ELSE NULL
    END                                                 AS pct_of_target
FROM raw.fact_value_realization;


CREATE VIEW staging.stg_fact_sla_breach AS
SELECT
    breach_id,
    stage_id,
    use_case_id,
    breach_date,
    sla_target_days,
    actual_days,
    days_over_sla,
    COALESCE(TRIM(breach_reason), 'Not documented')     AS breach_reason,
    escalated,
    COALESCE(TRIM(escalated_to), '')                    AS escalated_to,
    resolved_date,
    CASE WHEN resolved_date IS NOT NULL THEN 'Resolved' ELSE 'Open' END
                                                        AS breach_resolution_status
FROM raw.fact_sla_breach;


CREATE VIEW staging.stg_fact_governance_review AS
SELECT
    review_id,
    use_case_id,
    risk_tier_id,
    TRIM(review_type)                                   AS review_type,
    review_date,
    reviewer_id,
    CASE TRIM(review_outcome)
        WHEN 'Approved'                  THEN 'Approved'
        WHEN 'Approved with Conditions'  THEN 'Approved with Conditions'
        WHEN 'Rejected'                  THEN 'Rejected'
        WHEN 'Deferred'                  THEN 'Deferred'
        ELSE 'Pending'
    END                                                 AS review_outcome,
    COALESCE(risk_score, 50)                            AS risk_score,
    COALESCE(findings_count, 0)                         AS findings_count,
    COALESCE(critical_findings, 0)                      AS critical_findings,
    COALESCE(TRIM(conditions), '')                      AS conditions,
    next_review_date,
    CASE
        WHEN next_review_date < CURRENT_DATE            THEN 'Overdue'
        WHEN next_review_date < CURRENT_DATE + 14       THEN 'Due Soon'
        ELSE 'On Track'
    END                                                 AS review_health
FROM raw.fact_governance_review;
