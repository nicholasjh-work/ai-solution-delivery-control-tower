-- AI Solution Delivery Control Tower
-- Silver schema: analytical views over staging (raw > staging > silver)
-- Nicholas Hidalgo | Portfolio Project | Synthetic Data

DROP VIEW IF EXISTS silver.v_executive_delivery   CASCADE;
DROP VIEW IF EXISTS silver.v_sla_compliance       CASCADE;
DROP VIEW IF EXISTS silver.v_model_health         CASCADE;
DROP VIEW IF EXISTS silver.v_governance_status    CASCADE;
DROP VIEW IF EXISTS silver.v_intake_metrics       CASCADE;
DROP VIEW IF EXISTS silver.v_portfolio_summary    CASCADE;

-- ── v_portfolio_summary ───────────────────────────────────────────────────────
-- One row per use case. Joins use case, business unit, latest stage, and
-- most recent governance review to give a full portfolio snapshot.

CREATE VIEW silver.v_portfolio_summary AS
WITH latest_stage AS (
    SELECT DISTINCT ON (use_case_id)
        use_case_id,
        stage_name      AS current_stage_name,
        stage_sequence  AS current_stage_sequence,
        stage_status    AS current_stage_status,
        entry_date      AS current_stage_entry_date,
        actual_days     AS current_stage_actual_days,
        sla_target_days AS current_stage_sla_days,
        is_sla_breached AS current_stage_breached,
        days_over_sla   AS current_days_over_sla
    FROM staging.stg_fact_ai_delivery_stage
    ORDER BY use_case_id, stage_sequence DESC
),
latest_governance AS (
    SELECT DISTINCT ON (use_case_id)
        use_case_id,
        review_outcome  AS last_review_outcome,
        review_date     AS last_review_date,
        next_review_date,
        review_health,
        risk_score      AS last_risk_score,
        critical_findings AS last_critical_findings
    FROM staging.stg_fact_governance_review
    ORDER BY use_case_id, review_date DESC
),
sla_breach_counts AS (
    SELECT use_case_id, COUNT(*) AS total_sla_breaches
    FROM staging.stg_fact_sla_breach
    GROUP BY use_case_id
),
gate_status AS (
    -- gate is Clear only when every governance review for the use case
    -- is Approved or N/A; any Conditional, Pending, or Deferred → Blocked
    SELECT
        use_case_id,
        CASE
            WHEN COUNT(*) FILTER (
                WHERE review_outcome IN ('Approved with Conditions','Pending','Deferred')
            ) > 0 THEN 'Blocked'
            ELSE 'Clear'
        END AS gate_status
    FROM staging.stg_fact_governance_review
    GROUP BY use_case_id
)
SELECT
    uc.use_case_id,
    uc.use_case_code,
    uc.use_case_name,
    uc.use_case_type,
    uc.priority,
    bu.unit_name        AS business_unit,
    bu.division,
    bu.region,
    -- Pipeline position
    ls.current_stage_name,
    ls.current_stage_sequence,
    ls.current_stage_status,
    ls.current_stage_entry_date,
    ls.current_stage_actual_days,
    ls.current_stage_sla_days,
    ls.current_stage_breached,
    GREATEST(ls.current_days_over_sla, 0)   AS days_over_sla,
    -- Governance
    COALESCE(lg.last_review_outcome, 'Not Reviewed')    AS last_review_outcome,
    lg.last_review_date,
    lg.next_review_date,
    COALESCE(lg.review_health, 'N/A')                   AS review_health,
    COALESCE(lg.last_risk_score, 0)                     AS last_risk_score,
    COALESCE(lg.last_critical_findings, 0)              AS last_critical_findings,
    -- Gate
    COALESCE(gs.gate_status, 'Clear')                   AS gate_status,
    -- SLA history
    COALESCE(sc.total_sla_breaches, 0)                  AS total_sla_breaches
FROM staging.stg_dim_ai_use_case uc
JOIN staging.stg_dim_business_unit bu  ON bu.business_unit_id = uc.business_unit_id
LEFT JOIN latest_stage          ls     ON ls.use_case_id      = uc.use_case_id
LEFT JOIN latest_governance     lg     ON lg.use_case_id      = uc.use_case_id
LEFT JOIN sla_breach_counts     sc     ON sc.use_case_id      = uc.use_case_id
LEFT JOIN gate_status           gs     ON gs.use_case_id      = uc.use_case_id;


