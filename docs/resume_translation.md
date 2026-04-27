# Resume Translation Guide

**AI Solution Delivery Control Tower**  
Nicholas Hidalgo | Portfolio Project | Synthetic Data

This document maps project components to resume bullets and explains the engineering decisions behind each so you can defend them in an interview.

---

## Resume Bullets

### Data Engineering

> Designed and implemented a three-layer data architecture (raw / staging / silver) in PostgreSQL for an AI portfolio governance platform, including 10 source tables, 10 conformance views, and 6 analytical views embedding business logic for model health classification and governance gate status.

> Built a layered SQL pipeline with explicit data contracts: staging views enforce type casting, null handling, and enum normalisation; silver views apply business logic derivations (health_status, gate_status, days_over_sla) as documented, testable rules — not application code.

> Authored 24 data quality checks and 16 layer-to-layer reconciliation checks persisted to an audit schema; integrated into a Python CLI runner that exits non-zero on failure, making the checks CI-compatible.

> Developed a synthetic data generator (Python + Faker + numpy) producing statistically realistic pipeline stage durations using normally-distributed day sampling, role-labelled reviewers, and referentially consistent FK relationships across 10 tables.

---

### Analytics Engineering

> Modelled six silver-layer analytical views serving an executive dashboard: `v_portfolio_summary` (use case lifecycle + gate status), `v_model_health` (four-bucket health classification), `v_executive_delivery` (BU-level KPI roll-up), `v_sla_compliance` (breach log + severity), `v_governance_status` (review outcomes + gate), `v_intake_metrics` (pipeline funnel).

> Wrote a JSON exporter script that reads exclusively from silver views and audit tables to produce static files consumed by a React dashboard — decoupling the UI from live database connectivity.

---

### Dashboard / Visualisation

> Built a React + Tailwind five-tab dashboard consuming static JSON exports: Executive Overview (portfolio KPIs, BU table), Portfolio (filterable use case list), Model Health (latest health status per model), SLA Compliance (breach log), Governance (review outcomes with overdue alerts).

---

## Technical Decisions to Defend

### Why views instead of tables for silver?

Silver is an analytical layer, not a serving layer. Business logic in SQL views means:
- The definition is in one place and version-controlled
- Any change to raw data is immediately reflected without a refresh job
- The logic is testable by running a SELECT
- No ETL job is needed to keep silver in sync

A table-based silver layer would require a stored procedure or Airflow DAG to keep it current — adding operational complexity with no benefit in this architecture.

### Why no gold layer?

The silver views already provide the aggregations the dashboard needs (`v_executive_delivery` is the "gold" roll-up). Adding a separate gold schema would duplicate logic and introduce another layer to maintain. The principle here is: add a layer only when it provides a distinct capability, not to match a naming convention.

### Why static JSON instead of a live DB API?

The dashboard is a portfolio artefact. Serving it as a static site means:
- No server to manage
- No DB connection string in a deployed frontend
- Reproducible: the JSON captures a known, verified snapshot
- The export script is the integration point — it enforces that only silver and audit tables are exposed

### Why PostgreSQL instead of a data warehouse?

For a single-developer portfolio project, PostgreSQL provides everything needed: CTEs, window functions, stored procedures, schema isolation. A warehouse like BigQuery or Snowflake would be appropriate when the data volume or concurrency demands it — not as a default choice.

### Why normalised days in the generator?

Using `numpy.random.normal(mean, std)` for stage durations produces a realistic spread around the SLA target. A uniform distribution would produce unrealistically flat data; a constant would produce no variance. The 25% std_pct default means roughly two-thirds of stages land within one SLA unit of the target — reflecting real delivery patterns.

---

## Scope Decisions (what was intentionally left out)

| Omitted | Reason |
|---|---|
| Orchestration (Airflow, dbt) | Adds operational complexity; overkill for a single-node portfolio project |
| Materialised views | No query performance problem to solve; views are sufficient |
| ORM or API layer | Not needed; dashboard reads flat JSON |
| Authentication / RBAC | No real data; portfolio demo only |
| Test suite (pytest) | SQL checks serve this purpose; Python scripts are thin wrappers |
| Multi-environment config | Single local DB; no deployment pipeline in scope |
