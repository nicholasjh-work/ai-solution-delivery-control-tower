# Architecture

**AI Solution Delivery Control Tower**  
Nicholas Hidalgo | Portfolio Project | Synthetic Data

---

## Design Principles

1. **Layered, not flat.** Each layer has a single responsibility: raw stores, staging conforms, silver derives. No layer skips another.
2. **Views over tables in silver.** Business logic lives in SQL views, not in materialised tables or application code. Queries are recomputed from source on demand; the JSON export captures a point-in-time snapshot for the dashboard.
3. **Audit by default.** Quality checks and reconciliation results are persisted to `audit` tables so failures are traceable, not ephemeral.
4. **No gold layer.** This architecture deliberately stops at silver. Aggregated KPIs are computed in the silver views at query time. A gold/reporting layer would add complexity without adding correctness.
5. **Dashboard reads JSON, not the database.** The React dashboard consumes static JSON files exported from silver. This decouples the UI from live DB connectivity and enables hosting on any static server.

---

## Component Map

```
┌──────────────────────────────────────────────────────────────────────┐
│  PostgreSQL: ai_control_tower                                        │
│                                                                      │
│  ┌────────────┐    ┌────────────────┐    ┌───────────────────────┐  │
│  │  raw       │───▶│  staging       │───▶│  silver               │  │
│  │  (tables)  │    │  (views, 1:1)  │    │  (views, joins+logic) │  │
│  └────────────┘    └────────────────┘    └───────────┬───────────┘  │
│                                                      │               │
│  ┌────────────┐◀──────────────────────────────────── │               │
│  │  audit     │  DQ checks + reconciliation          │               │
│  │  (tables)  │                                      │               │
│  └────────────┘                                      │               │
└─────────────────────────────────────────────────────┼───────────────┘
                                                       │
                            scripts/export_silver_to_json.py
                                                       │
                                                       ▼
                                           data/silver/*.json
                                                       │
                                                       ▼
                                           dashboard/src/App.jsx
                                           (React + Tailwind, static)
```

---

## Schema Responsibilities

### raw
- Exact DDL mirror of how data would arrive from a source system (e.g. Azure SQL export, Fivetran landing zone)
- `SERIAL` PKs, FK constraints enforced
- Nulls and dirty values permitted — no business logic
- Populated by: `sql/seed_data.sql` or `scripts/generate_synthetic_data.py`

### staging
- One view per raw table, naming convention: `stg_{table_name}`
- Transformations: TRIM, COALESCE with documented defaults, CASE normalisation, timestamp→date casts
- Row counts are always equal to the raw source
- No joins; no aggregation

### silver
- Six analytical views; each joins multiple staging views
- Business logic defined and documented in `docs/GOVERNANCE_MODEL.md`
- Derived columns: `health_status`, `gate_status`, `days_over_sla`, `breach_severity`, `review_health`
- No DDL tables; no stored procedures; no materialized views

### audit
- `run_log`: pipeline execution history
- `dq_check_results`: one row per DQ assertion per run
- `reconciliation_results`: layer-to-layer row count and aggregate comparisons
- Written by SQL files; exported to JSON alongside silver data

---

## Data Flow Sequence

```
1. seed_data.sql / generate_synthetic_data.py
   → Inserts into raw.* tables

2. staging views
   → Automatically reflect raw on SELECT (no refresh needed)

3. silver views
   → Automatically reflect staging on SELECT

4. sql/data_quality_checks.sql
   → Reads raw.*, writes to audit.dq_check_results

5. sql/reconciliation_checks.sql
   → Reads raw.*, staging.*, silver.*, writes to audit.reconciliation_results

6. scripts/run_quality_checks.py
   → Executes steps 4–5, reports pass/fail, exits non-zero on failure

7. scripts/export_silver_to_json.py
   → Reads silver.v_* and audit.* tables
   → Writes data/silver/*.json

8. dashboard/src/App.jsx
   → fetch() data/silver/*.json
   → Renders five tabbed views
```

---

## Technology Choices

| Component | Technology | Reason |
|---|---|---|
| Database | PostgreSQL 14+ | Full SQL feature set; CTEs, window functions, procedural SQL |
| Silver layer | SQL views | Logic lives in SQL, not application code; recomputed on demand |
| Data generation | Python + Faker + numpy | Faker for realistic text; numpy for normalised distributions |
| Quality checks | SQL + Python runner | Checks stored as SQL for portability; Python runner for CI integration |
| Dashboard | React + Tailwind | Lightweight; no build-time DB dependency; deployable as static files |
| Export format | JSON | Schema-agnostic; readable; no DB connection required at runtime |

---

## What Is Deliberately Out of Scope

- **Orchestration** (Airflow, dbt): not needed for a single-environment portfolio project
- **Gold/reporting layer**: silver views satisfy all dashboard requirements at query time
- **Materialised views**: adds complexity and refresh management; views are sufficient
- **Authentication**: portfolio project; no real data
- **CI/CD**: `scripts/run_quality_checks.py` is CI-ready (exits non-zero on failure) but no pipeline is configured
