# Data Contract

**AI Solution Delivery Control Tower**  
Version 1.0 | Nicholas Hidalgo | Portfolio Project | Synthetic Data

This document defines the schema, semantics, and quality expectations for each layer of the pipeline. Consumers (silver views, dashboard, exports) must rely only on the contracts defined here, not on raw table internals.

---

## Layer Contracts

### raw (source system simulation)

Tables in `raw` simulate the shape of an Azure SQL extract. Columns carry source-system types; nulls and dirty values are permitted. No business logic is applied here.

**dim_business_unit**

| Column | Type | Nullable | Notes |
|---|---|---|---|
| business_unit_id | SERIAL PK | No | System-generated |
| unit_code | VARCHAR(10) | No | Unique; 2–5 uppercase letters |
| unit_name | VARCHAR(100) | No | |
| division | VARCHAR(100) | Yes | May be NULL in source |
| region | VARCHAR(50) | Yes | May be NULL in source |
| created_at | TIMESTAMP | No | Default NOW() |

**dim_ai_use_case**

| Column | Type | Nullable | Notes |
|---|---|---|---|
| use_case_id | SERIAL PK | No | |
| use_case_code | VARCHAR(20) | No | Unique; format UC-{BU}-{NNN} |
| use_case_name | VARCHAR(200) | No | |
| business_unit_id | INT FK | No | → dim_business_unit |
| use_case_type | VARCHAR(50) | No | One of: Predictive, Forecasting, Classification, NLP, Recommender, Optimization, Graph ML, Analytics |
| description | TEXT | Yes | |
| priority | VARCHAR(20) | No | High / Medium / Low |
| current_stage | VARCHAR(50) | No | Pipeline stage name |
| created_at | TIMESTAMP | No | |
| updated_at | TIMESTAMP | No | |

**dim_risk_tier**

| Column | Type | Notes |
|---|---|---|
| risk_tier_id | SERIAL PK | |
| tier_code | VARCHAR(10) | T1–T4 |
| tier_name | VARCHAR(50) | Critical / High / Medium / Low |
| description | TEXT | |
| approval_level | VARCHAR(100) | |
| review_frequency | VARCHAR(50) | Quarterly / Semi-Annual / Annual |

**dim_model**

| Column | Type | Notes |
|---|---|---|
| model_id | SERIAL PK | |
| model_code | VARCHAR(20) | Unique |
| model_name | VARCHAR(200) | |
| use_case_id | INT FK | → dim_ai_use_case |
| model_type | VARCHAR(50) | |
| framework | VARCHAR(50) | |
| version | VARCHAR(20) | |
| risk_tier_id | INT FK | → dim_risk_tier |
| deployment_env | VARCHAR(20) | Development / Staging / Production |
| performance_score | NUMERIC(5,4) | 0.0–1.0 |
| bias_assessment | VARCHAR(50) | Low / Medium / High / Not Assessed |
| drift_status | VARCHAR(50) | None / Low / Medium / Significant |
| is_active | BOOLEAN | |

**dim_owner**

| Column | Type | Notes |
|---|---|---|
| owner_id | SERIAL PK | |
| owner_name | VARCHAR(100) | |
| owner_role | VARCHAR(100) | |
| business_unit_id | INT FK | |
| email | VARCHAR(150) | |
| is_active | BOOLEAN | |

**fact_ai_delivery_stage**

| Column | Type | Notes |
|---|---|---|
| stage_id | SERIAL PK | |
| use_case_id | INT FK | |
| owner_id | INT FK | |
| stage_name | VARCHAR(50) | Intake / Scoping / Development / Validation / Staging / Production |
| stage_sequence | INT | 1–6 |
| entry_date | DATE | |
| exit_date | DATE | NULL if in progress |
| actual_days | INT | NULL if in progress |
| sla_target_days | INT | |
| stage_status | VARCHAR(30) | In Progress / Completed / Blocked |
| is_sla_breached | BOOLEAN | |

