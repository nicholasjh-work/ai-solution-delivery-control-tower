-- AI Solution Delivery Control Tower
-- Raw schema DDL: source-system tables simulating Azure SQL extract target
-- Nicholas Hidalgo | Portfolio Project | Synthetic Data

SET search_path TO raw;

DROP TABLE IF EXISTS raw.fact_governance_review  CASCADE;
DROP TABLE IF EXISTS raw.fact_sla_breach         CASCADE;
DROP TABLE IF EXISTS raw.fact_value_realization  CASCADE;
DROP TABLE IF EXISTS raw.fact_model_monitoring   CASCADE;
DROP TABLE IF EXISTS raw.fact_ai_delivery_stage  CASCADE;
DROP TABLE IF EXISTS raw.dim_owner               CASCADE;
DROP TABLE IF EXISTS raw.dim_model               CASCADE;
DROP TABLE IF EXISTS raw.dim_risk_tier           CASCADE;
DROP TABLE IF EXISTS raw.dim_ai_use_case         CASCADE;
DROP TABLE IF EXISTS raw.dim_business_unit       CASCADE;

CREATE TABLE raw.dim_business_unit (
    business_unit_id    SERIAL PRIMARY KEY,
    unit_code           VARCHAR(10)  NOT NULL UNIQUE,
    unit_name           VARCHAR(100) NOT NULL,
    division            VARCHAR(100),
    region              VARCHAR(50),
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE raw.dim_ai_use_case (
    use_case_id         SERIAL PRIMARY KEY,
    use_case_code       VARCHAR(20)  NOT NULL UNIQUE,
    use_case_name       VARCHAR(200) NOT NULL,
    business_unit_id    INT          NOT NULL REFERENCES raw.dim_business_unit(business_unit_id),
    use_case_type       VARCHAR(50)  NOT NULL,
    description         TEXT,
    priority            VARCHAR(20)  NOT NULL DEFAULT 'Medium',
    current_stage       VARCHAR(50)  NOT NULL DEFAULT 'Intake',
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE raw.dim_risk_tier (
    risk_tier_id        SERIAL PRIMARY KEY,
    tier_code           VARCHAR(10)  NOT NULL UNIQUE,
    tier_name           VARCHAR(50)  NOT NULL,
    description         TEXT,
    approval_level      VARCHAR(100),
    review_frequency    VARCHAR(50),
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE raw.dim_model (
    model_id            SERIAL PRIMARY KEY,
    model_code          VARCHAR(20)  NOT NULL UNIQUE,
    model_name          VARCHAR(200) NOT NULL,
    use_case_id         INT          NOT NULL REFERENCES raw.dim_ai_use_case(use_case_id),
    model_type          VARCHAR(50)  NOT NULL,
    framework           VARCHAR(50),
    version             VARCHAR(20)  NOT NULL DEFAULT '1.0',
    risk_tier_id        INT          NOT NULL REFERENCES raw.dim_risk_tier(risk_tier_id),
    deployment_env      VARCHAR(20)  NOT NULL DEFAULT 'Development',
    performance_score   NUMERIC(5,4),
    bias_assessment     VARCHAR(50),
    drift_status        VARCHAR(50),
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE raw.dim_owner (
    owner_id            SERIAL PRIMARY KEY,
    owner_name          VARCHAR(100) NOT NULL,
    owner_role          VARCHAR(100) NOT NULL,
    business_unit_id    INT          NOT NULL REFERENCES raw.dim_business_unit(business_unit_id),
    email               VARCHAR(150),
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE raw.fact_ai_delivery_stage (
    stage_id            SERIAL PRIMARY KEY,
    use_case_id         INT          NOT NULL REFERENCES raw.dim_ai_use_case(use_case_id),
    owner_id            INT          NOT NULL REFERENCES raw.dim_owner(owner_id),
    stage_name          VARCHAR(50)  NOT NULL,
    stage_sequence      INT          NOT NULL,
    entry_date          DATE         NOT NULL,
    exit_date           DATE,
    actual_days         INT,
    sla_target_days     INT          NOT NULL DEFAULT 30,
    stage_status        VARCHAR(30)  NOT NULL DEFAULT 'In Progress',
    exit_reason         VARCHAR(100),
    is_sla_breached     BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE raw.fact_model_monitoring (
    monitoring_id       SERIAL PRIMARY KEY,
    model_id            INT          NOT NULL REFERENCES raw.dim_model(model_id),
    monitoring_date     DATE         NOT NULL,
    accuracy_score      NUMERIC(5,4),
    precision_score     NUMERIC(5,4),
    recall_score        NUMERIC(5,4),
    f1_score            NUMERIC(5,4),
    drift_score         NUMERIC(5,4),
    data_quality_score  NUMERIC(5,4),
    prediction_volume   INT,
    alert_triggered     BOOLEAN      NOT NULL DEFAULT FALSE,
    alert_type          VARCHAR(50),
    alert_severity      VARCHAR(20),
    retrain_required    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE raw.fact_value_realization (
    value_id            SERIAL PRIMARY KEY,
    use_case_id         INT          NOT NULL REFERENCES raw.dim_ai_use_case(use_case_id),
    measurement_date    DATE         NOT NULL,
    measurement_period  VARCHAR(20)  NOT NULL,
    metric_name         VARCHAR(100) NOT NULL,
    metric_category     VARCHAR(50)  NOT NULL,
    baseline_value      NUMERIC(15,2),
    realized_value      NUMERIC(15,2),
    target_value        NUMERIC(15,2),
    unit_of_measure     VARCHAR(50),
    confidence_level    VARCHAR(20)  NOT NULL DEFAULT 'Medium',
    is_validated        BOOLEAN      NOT NULL DEFAULT FALSE,
    validated_by        VARCHAR(100),
    notes               TEXT,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE raw.fact_sla_breach (
    breach_id           SERIAL PRIMARY KEY,
    stage_id            INT          NOT NULL REFERENCES raw.fact_ai_delivery_stage(stage_id),
    use_case_id         INT          NOT NULL REFERENCES raw.dim_ai_use_case(use_case_id),
    breach_date         DATE         NOT NULL,
    sla_target_days     INT          NOT NULL,
    actual_days         INT          NOT NULL,
    days_over_sla       INT          NOT NULL,
    breach_reason       VARCHAR(200),
    escalated           BOOLEAN      NOT NULL DEFAULT FALSE,
    escalated_to        VARCHAR(100),
    resolved_date       DATE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE raw.fact_governance_review (
    review_id           SERIAL PRIMARY KEY,
    use_case_id         INT          NOT NULL REFERENCES raw.dim_ai_use_case(use_case_id),
    risk_tier_id        INT          NOT NULL REFERENCES raw.dim_risk_tier(risk_tier_id),
    review_type         VARCHAR(50)  NOT NULL,
    review_date         DATE         NOT NULL,
    reviewer_id         INT          NOT NULL REFERENCES raw.dim_owner(owner_id),
    review_outcome      VARCHAR(30)  NOT NULL,
    risk_score          INT,
    findings_count      INT          NOT NULL DEFAULT 0,
    critical_findings   INT          NOT NULL DEFAULT 0,
    conditions          TEXT,
    next_review_date    DATE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_raw_stage_uc     ON raw.fact_ai_delivery_stage(use_case_id);
CREATE INDEX idx_raw_stage_seq    ON raw.fact_ai_delivery_stage(stage_sequence);
CREATE INDEX idx_raw_mon_model    ON raw.fact_model_monitoring(model_id);
CREATE INDEX idx_raw_mon_date     ON raw.fact_model_monitoring(monitoring_date);
CREATE INDEX idx_raw_val_uc       ON raw.fact_value_realization(use_case_id);
CREATE INDEX idx_raw_sla_uc       ON raw.fact_sla_breach(use_case_id);
CREATE INDEX idx_raw_gov_uc       ON raw.fact_governance_review(use_case_id);
CREATE INDEX idx_raw_uc_stage     ON raw.dim_ai_use_case(current_stage);
