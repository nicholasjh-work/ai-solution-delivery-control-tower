<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/nicholasjh-work/nicholasjh-work/main/nh-logo-light.svg">
    <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/nicholasjh-work/nicholasjh-work/main/nh-logo-dark.svg">
    <img alt="NH" src="https://raw.githubusercontent.com/nicholasjh-work/nicholasjh-work/main/nh-logo-dark.svg" width="80">
  </picture>
</p>

<h1 align="center">AI Solution Delivery Control Tower</h1>
<p align="center"><strong>Enterprise AI portfolio governance — synthetic data · portfolio project</strong></p>

<p align="center">
  <a href="#local-setup"><img src="https://img.shields.io/badge/Demo-Local_Setup-4f46e5?style=for-the-badge&logoColor=white" alt="Demo"></a>
  <img src="https://img.shields.io/badge/License-MIT-0ea5e9?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/DQ_Checks-24_Passing-16a34a?style=for-the-badge" alt="DQ Checks">
  <img src="https://img.shields.io/badge/Silver_Views-6-7c3aed?style=for-the-badge" alt="Silver Views">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/React-61DAFB?style=flat&logo=react&logoColor=black" alt="React">
  <img src="https://img.shields.io/badge/Recharts-22d3ee?style=flat&logoColor=white" alt="Recharts">
  <img src="https://img.shields.io/badge/Tailwind_CSS-06B6D4?style=flat&logo=tailwindcss&logoColor=white" alt="Tailwind">
  <img src="https://img.shields.io/badge/Faker-FF6B35?style=flat&logoColor=white" alt="Faker">
</p>

---

## What This Does

<table>
  <tr>
    <td width="50%" valign="top">
      <h3>📊 Portfolio Visibility</h3>
      <p>Tracks 20 AI use cases across 8 business units through a 6-stage delivery pipeline — Intake → Scoping → Development → Validation → Staging → Production — with SLA targets and breach detection at every stage.</p>
    </td>
    <td width="50%" valign="top">
      <h3>🏛️ Governance Tracking</h3>
      <p>Records governance reviews against a 4-tier risk framework (T1 Critical → T4 Low). Derives <code>gate_status</code> (Clear / Blocked) automatically from review outcomes. Surfaces overdue reviews and critical findings.</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>🤖 Model Health Monitor</h3>
      <p>Classifies each model into <strong>Healthy · Monitor · At Risk · Degraded</strong> based on performance score, drift signal, and bias assessment. 12 months of monthly monitoring history per production model.</p>
    </td>
    <td width="50%" valign="top">
      <h3>💰 Value Realization</h3>
      <p>Captures quarterly financial and operational metrics (baseline → target → realized) with confidence levels and validation status. Aggregated to business unit in the executive view.</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>✅ Data Quality</h3>
      <p>24 DQ assertions and 16 reconciliation checks write results to an <code>audit</code> schema. A Python CLI runner exits non-zero on failure — CI-compatible out of the box.</p>
    </td>
    <td width="50%" valign="top">
      <h3>📱 React Dashboard</h3>
      <p>Five-tab dashboard (Executive Overview, Portfolio, Model Health, SLA Compliance, Governance) reads static JSON exports — no live DB connection required at runtime.</p>
    </td>
  </tr>
</table>

---

## Business Problem

Large enterprises running multiple AI initiatives in parallel face three compounding risks:

1. **Delivery opacity** — no single view of where each use case sits in the pipeline or whether it is on track against SLA targets.
2. **Governance gaps** — risk reviews happen asynchronously, conditions go untracked, and high-risk models reach production without a clear gate clearance record.
3. **Value leakage** — financial and operational benefits are claimed at deployment but rarely measured consistently over time.

This platform simulates the operational data layer that would address all three: a governed, auditable record of delivery, model risk, and realized value — structured for analytics consumption.

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
  │                    derivations (health_status, gate_status, days_over_sla).
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
|---|---|---|
| `dim_business_unit` | 8 | Business units with division and region |
| `dim_ai_use_case` | 20 | AI initiatives with type, priority, current stage |
| `dim_risk_tier` | 4 | T1 Critical → T4 Low governance tiers |
| `dim_model` | 20 | ML models with framework, version, bias and drift signals |
| `dim_owner` | 16 | Delivery owners and reviewers |
| `fact_ai_delivery_stage` | 94 | One row per use case per pipeline stage |
| `fact_model_monitoring` | 104 | Monthly model performance metrics |
| `fact_value_realization` | 28 | Quarterly financial and operational metrics |
| `fact_sla_breach` | 10 | Breached stages with reasons and escalation status |
| `fact_governance_review` | 29 | Risk reviews with outcomes and conditions |

### staging — conformance views

Ten views (`stg_*`) sit 1:1 over the raw tables. Transformations: TRIM on all VARCHAR, COALESCE with documented defaults, CASE normalisation for enums, timestamp → DATE casts. No joins, no aggregation, no business logic.

