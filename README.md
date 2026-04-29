<div align="center">

<img src="assets/nh-logo-light.svg#gh-light-mode-only" alt="NH" width="80" />
<img src="assets/nh-logo-dark.svg#gh-dark-mode-only" alt="NH" width="80" />

# AI Solution Delivery Control Tower

**Enterprise AI portfolio governance — synthetic data · portfolio project**

[![Demo](https://img.shields.io/badge/Demo-Local_Setup-4f46e5?style=for-the-badge&logoColor=white)](#local-setup)
[![License](https://img.shields.io/badge/License-MIT-0ea5e9?style=for-the-badge)](LICENSE)
[![DQ Checks](https://img.shields.io/badge/DQ_Checks-24_Passing-16a34a?style=for-the-badge)](sql/data_quality_checks.sql)
[![Silver Views](https://img.shields.io/badge/Silver_Views-7-7c3aed?style=for-the-badge)](sql/silver_views.sql)

[![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)](#)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white)](#)
[![React](https://img.shields.io/badge/React-61DAFB?style=flat&logo=react&logoColor=black)](#)
[![Recharts](https://img.shields.io/badge/Recharts-22d3ee?style=flat&logoColor=white)](#)
[![Tailwind](https://img.shields.io/badge/Tailwind_CSS-06B6D4?style=flat&logo=tailwindcss&logoColor=white)](#)
[![Faker](https://img.shields.io/badge/Faker-FF6B35?style=flat&logoColor=white)](#)

</div>

---

## What This Does

|  |  |
| --- | --- |
| **Portfolio Visibility**<br>Tracks 20 AI use cases across 8 business units through a 6-stage delivery pipeline — Intake → Scoping → Development → Validation → Staging → Production — with SLA targets and breach detection at every stage. | **Governance Tracking**<br>Records governance reviews against a 4-tier risk framework (T1 Critical → T4 Low). Derives `gate_status` (Clear / Blocked) automatically from review outcomes. Surfaces overdue reviews and critical findings. |
| **Model Health Monitor**<br>Classifies each model into Healthy · Monitor · At Risk · Degraded based on performance score, drift signal, and bias assessment. 12 months of monthly monitoring history per production model. | **Value Realization**<br>Captures quarterly financial and operational metrics (baseline → target → realized) with confidence levels and validation status. Aggregated to business unit in the executive view. |
| **Data Quality**<br>24 DQ assertions and 16 reconciliation checks write results to an `audit` schema. A Python CLI runner exits non-zero on failure — CI-compatible out of the box. | **Business Partner Operating Model**<br>Models how a Data & AI Business Partner translates business demand into governed delivery: intake, value hypothesis, feasibility, organizational readiness, risk triage, roadmap, handoff, and value realization across 14 use cases in 6 functions. |

---

## Business Problem

Large enterprises running multiple AI initiatives in parallel face three compounding risks:

1. **Delivery opacity** — no single view of where each use case sits in the pipeline or whether it is on track against SLA targets.
2. **Governance gaps** — risk reviews happen asynchronously, conditions go untracked, and high-risk models reach production without a clear gate clearance record.
3. **Value leakage** — financial and operational benefits are claimed at deployment but rarely measured consistently over time.

This platform simulates the operational data layer that would address all three: a governed, auditable record of delivery, model risk, business partner demand, and realized value — structured for analytics consumption.

---

## ELT Pipeline

```
Source system (simulated Azure SQL extract)
  │
  ▼
raw schema          ← Exact DDL replica of source tables. Nulls and dirty
  │                    values permitted. No business logic.
  ▼
staging schema      ← Conformance views (1:1 over raw). TRIM, COALESCE,
  │                    type casts, enum normalisation. Row counts = raw.
  ▼
silver schema       ← Analytical views. Multi-table joins + business logic
  │                    derivations (health_status, gate_status, days_over_sla,
  │                    composite_readiness_score, handoff_ready_flag).
  │
  ├──▶ audit schema ← DQ assertions + reconciliation results persisted here.
  │
  ▼
data/silver/*.json  ← Point-in-time export from silver + audit views.
  │
  ▼
React dashboard     ← Reads JSON. No live DB connection at runtime.
```

Quality checks run between export steps. `scripts/run_quality_checks.py` executes both SQL files and exits non-zero on any FAIL — drop it into any CI pipeline.

---

## Data Model

### raw — source system simulation

| Table | Rows | Description |
| --- | :---: | --- |
| ![dim_business_unit](https://img.shields.io/badge/dim__business__unit-1f2937?style=flat) | `8` | Business units with division and region |
| ![dim_ai_use_case](https://img.shields.io/badge/dim__ai__use__case-1f2937?style=flat) | `20` | AI initiatives with type, priority, current stage |
| ![dim_risk_tier](https://img.shields.io/badge/dim__risk__tier-1f2937?style=flat) | `4` | T1 Critical → T4 Low governance tiers |
| ![dim_model](https://img.shields.io/badge/dim__model-1f2937?style=flat) | `20` | ML models with framework, version, bias and drift signals |
| ![dim_owner](https://img.shields.io/badge/dim__owner-1f2937?style=flat) | `16` | Delivery owners and reviewers |
| ![dim_bp_portfolio](https://img.shields.io/badge/dim__bp__portfolio-1f2937?style=flat) | `14` | Business Partner portfolio of AI initiatives |
| ![fact_ai_delivery_stage](https://img.shields.io/badge/fact__ai__delivery__stage-1f2937?style=flat) | `94` | One row per use case per pipeline stage |
| ![fact_model_monitoring](https://img.shields.io/badge/fact__model__monitoring-1f2937?style=flat) | `104` | Monthly model performance metrics |
| ![fact_value_realization](https://img.shields.io/badge/fact__value__realization-1f2937?style=flat) | `28` | Quarterly financial and operational metrics |
| ![fact_sla_breach](https://img.shields.io/badge/fact__sla__breach-1f2937?style=flat) | `10` | Breached stages with reasons and escalation status |
| ![fact_governance_review](https://img.shields.io/badge/fact__governance__review-1f2937?style=flat) | `29` | Risk reviews with outcomes and conditions |

### staging — conformance views

Ten views (`stg_*`) sit 1:1 over the raw tables. Transformations: TRIM on all VARCHAR, COALESCE with documented defaults, CASE normalisation for enums, timestamp → DATE casts. No joins, no aggregation, no business logic.

### silver — analytical views

| View | Grain | Key Derivations |
| --- | --- | --- |
| ![v_portfolio_summary](https://img.shields.io/badge/v__portfolio__summary-1f2937?style=flat) | 1 row per use case | `gate_status`, `days_over_sla`, latest stage + review |
| ![v_intake_metrics](https://img.shields.io/badge/v__intake__metrics-1f2937?style=flat) | Stage × BU × priority | `sla_breach_pct`, `avg_days_over_sla` |
| ![v_governance_status](https://img.shields.io/badge/v__governance__status-1f2937?style=flat) | 1 row per review | `gate_status` per review, reviewer context |
| ![v_model_health](https://img.shields.io/badge/v__model__health-1f2937?style=flat) | Model × monitoring date | `health_status`, `breach_severity` |
| ![v_sla_compliance](https://img.shields.io/badge/v__sla__compliance-1f2937?style=flat) | 1 row per breach | `days_over_sla`, `breach_severity`, resolution status |
| ![v_executive_delivery](https://img.shields.io/badge/v__executive__delivery-1f2937?style=flat) | 1 row per BU | Portfolio, SLA, value, governance, model risk roll-ups |
| ![v_bp_portfolio](https://img.shields.io/badge/v__bp__portfolio-1f2937?style=flat) | 1 row per BP initiative | `composite_readiness_score`, `handoff_ready_flag`, `strategic_risk_flag` |

### audit — quality and observability

| Table | Description |
| --- | --- |
| ![run_log](https://img.shields.io/badge/run__log-1f2937?style=flat) | Pipeline execution history |
| ![dq_check_results](https://img.shields.io/badge/dq__check__results-1f2937?style=flat) | 24 DQ assertions — null, uniqueness, FK, range, business logic |
| ![reconciliation_results](https://img.shields.io/badge/reconciliation__results-1f2937?style=flat) | 16 layer-to-layer row count comparisons (raw → staging → silver) |

---

## Delivery Lifecycle

| Stage | Sequence | SLA Target | Who Owns |
| --- | :---: | --- | --- |
| ![Intake](https://img.shields.io/badge/Intake-3b82f6?style=flat-square) | 1 | 14 days | AI Delivery Lead |
| ![Scoping](https://img.shields.io/badge/Scoping-6366f1?style=flat-square) | 2 | 21 days | AI Delivery Lead + Product Owner |
| ![Development](https://img.shields.io/badge/Development-8b5cf6?style=flat-square) | 3 | 60 days | Data Scientist / ML Engineer |
| ![Validation](https://img.shields.io/badge/Validation-d946ef?style=flat-square) | 4 | 30 days | ML Engineer + Risk |
| ![Staging](https://img.shields.io/badge/Staging-ec4899?style=flat-square) | 5 | 21 days | MLOps / Delivery Manager |
| ![Production](https://img.shields.io/badge/Production-16a34a?style=flat-square) | 6 | Ongoing | MLOps + Model Owner |

An SLA breach is recorded when `actual_days > sla_target_days` for a completed stage. `is_sla_breached` is flagged on the stage record; a corresponding row is inserted into `fact_sla_breach` with the breach reason and escalation status.

**health_status classification** (applied at model level in `v_model_health`):

| Status | Condition |
| --- | --- |
| ![Healthy](https://img.shields.io/badge/Healthy-16a34a?style=flat-square) | `performance_score >= 0.85` AND `drift_status = 'None'` AND bias not flagged |
| ![Monitor](https://img.shields.io/badge/Monitor-3b82f6?style=flat-square) | All other combinations |
| ![At_Risk](https://img.shields.io/badge/At_Risk-f59e0b?style=flat-square) | `drift_status = 'Significant'` OR `bias_assessment IN ('High', 'Review Required')` |
| ![Degraded](https://img.shields.io/badge/Degraded-dc2626?style=flat-square) | `performance_score < 0.80` |

**risk_tier classification:**

| Tier | Description |
| --- | --- |
| ![T1_Critical](https://img.shields.io/badge/T1_Critical-dc2626?style=flat-square) | Customer-facing decisions, regulatory exposure, financial risk |
| ![T2_High](https://img.shields.io/badge/T2_High-f59e0b?style=flat-square) | Material business decisions, internal-facing |
| ![T3_Standard](https://img.shields.io/badge/T3_Standard-eab308?style=flat-square) | Standard analytical and operational use cases |
| ![T4_Low](https://img.shields.io/badge/T4_Low-64748b?style=flat-square) | Experimentation, internal tooling, low-impact automation |

**gate_status** (use-case level in `v_portfolio_summary`): `Clear` when every governance review for the use case is `Approved`. `Blocked` if any review is `Approved with Conditions`, `Pending`, or `Deferred`.

---

## Data & AI Business Partner Operating Model

The Business Partner Portfolio View models how a senior Data & AI Business Partner translates business demand into governed delivery:

```
Business problem intake
  → Value hypothesis
  → Feasibility assessment
  → Organizational readiness
  → Risk and governance triage
  → Roadmap prioritization
  → Delivery handoff
  → Value realization review
  → Reuse opportunity identification
```

Each initiative in `silver.v_bp_portfolio` carries the structured fields a Business Partner uses to evaluate, prioritize, and translate AI opportunities. Reuse candidates are flagged for adjacent functions facing similar problems. This prevents duplicate build effort and accelerates delivery for lower-complexity applications of proven patterns.

### Business Partner Portfolio View (silver.v_bp_portfolio)

| Field | Description |
| --- | --- |
| `business_function` | One of: Finance, Operations, Commercial, HR, Supply Chain, Customer Service |
| `business_partner_role` | Named BP role aligned to the business function |
| `business_problem` | Plain-language problem statement from the business owner |
| `value_hypothesis` | Specific value claim with metric, baseline, and target |
| `estimated_value_usd` | Estimated annual value at full deployment |
| `feasibility_score` | 1 (very low) to 5 (very high) |
| `organizational_readiness_score` | 1 (not ready) to 5 (fully ready) |
| `composite_readiness_score` | Average of feasibility and org readiness, rounded to 1 decimal |
| `risk_tier` | Low / Medium / High / Critical |
| `recommended_solution_pattern` | Architectural recommendation from BP scoping |
| `reuse_candidate_flag` | True if the solution pattern is reusable across functions |
| `delivery_handoff_status` | Not Ready / Ready / In Delivery / Live |
| `handoff_ready_flag` | True if status is Ready, In Delivery, or Live |
| `strategic_risk_flag` | True if risk tier is High/Critical AND feasibility score is 2 or below |
| `success_metric` | Measurable outcome the business owner is accountable for |

---

## Local Setup

### Prerequisites

```
PostgreSQL 14+
Python 3.11+    pip install psycopg2-binary faker numpy
Node.js 18+     (dashboard only)
```

### Database

```
psql -U postgres -c "CREATE DATABASE ai_control_tower;"

# Create schemas
psql -U your_user -d ai_control_tower -c "
  CREATE SCHEMA IF NOT EXISTS raw;
  CREATE SCHEMA IF NOT EXISTS staging;
  CREATE SCHEMA IF NOT EXISTS silver;
  CREATE SCHEMA IF NOT EXISTS audit;"

# Run DDL and seed in order
psql -U your_user -d ai_control_tower -f sql/raw_schema.sql
psql -U your_user -d ai_control_tower -f sql/audit_tables.sql
psql -U your_user -d ai_control_tower -f sql/staging_views.sql
psql -U your_user -d ai_control_tower -f sql/silver_views.sql
psql -U your_user -d ai_control_tower -f sql/seed_data.sql
psql -U your_user -d ai_control_tower -f sql/bp_portfolio.sql
```

### Quality Checks + Export

```
python scripts/run_quality_checks.py --verbose   # exits non-zero on failure
python scripts/export_silver_to_json.py          # writes data/silver/*.json
```

### Dashboard

```
cd dashboard
npm install
npm run dev       # http://localhost:5173
```

### Regenerate Synthetic Data

```
python scripts/generate_synthetic_data.py --reset --use-cases 40 --months 18
python scripts/run_quality_checks.py && python scripts/export_silver_to_json.py
```

---

## Project Structure

```
ai-solution-delivery-control-tower/
│
├── assets/
│   ├── nh-logo-dark.svg           # NH monogram (light fill, for dark backgrounds)
│   └── nh-logo-light.svg          # NH monogram (dark fill, for light backgrounds)
│
├── sql/
│   ├── create_database.sql        # Database + schema creation
│   ├── raw_schema.sql             # Raw tables + indexes (10 tables)
│   ├── audit_tables.sql           # Audit schema (3 tables)
│   ├── staging_views.sql          # Conformance views (10 views)
│   ├── silver_views.sql           # Analytical views with business logic (6 views)
│   ├── bp_portfolio.sql           # BP portfolio table, seed data, and v_bp_portfolio view
│   ├── data_quality_checks.sql    # 24 DQ assertions → audit.dq_check_results
│   ├── reconciliation_checks.sql  # 16 layer-to-layer checks → audit.reconciliation_results
│   └── seed_data.sql              # Deterministic synthetic dataset
│
├── scripts/
│   ├── generate_synthetic_data.py # Faker + numpy data generator (--reset, --use-cases, --months)
│   ├── run_quality_checks.py      # Runs DQ + reconciliation; exits non-zero on failure
│   └── export_silver_to_json.py   # Reads silver + audit → data/silver/*.json
│
├── data/
│   └── silver/                    # JSON exports (gitignored; regenerate with export script)
│       ├── portfolio_summary.json
│       ├── intake_metrics.json
│       ├── governance_status.json
│       ├── model_health.json
│       ├── sla_compliance.json
│       ├── executive_delivery.json
│       ├── bp_portfolio.json
│       ├── audit_dq_results.json
│       ├── audit_reconciliation.json
│       └── audit_run_log.json
│
├── dashboard/
│   ├── package.json               # Vite + React + Recharts + Tailwind
│   └── src/
│       └── App.jsx                # Six-tab React dashboard (incl. Business Partner Portfolio)
│
├── docs/
│   ├── DATA_CONTRACT.md           # Schema definitions and quality thresholds
│   ├── LINEAGE.md                 # Layer-to-layer join graph and derivation map
│   ├── GOVERNANCE_MODEL.md        # Business logic definitions (health_status, gate_status, etc.)
│   ├── architecture.md            # Design principles and component map
│   ├── RUNBOOK.md                 # Setup, refresh, and troubleshooting procedures
│   └── screenshots/               # Dashboard screenshots
│
├── .gitignore
└── README.md
```

---

## Enterprise Target Architecture

This project simulates the analytical layer of a production AI governance platform. In an enterprise context the same data model would sit within a broader stack:

```
Source Systems (Azure SQL, Salesforce, JIRA, ServiceNow)
  │
  ▼ Ingestion (Azure Data Factory / Fivetran)
  │
  ▼ Landing Zone (ADLS Gen2 / S3 — raw Parquet)
  │
  ▼ Compute (Azure Databricks / dbt on Snowflake)
  │   raw → staging → silver  [this project]
  │
  ▼ Serving Layer (Synapse / BigQuery / Snowflake)
  │
  ▼ BI Layer (Power BI / Tableau) + Operational API (FastAPI)
  │
  ▼ Consumers: CAIO dashboard, Risk Committee reports, MLOps alerting
```

The layered schema design, data contract documentation, and audit framework in this project are directly portable to that stack. The primary changes at scale would be: materialising silver on a dbt schedule, partitioning monitoring facts by date, and replacing the static JSON export with a live API or Power BI DirectQuery connection.

---

> All data is synthetic. Names, companies, metrics, and figures are generated for demonstration purposes only and do not represent any real organisation or individual.

---

<div align="center">

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Nicholas_Hidalgo-0a66c2?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/nicholashidalgo)
[![Website](https://img.shields.io/badge/Website-nicholashidalgo.com-4f46e5?style=for-the-badge&logoColor=white)](https://nicholashidalgo.com)
[![Email](https://img.shields.io/badge/Email-analytics@nicholashidalgo.com-16a34a?style=for-the-badge&logo=gmail&logoColor=white)](mailto:analytics@nicholashidalgo.com)

</div>
