# Interview Talk Track

**AI Solution Delivery Control Tower**  
Nicholas Hidalgo | Portfolio Project | Synthetic Data

Structured answers for common interview questions about this project.

---

## "Walk me through this project."

"This is an end-to-end data platform that simulates how a large enterprise would track, govern, and measure AI use cases across business units — from intake through production deployment.

The database has three layers: a raw schema that mirrors source-system tables, a staging layer of conformance views that clean and normalise the data, and a silver layer of analytical views where the business logic lives — things like classifying a model as Healthy, At Risk, Degraded, or Monitor based on performance score, drift, and bias signals.

On top of that I built 24 data quality checks and 16 reconciliation checks that write results to an audit schema, a Python CLI that runs all of them and exits non-zero on failure — so it's CI-compatible — and a JSON exporter that reads exclusively from the silver views to feed a React dashboard. The dashboard has five tabs covering executive KPIs, the use case pipeline, model health, SLA breaches, and governance reviews."

---

## "Why did you choose views instead of tables for the silver layer?"

"Business logic in views is the right call when the transformation doesn't need materialisation. It means the definition is in one place, it's version-controlled, and any change to the raw data is immediately reflected without a refresh job. If I'd used tables I'd need either a stored procedure or an orchestrator to keep them current, which is operational complexity with no benefit at this scale.

The tradeoff is query time — a complex view with five CTEs will be slower than a pre-materialised table on large datasets. In a production data warehouse I'd materialise on a schedule. Here, the data fits in memory and the exports are generated once, so there's no latency problem to solve."

---

## "How did you handle data quality?"

"Two mechanisms. First, I wrote 24 SQL assertions that check things like null counts on required columns, uniqueness on natural keys, FK orphan detection, score ranges, and business logic invariants — like 'exit_date must be >= entry_date.' Each assertion writes a PASS/FAIL row to an audit table with the expected and actual values so failures are traceable, not just a console log.

Second, I have 16 reconciliation checks that compare row counts between raw and staging, and between staging and silver. Since staging views are 1:1 over raw, the count should always match. If it doesn't, something's wrong with the view logic.

The Python runner executes both sets of checks and exits non-zero on any failure, so you could plug it straight into a CI pipeline."

---

## "What business logic did you implement in silver?"

"Three main derivations.

`health_status` classifies each model into four buckets. At Risk takes priority — it fires when drift is Significant or bias is flagged as High or Review Required, because those are safety signals regardless of headline accuracy. Degraded fires on performance score below 0.80. Healthy requires all three conditions: score above 0.85, no drift, no bias concern. Monitor is the default for everything in between.

`gate_status` is a governance gate aggregation. At the use case level it's Clear only when every governance review for that use case is Approved — no conditions, no pending, no deferred. A single outstanding condition blocks the gate. At the review row level it's simply Clear if the outcome is Approved, Blocked otherwise.

`days_over_sla` is `actual_days minus sla_target_days`, derived in the view — not stored — which means it's always consistent with the source data and can't drift."

---

## "Why static JSON instead of a live database connection in the dashboard?"

"Two reasons. First, it decouples the UI from the database — the dashboard can be hosted on GitHub Pages or any static server with no backend, no connection string, no secrets management. Second, it enforces a clean boundary: the export script is the only thing that touches the database, and it reads only from silver views and audit tables. The dashboard can't accidentally bypass the business logic layer.

The tradeoff is that the data is a snapshot — it doesn't update in real time. For a portfolio project that's fine. In production you'd either schedule the export or serve the silver views through an API."

---

## "What would you do differently at production scale?"

"A few things. I'd materialise the silver views on a schedule — probably with dbt — because the CTEs in `v_executive_delivery` and `v_portfolio_summary` involve multiple subqueries that would be expensive on millions of rows. I'd add partitioning to `fact_model_monitoring` by monitoring_date since that table grows unboundedly. I'd move the quality checks into an orchestrator like Airflow so they run automatically after each load and alert on failure. And I'd replace the static JSON export with a thin API layer — probably FastAPI — so the dashboard can pull live data without a full re-export."

---

## Common Follow-Up Questions

**"What's the difference between staging and silver?"**
Staging is conformance only — trim, coalesce, type cast, no joins, no aggregation. Silver is where the analytical joins and business logic live. The separation means you can change a business rule in silver without touching the conformance logic, and vice versa.

**"How would you add a new metric?"**
Add a column derivation to the relevant silver view, update the data contract doc, re-run the export. The dashboard picks it up automatically on the next JSON fetch. No schema migration needed.

**"What's in the audit schema?"**
Three tables: run_log for pipeline execution history, dq_check_results for quality assertion results, and reconciliation_results for layer-to-layer row count comparisons. All three are exported to JSON alongside the silver data so the dashboard could surface quality metrics if needed.

**"Why PostgreSQL and not a cloud data warehouse?"**
At this scale — 20 use cases, 100 monitoring rows — there's no query performance problem to solve. PostgreSQL has everything I need: CTEs, window functions, stored procedures, schema isolation. I'd move to a warehouse like BigQuery or Snowflake when the data volume or concurrency demands it, not as a default choice.