### silver — analytical views

| View | Grain | Key Derivations |
|---|---|---|
| `v_portfolio_summary` | 1 row per use case | `gate_status`, `days_over_sla`, latest stage + review |
| `v_intake_metrics` | Stage × BU × priority | `sla_breach_pct`, `avg_days_over_sla` |
| `v_governance_status` | 1 row per review | `gate_status` per review, reviewer context |
| `v_model_health` | Model × monitoring date | `health_status`, `breach_severity` |
| `v_sla_compliance` | 1 row per breach | `days_over_sla`, `breach_severity`, resolution status |
| `v_executive_delivery` | 1 row per BU | Portfolio, SLA, value, governance, model risk roll-ups |

### audit — quality and observability

| Table | Description |
|---|---|
| `run_log` | Pipeline execution history |
| `dq_check_results` | 24 DQ assertions — null, uniqueness, FK, range, business logic |
| `reconciliation_results` | 16 layer-to-layer row count comparisons (raw → staging → silver) |

---

## Delivery Lifecycle

| Stage | Sequence | SLA Target | Who Owns |
|---|---|---|---|
| Intake | 1 | 14 days | AI Delivery Lead |
| Scoping | 2 | 21 days | AI Delivery Lead + Product Owner |
| Development | 3 | 60 days | Data Scientist / ML Engineer |
| Validation | 4 | 30 days | ML Engineer + Risk |
| Staging | 5 | 21 days | MLOps / Delivery Manager |
| Production | 6 | Ongoing | MLOps + Model Owner |

An SLA breach is recorded when `actual_days > sla_target_days` for a completed stage. `is_sla_breached` is flagged on the stage record; a corresponding row is inserted into `fact_sla_breach` with the breach reason and escalation status.

**health_status classification** (applied at model level in `v_model_health`):

| Status | Condition |
|---|---|
| At Risk | `drift_status = 'Significant'` OR `bias_assessment IN ('High', 'Review Required')` |
| Degraded | `performance_score < 0.80` |
| Healthy | `performance_score >= 0.85` AND `drift_status = 'None'` AND bias not flagged |
| Monitor | All other combinations |

**gate_status** (use-case level in `v_portfolio_summary`): `Clear` when every governance review for the use case is `Approved`. `Blocked` if any review is `Approved with Conditions`, `Pending`, or `Deferred`.

---

## Local Setup

### Prerequisites

```
PostgreSQL 14+
Python 3.11+    pip install psycopg2-binary faker numpy
Node.js 18+     (dashboard only)
```

### Database

```bash
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
```

### Quality Checks + Export

```bash
python scripts/run_quality_checks.py --verbose   # exits non-zero on failure
python scripts/export_silver_to_json.py          # writes data/silver/*.json
```

### Dashboard

```bash
cd dashboard
npm install
npm run dev       # http://localhost:5173
```

### Regenerate Synthetic Data

```bash
python scripts/generate_synthetic_data.py --reset --use-cases 40 --months 18
python scripts/run_quality_checks.py && python scripts/export_silver_to_json.py
```

---

## Project Structure

```
ai-solution-delivery-control-tower/
│
├── sql/
│   ├── create_database.sql        # Database + schema creation
│   ├── raw_schema.sql             # Raw tables + indexes (10 tables)
│   ├── audit_tables.sql           # Audit schema (3 tables)
│   ├── staging_views.sql          # Conformance views (10 views)
│   ├── silver_views.sql           # Analytical views with business logic (6 views)
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
│       ├── audit_dq_results.json
│       ├── audit_reconciliation.json
│       └── audit_run_log.json
│
├── dashboard/
│   ├── package.json               # Vite + React + Recharts + Tailwind
│   └── src/
│       └── App.jsx                # Five-tab React dashboard
│
├── docs/
│   ├── DATA_CONTRACT.md           # Schema definitions and quality thresholds
│   ├── LINEAGE.md                 # Layer-to-layer join graph and derivation map
│   ├── GOVERNANCE_MODEL.md        # Business logic definitions (health_status, gate_status, etc.)
│   ├── architecture.md            # Design principles and component map
│   ├── RUNBOOK.md                 # Setup, refresh, and troubleshooting procedures
│   ├── resume_translation.md      # Resume bullets and decision rationale
│   └── interview_talk_track.md    # Structured answers for common interview questions
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

<p align="center">
  <a href="https://linkedin.com/in/nicholashidalgo"><img src="https://img.shields.io/badge/LinkedIn-Nicholas_Hidalgo-0a66c2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"></a>
  &nbsp;
  <a href="https://nicholashidalgo.com"><img src="https://img.shields.io/badge/Website-nicholashidalgo.com-4f46e5?style=for-the-badge&logoColor=white" alt="Website"></a>
  &nbsp;
  <a href="mailto:analytics@nicholashidalgo.com"><img src="https://img.shields.io/badge/Email-analytics@nicholashidalgo.com-16a34a?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"></a>
</p>