**fact_model_monitoring**

| Column | Type | Notes |
|---|---|---|
| monitoring_id | SERIAL PK | |
| model_id | INT FK | |
| monitoring_date | DATE | One row per model per month |
| accuracy_score | NUMERIC(5,4) | 0–1 |
| precision_score | NUMERIC(5,4) | 0–1 |
| recall_score | NUMERIC(5,4) | 0–1 |
| f1_score | NUMERIC(5,4) | 0–1 |
| drift_score | NUMERIC(5,4) | 0–1 (higher = more drift) |
| data_quality_score | NUMERIC(5,4) | 0–1 |
| prediction_volume | INT | |
| alert_triggered | BOOLEAN | |
| alert_type | VARCHAR(50) | |
| alert_severity | VARCHAR(20) | None / Low / Medium / High |
| retrain_required | BOOLEAN | |

**fact_value_realization**

| Column | Type | Notes |
|---|---|---|
| value_id | SERIAL PK | |
| use_case_id | INT FK | |
| measurement_date | DATE | |
| measurement_period | VARCHAR(20) | e.g. Q2-2024 |
| metric_name | VARCHAR(100) | |
| metric_category | VARCHAR(50) | Financial / Operational |
| baseline_value | NUMERIC(15,2) | Pre-AI baseline |
| realized_value | NUMERIC(15,2) | Actual measured |
| target_value | NUMERIC(15,2) | Expected at deployment |
| unit_of_measure | VARCHAR(50) | |
| confidence_level | VARCHAR(20) | High / Medium / Low |
| is_validated | BOOLEAN | |

**fact_sla_breach**

| Column | Type | Notes |
|---|---|---|
| breach_id | SERIAL PK | |
| stage_id | INT FK | |
| use_case_id | INT FK | |
| breach_date | DATE | |
| sla_target_days | INT | |
| actual_days | INT | |
| days_over_sla | INT | actual_days − sla_target_days; always > 0 |
| breach_reason | VARCHAR(200) | |
| escalated | BOOLEAN | |
| escalated_to | VARCHAR(100) | |
| resolved_date | DATE | NULL if unresolved |

**fact_governance_review**

| Column | Type | Notes |
|---|---|---|
| review_id | SERIAL PK | |
| use_case_id | INT FK | |
| risk_tier_id | INT FK | |
| review_type | VARCHAR(50) | Initial Risk Assessment / Annual Review / Interim / Follow-up |
| review_date | DATE | |
| reviewer_id | INT FK | → dim_owner |
| review_outcome | VARCHAR(30) | Approved / Approved with Conditions / Rejected / Deferred / Pending |
| risk_score | INT | 0–100 |
| findings_count | INT | |
| critical_findings | INT | |
| next_review_date | DATE | |

---

### staging (conformance layer)

Views in `staging` expose a clean, typed, null-free version of each raw table. No aggregation or business logic; purely conformance:
- TRIM on all VARCHAR
- COALESCE on nullable columns with documented defaults
- CASE normalisation for enum-like columns (priority, stage_status, review_outcome)
- Timestamps cast to DATE

Consumers should read from staging, not raw.

---

### silver (analytical layer)

Views in `silver` join staging tables and apply business logic. See [LINEAGE.md](LINEAGE.md) for join paths and [GOVERNANCE_MODEL.md](GOVERNANCE_MODEL.md) for logic definitions.

Silver views are the **only** approved source for the JSON exports and dashboard.

---

## Quality Thresholds

| Check Type | Threshold | Severity |
|---|---|---|
| Null on required column | 0 nulls | Error |
| Duplicate on unique key | 0 duplicates | Error |
| FK orphan | 0 orphans | Error |
| Score out of [0,1] range | 0 violations | Error |
| Exit date before entry date | 0 violations | Error |
| days_over_sla ≤ 0 in breach table | 0 violations | Warning |
| Inactive model in Production | 0 | Warning |
| Volume below minimum | See DQ checks | Error/Warning |