-- ── v_intake_metrics ──────────────────────────────────────────────────────────
-- Pipeline funnel: how many use cases at each stage, by BU and priority.
-- Includes average days-in-stage and SLA breach rate per stage bucket.

CREATE VIEW silver.v_intake_metrics AS
WITH stage_counts AS (
    SELECT
        s.stage_name,
        s.stage_sequence,
        uc.business_unit_id,
        bu.unit_name        AS business_unit,
        bu.division,
        uc.priority,
        COUNT(*)            AS use_case_count,
        AVG(s.actual_days)  AS avg_days_in_stage,
        SUM(CASE WHEN s.is_sla_breached THEN 1 ELSE 0 END)  AS breached_count,
        AVG(GREATEST(s.days_over_sla, 0))                   AS avg_days_over_sla
    FROM staging.stg_fact_ai_delivery_stage s
    JOIN staging.stg_dim_ai_use_case uc ON uc.use_case_id = s.use_case_id
    JOIN staging.stg_dim_business_unit bu ON bu.business_unit_id = uc.business_unit_id
    GROUP BY s.stage_name, s.stage_sequence,
             uc.business_unit_id, bu.unit_name, bu.division, uc.priority
)
SELECT
    stage_sequence,
    stage_name,
    business_unit_id,
    business_unit,
    division,
    priority,
    use_case_count,
    ROUND(avg_days_in_stage::NUMERIC, 1)  AS avg_days_in_stage,
    breached_count,
    ROUND(
        100.0 * breached_count / NULLIF(use_case_count, 0),
        1
    )                                     AS sla_breach_pct,
    ROUND(avg_days_over_sla::NUMERIC, 1)  AS avg_days_over_sla
FROM stage_counts
ORDER BY stage_sequence, business_unit, priority;


-- ── v_governance_status ───────────────────────────────────────────────────────
-- One row per governance review. Adds gate_status, health flag,
-- risk tier context, and reviewer details for compliance reporting.

CREATE VIEW silver.v_governance_status AS
SELECT
    gr.review_id,
    uc.use_case_id,
    uc.use_case_code,
    uc.use_case_name,
    bu.unit_name                            AS business_unit,
    rt.tier_name                            AS risk_tier,
    rt.tier_code,
    gr.review_type,
    gr.review_date,
    gr.review_outcome,
    gr.risk_score,
    gr.findings_count,
    gr.critical_findings,
    gr.conditions,
    gr.next_review_date,
    gr.review_health,
    -- gate_status per review row: Blocked when outcome is not a clean Approved
    CASE
        WHEN gr.review_outcome = 'Approved'  THEN 'Clear'
        ELSE 'Blocked'
    END                                     AS gate_status,
    o.owner_name                            AS reviewer_name,
    o.owner_role                            AS reviewer_role
FROM staging.stg_fact_governance_review gr
JOIN staging.stg_dim_ai_use_case  uc ON uc.use_case_id  = gr.use_case_id
JOIN staging.stg_dim_business_unit bu ON bu.business_unit_id = uc.business_unit_id
JOIN staging.stg_dim_risk_tier    rt ON rt.risk_tier_id  = gr.risk_tier_id
JOIN staging.stg_dim_owner        o  ON o.owner_id       = gr.reviewer_id
ORDER BY gr.review_date DESC, uc.use_case_code;


-- ── v_model_health ────────────────────────────────────────────────────────────
-- One row per model × monitoring date.
-- health_status derivation:
--   Healthy   → performance_score >= 0.85 AND drift_status = 'None' AND bias_assessment not High
--   At Risk   → drift_status IN ('Significant') OR bias_assessment IN ('High','Review Required')
--   Degraded  → performance_score < 0.80
--   Monitor   → everything else

