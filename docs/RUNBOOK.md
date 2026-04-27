# Runbook

**AI Solution Delivery Control Tower**  
Nicholas Hidalgo | Portfolio Project | Synthetic Data

Operational procedures for maintaining, refreshing, and troubleshooting the project.

---

## Prerequisites

```bash
# PostgreSQL 14+
brew install postgresql@14   # macOS

# Python dependencies
pip install psycopg2-binary faker numpy

# Node (dashboard only)
brew install node
```

---

## Initial Setup (from scratch)

```bash
# 1. Create database
psql -U postgres -c "CREATE DATABASE ai_control_tower;"

# 2. Create schemas
psql -U your_user -d ai_control_tower -c "
  CREATE SCHEMA IF NOT EXISTS raw;
  CREATE SCHEMA IF NOT EXISTS staging;
  CREATE SCHEMA IF NOT EXISTS silver;
  CREATE SCHEMA IF NOT EXISTS audit;
"

# 3. Create raw tables
psql -U your_user -d ai_control_tower -f sql/raw_schema.sql

# 4. Create audit tables
psql -U your_user -d ai_control_tower -f sql/audit_tables.sql

# 5. Create staging views
psql -U your_user -d ai_control_tower -f sql/staging_views.sql

# 6. Create silver views
psql -U your_user -d ai_control_tower -f sql/silver_views.sql

# 7. Load seed data
psql -U your_user -d ai_control_tower -f sql/seed_data.sql

# 8. Run quality checks (should all pass)
python scripts/run_quality_checks.py

# 9. Export to JSON
python scripts/export_silver_to_json.py
```

---

## Refresh Cycle (after data changes)

```bash
# Run checks first — fix any failures before exporting
python scripts/run_quality_checks.py

# If all pass, export
python scripts/export_silver_to_json.py
```

---

## Regenerate Synthetic Data

```bash
# Reset and regenerate with defaults (20 use cases, 12 months monitoring)
python scripts/generate_synthetic_data.py --reset

# Larger dataset
python scripts/generate_synthetic_data.py --reset --use-cases 50 --months 24

# Then check and export
python scripts/run_quality_checks.py && python scripts/export_silver_to_json.py
```

---

## Rebuild Silver Views (after logic change)

```bash
psql -U your_user -d ai_control_tower -f sql/silver_views.sql
```

The DROP/CREATE IF EXISTS pattern at the top of the file handles idempotency.

---

## Rebuild Staging Views (after raw schema change)

```bash
psql -U your_user -d ai_control_tower -f sql/staging_views.sql
# Then rebuild silver (staging views are depended on by silver)
psql -U your_user -d ai_control_tower -f sql/silver_views.sql
```

---

## Run Dashboard

```bash
cd dashboard
npm install       # first time only
npm run dev       # dev server at localhost:5173
```

The dashboard reads from `data/silver/*.json` relative to the Vite dev server root. If the files are missing, run the exporter first.

---

## Troubleshooting

### Quality check fails with "N orphan(s)"

A foreign key in a fact table references a PK that doesn't exist in the dimension. Most common cause: partial reload (e.g. truncating raw facts but not dimensions, or vice versa).

```bash
# Full reset and reload
psql -U your_user -d ai_control_tower -c "
  TRUNCATE raw.fact_governance_review, raw.fact_sla_breach,
           raw.fact_value_realization, raw.fact_model_monitoring,
           raw.fact_ai_delivery_stage, raw.dim_owner, raw.dim_model,
           raw.dim_risk_tier, raw.dim_ai_use_case, raw.dim_business_unit
  RESTART IDENTITY CASCADE;
"
psql -U your_user -d ai_control_tower -f sql/seed_data.sql
```

### "days_over_sla ≤ 0" DQ check fails

A row exists in `fact_sla_breach` where `actual_days <= sla_target_days`. The breach table should only contain stages where `actual_days > sla_target_days`. Check the insert that populated `fact_sla_breach` for stages where `actual_days` was NULL or incorrectly coalesced.

### Silver view returns fewer rows than expected

Check whether the JOIN in the silver view is an INNER JOIN where a LEFT JOIN is needed, or whether staging has rows filtered unexpectedly. Run:

```sql
SELECT COUNT(*) FROM staging.stg_fact_model_monitoring;
SELECT COUNT(*) FROM silver.v_model_health;
-- These should match; if not, check the JOIN conditions in silver_views.sql
```

### Dashboard shows "Failed to load data"

The JSON files in `data/silver/` are missing or the dev server can't find them. Run:

```bash
python scripts/export_silver_to_json.py
ls data/silver/
```

If using Vite, ensure the `data/` directory is inside the directory served as the Vite root (typically the project root or `public/`).

### psycopg2 connection error

Default DSN is `dbname=ai_control_tower user=nickhidalgo`. If your PostgreSQL user differs, update `DB_DSN` at the top of each Python script, or set a `PGUSER` environment variable.

---

## Audit Queries

```sql
-- Last 10 DQ check results
SELECT check_name, status, severity, actual, check_timestamp
FROM audit.dq_check_results
ORDER BY check_timestamp DESC
LIMIT 10;

-- Failed checks only
SELECT * FROM audit.dq_check_results
WHERE status IN ('FAIL', 'WARN')
ORDER BY check_timestamp DESC;

-- Reconciliation failures
SELECT * FROM audit.reconciliation_results
WHERE status != 'PASS'
ORDER BY check_timestamp DESC;

-- Silver view row counts
SELECT 'v_portfolio_summary',  COUNT(*) FROM silver.v_portfolio_summary  UNION ALL
SELECT 'v_intake_metrics',     COUNT(*) FROM silver.v_intake_metrics      UNION ALL
SELECT 'v_governance_status',  COUNT(*) FROM silver.v_governance_status   UNION ALL
SELECT 'v_model_health',       COUNT(*) FROM silver.v_model_health        UNION ALL
SELECT 'v_sla_compliance',     COUNT(*) FROM silver.v_sla_compliance      UNION ALL
SELECT 'v_executive_delivery', COUNT(*) FROM silver.v_executive_delivery;
```