CREATE VIEW silver.v_model_health AS
SELECT
    m.model_id,
    m.model_code,
    m.model_name,
    m.model_type,
    m.framework,
    m.version,
    m.deployment_env,
    m.is_active,
    uc.use_case_id,
    uc.use_case_code,
    uc.use_case_name,
    bu.unit_name                            AS business_unit,
    rt.tier_name                            AS risk_tier,
    rt.tier_code,
    mon.monitoring_id,
    mon.monitoring_date,
    mon.accuracy_score,
    mon.precision_score,
    mon.recall_score,
    mon.f1_score,
    mon.drift_score,
    mon.data_quality_score,
    mon.prediction_volume,
    mon.alert_triggered,
    mon.alert_type,
    mon.alert_severity,
    mon.retrain_required,
    m.bias_assessment,
    m.drift_status,
    m.performance_score                     AS model_performance_score,
    -- health_status
    CASE
        WHEN m.drift_status = 'Significant'
             OR m.bias_assessment IN ('High', 'Review Required')
            THEN 'At Risk'
        WHEN m.performance_score < 0.80
            THEN 'Degraded'
        WHEN m.performance_score >= 0.85
             AND m.drift_status = 'None'
             AND m.bias_assessment NOT IN ('High', 'Review Required')
            THEN 'Healthy'
        ELSE 'Monitor'
    END                                     AS health_status
FROM staging.stg_dim_model m
JOIN staging.stg_dim_ai_use_case   uc ON uc.use_case_id   = m.use_case_id
JOIN staging.stg_dim_business_unit bu ON bu.business_unit_id = uc.business_unit_id
JOIN staging.stg_dim_risk_tier     rt ON rt.risk_tier_id   = m.risk_tier_id
JOIN staging.stg_fact_model_monitoring mon ON mon.model_id = m.model_id
ORDER BY m.model_code, mon.monitoring_date;


-- ── v_sla_compliance ─────────────────────────────────────────────────────────
-- One row per SLA breach. Joins stage, use case, BU and owner context.
-- days_over_sla is derived directly: actual_days - sla_target_days.

CREATE VIEW silver.v_sla_compliance AS
SELECT
    sb.breach_id,
    sb.use_case_id,
    uc.use_case_code,
    uc.use_case_name,
    uc.priority,
    bu.unit_name                            AS business_unit,
    bu.division,
    sb.stage_id,
    s.stage_name,
    s.stage_sequence,
    sb.breach_date,
    sb.sla_target_days,
    sb.actual_days,
    sb.actual_days - sb.sla_target_days     AS days_over_sla,
    sb.breach_reason,
    sb.escalated,
    sb.escalated_to,
    sb.resolved_date,
    sb.breach_resolution_status,
    -- severity bucket based on how far over SLA
    CASE
        WHEN (sb.actual_days - sb.sla_target_days) >= 30 THEN 'Critical'
        WHEN (sb.actual_days - sb.sla_target_days) >= 14 THEN 'High'
        WHEN (sb.actual_days - sb.sla_target_days) >= 7  THEN 'Medium'
        ELSE 'Low'
    END                                     AS breach_severity,
    o.owner_name                            AS stage_owner,
    o.owner_role                            AS stage_owner_role
FROM staging.stg_fact_sla_breach sb
JOIN staging.stg_dim_ai_use_case      uc ON uc.use_case_id  = sb.use_case_id
JOIN staging.stg_dim_business_unit    bu ON bu.business_unit_id = uc.business_unit_id
JOIN staging.stg_fact_ai_delivery_stage s ON s.stage_id     = sb.stage_id
JOIN staging.stg_dim_owner             o ON o.owner_id      = s.owner_id
ORDER BY sb.breach_date DESC;


-- ── v_executive_delivery ─────────────────────────────────────────────────────
-- Executive roll-up: one row per business unit.
-- Summarises portfolio health, pipeline velocity, SLA performance,
-- value realization, and governance posture for C-suite consumption.

CREATE VIEW silver.v_executive_delivery AS
WITH uc_counts AS (
    SELECT
        bu.business_unit_id,
        COUNT(*)                                                    AS total_use_cases,
        COUNT(*) FILTER (WHERE uc.current_stage = 'Production')    AS in_production,
        COUNT(*) FILTER (WHERE uc.priority = 'High')               AS high_priority_count,
        COUNT(*) FILTER (WHERE uc.current_stage NOT IN ('Production','Cancelled')) AS in_flight
    FROM staging.stg_dim_ai_use_case uc
    JOIN staging.stg_dim_business_unit bu ON bu.business_unit_id = uc.business_unit_id
    GROUP BY bu.business_unit_id
),
sla_summary AS (
    SELECT
        uc.business_unit_id,
        COUNT(*)                                                    AS total_stages,
        SUM(CASE WHEN s.is_sla_breached THEN 1 ELSE 0 END)        AS breached_stages,
        ROUND(
            100.0 * SUM(CASE WHEN NOT s.is_sla_breached THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0), 1
        )                                                           AS sla_compliance_pct
    FROM staging.stg_fact_ai_delivery_stage s
    JOIN staging.stg_dim_ai_use_case uc ON uc.use_case_id = s.use_case_id
    GROUP BY uc.business_unit_id
),
value_summary AS (
    SELECT
        uc.business_unit_id,
        COUNT(DISTINCT vr.use_case_id)                              AS use_cases_with_value_data,
        ROUND(AVG(vr.pct_of_target), 1)                            AS avg_pct_of_target,
        SUM(vr.realized_value) FILTER (
            WHERE vr.metric_category = 'Financial'
        )                                                           AS total_financial_realized
    FROM staging.stg_fact_value_realization vr
    JOIN staging.stg_dim_ai_use_case uc ON uc.use_case_id = vr.use_case_id
    GROUP BY uc.business_unit_id
),
gov_summary AS (
    SELECT
        uc.business_unit_id,
        COUNT(*)                                                    AS total_reviews,
        SUM(CASE WHEN gr.review_outcome = 'Approved' THEN 1 ELSE 0 END) AS approved_count,
        SUM(CASE WHEN gr.critical_findings > 0 THEN 1 ELSE 0 END) AS reviews_with_critical_findings,
        ROUND(AVG(gr.risk_score), 1)                               AS avg_risk_score
    FROM staging.stg_fact_governance_review gr
    JOIN staging.stg_dim_ai_use_case uc ON uc.use_case_id = gr.use_case_id
    GROUP BY uc.business_unit_id
),
model_health_summary AS (
    SELECT
        uc.business_unit_id,
        COUNT(DISTINCT m.model_id)                                  AS total_models,
        COUNT(DISTINCT m.model_id) FILTER (
            WHERE m.deployment_env = 'Production' AND m.is_active
        )                                                           AS active_prod_models,
        COUNT(DISTINCT m.model_id) FILTER (
            WHERE m.bias_assessment = 'High'
        )                                                           AS high_bias_models
    FROM staging.stg_dim_model m
    JOIN staging.stg_dim_ai_use_case uc ON uc.use_case_id = m.use_case_id
    GROUP BY uc.business_unit_id
)
SELECT
    bu.business_unit_id,
    bu.unit_code,
    bu.unit_name                                                    AS business_unit,
    bu.division,
    bu.region,
    -- Portfolio counts
    COALESCE(uc.total_use_cases, 0)                                 AS total_use_cases,
    COALESCE(uc.in_production, 0)                                   AS in_production,
    COALESCE(uc.in_flight, 0)                                       AS in_flight,
    COALESCE(uc.high_priority_count, 0)                             AS high_priority_count,
    -- SLA
    COALESCE(sl.total_stages, 0)                                    AS total_stages_completed,
    COALESCE(sl.breached_stages, 0)                                 AS sla_breached_stages,
    COALESCE(sl.sla_compliance_pct, 100)                            AS sla_compliance_pct,
    -- Value realization
    COALESCE(vl.use_cases_with_value_data, 0)                       AS use_cases_with_value_data,
    COALESCE(vl.avg_pct_of_target, 0)                               AS avg_pct_of_target,
    COALESCE(vl.total_financial_realized, 0)                        AS total_financial_realized_usd,
    -- Governance
    COALESCE(gs.total_reviews, 0)                                   AS total_gov_reviews,
    COALESCE(gs.approved_count, 0)                                  AS approved_reviews,
    COALESCE(gs.reviews_with_critical_findings, 0)                  AS reviews_with_critical_findings,
    COALESCE(gs.avg_risk_score, 0)                                  AS avg_risk_score,
    -- Models
    COALESCE(mh.total_models, 0)                                    AS total_models,
    COALESCE(mh.active_prod_models, 0)                              AS active_prod_models,
    COALESCE(mh.high_bias_models, 0)                                AS high_bias_models
FROM staging.stg_dim_business_unit bu
LEFT JOIN uc_counts          uc ON uc.business_unit_id = bu.business_unit_id
LEFT JOIN sla_summary        sl ON sl.business_unit_id = bu.business_unit_id
LEFT JOIN value_summary      vl ON vl.business_unit_id = bu.business_unit_id
LEFT JOIN gov_summary        gs ON gs.business_unit_id = bu.business_unit_id
LEFT JOIN model_health_summary mh ON mh.business_unit_id = bu.business_unit_id
ORDER BY bu.unit_name;
