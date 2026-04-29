# Data Lineage

**AI Solution Delivery Control Tower**  
Nicholas Hidalgo | Portfolio Project | Synthetic Data

---

## Layer Flow

```
raw tables
  │
  ├─ staging views (1:1 conformance, no row drop)
  │     │
  │     └─ silver views (joins, business logic derivations)
  │           │
  │           └─ JSON exports  →  React dashboard
  │
  └─ audit tables  ←  DQ checks + reconciliation checks
                        │
                        └─ JSON exports  →  React dashboard
```

No data flows backwards. Silver reads from staging; staging reads from raw. The audit schema is written to by quality check scripts and exported separately.

---

## Raw → Staging (1:1 view mapping)

Every staging view is a direct 1:1 projection of its raw source table. Row counts are equal at all times.

| Staging View | Source Table | Transformations |
|---|---|---|
| `staging.stg_dim_business_unit` | `raw.dim_business_unit` | TRIM, COALESCE(division→'Unassigned'), COALESCE(region→'Global'), timestamp→date |
| `staging.stg_dim_ai_use_case` | `raw.dim_ai_use_case` | TRIM, COALESCE(description→''), CASE normalise priority, created_at→intake_date |
| `staging.stg_dim_risk_tier` | `raw.dim_risk_tier` | TRIM, COALESCE(approval_level, review_frequency) |
| `staging.stg_dim_model` | `raw.dim_model` | TRIM, CASE normalise deployment_env, COALESCE(performance_score→0.0, bias_assessment, drift_status) |
| `staging.stg_dim_owner` | `raw.dim_owner` | TRIM, LOWER(email), COALESCE(email→'') |
| `staging.stg_fact_ai_delivery_stage` | `raw.fact_ai_delivery_stage` | CASE normalise stage_status, COALESCE(actual_days→0), derive days_over_sla |
| `staging.stg_fact_model_monitoring` | `raw.fact_model_monitoring` | COALESCE all score columns, COALESCE alert fields |
| `staging.stg_fact_value_realization` | `raw.fact_value_realization` | COALESCE baseline/realized/target, derive pct_of_target |
| `staging.stg_fact_sla_breach` | `raw.fact_sla_breach` | COALESCE(breach_reason), derive breach_resolution_status |
| `staging.stg_fact_governance_review` | `raw.fact_governance_review` | CASE normalise review_outcome, COALESCE(risk_score→50), derive review_health |

---

## Staging → Silver (join graph)

### v_portfolio_summary

```
stg_dim_ai_use_case        (uc)      — base
  JOIN stg_dim_business_unit (bu)    ON bu.business_unit_id = uc.business_unit_id
  LEFT JOIN CTE: latest_stage        — DISTINCT ON use_case_id, max stage_sequence
      from stg_fact_ai_delivery_stage
  LEFT JOIN CTE: latest_governance   — DISTINCT ON use_case_id, max review_date
      from stg_fact_governance_review
  LEFT JOIN CTE: sla_breach_counts   — COUNT(*) from stg_fact_sla_breach
  LEFT JOIN CTE: gate_status         — CASE on review_outcome from stg_fact_governance_review
```

**Derived columns:**
- `gate_status`: Clear if all reviews for the use case are Approved; Blocked otherwise
- `days_over_sla`: GREATEST(current_days_over_sla, 0) — floors at zero for in-progress stages

---

### v_intake_metrics

```
stg_fact_ai_delivery_stage (s)       — base
  JOIN stg_dim_ai_use_case (uc)      ON uc.use_case_id = s.use_case_id
  JOIN stg_dim_business_unit (bu)    ON bu.business_unit_id = uc.business_unit_id
GROUP BY stage_name, stage_sequence, business_unit_id, unit_name, division, priority
```

**Derived columns:**
- `sla_breach_pct`: 100 * breached_count / use_case_count
- `avg_days_over_sla`: AVG(GREATEST(days_over_sla, 0))

---

### v_governance_status

```
stg_fact_governance_review (gr)      — base
  JOIN stg_dim_ai_use_case (uc)      ON uc.use_case_id = gr.use_case_id
  JOIN stg_dim_business_unit (bu)    ON bu.business_unit_id = uc.business_unit_id
  JOIN stg_dim_risk_tier (rt)        ON rt.risk_tier_id = gr.risk_tier_id
  JOIN stg_dim_owner (o)             ON o.owner_id = gr.reviewer_id
```

**Derived columns:**
- `gate_status`: Clear if review_outcome = 'Approved'; Blocked otherwise (per review row)

---

### v_model_health

```
stg_dim_model (m)                    — base
  JOIN stg_dim_ai_use_case (uc)      ON uc.use_case_id = m.use_case_id
  JOIN stg_dim_business_unit (bu)    ON bu.business_unit_id = uc.business_unit_id
  JOIN stg_dim_risk_tier (rt)        ON rt.risk_tier_id = m.risk_tier_id
  JOIN stg_fact_model_monitoring (mon) ON mon.model_id = m.model_id
```

**Derived columns:**
- `health_status`: four-bucket classification (see GOVERNANCE_MODEL.md)

---

### v_sla_compliance

```
stg_fact_sla_breach (sb)             — base
  JOIN stg_dim_ai_use_case (uc)      ON uc.use_case_id = sb.use_case_id
  JOIN stg_dim_business_unit (bu)    ON bu.business_unit_id = uc.business_unit_id
  JOIN stg_fact_ai_delivery_stage (s) ON s.stage_id = sb.stage_id
  JOIN stg_dim_owner (o)             ON o.owner_id = s.owner_id
```

**Derived columns:**
- `days_over_sla`: actual_days − sla_target_days (not stored; computed in view)
- `breach_severity`: Critical (≥30 days), High (≥14), Medium (≥7), Low (<7)

---

### v_executive_delivery

```
stg_dim_business_unit (bu)           — base
  LEFT JOIN CTE: uc_counts           — use case portfolio counts
  LEFT JOIN CTE: sla_summary         — stage compliance aggregates
  LEFT JOIN CTE: value_summary       — financial realization aggregates
  LEFT JOIN CTE: gov_summary         — governance posture aggregates
  LEFT JOIN CTE: model_health_summary — model risk aggregates
```

Each CTE joins its fact/dim tables back to business_unit via stg_dim_ai_use_case.

---

### v_bp_portfolio

```
raw.dim_bp_portfolio                 — sole source, no staging layer
```

This view reads directly from `raw.dim_bp_portfolio`. The table is populated via
`sql/bp_portfolio.sql` with clean, validated data at insert time. No staging
conformance layer is interposed because the table has no dirty-data risk: all
values are explicitly typed, constrained, and inserted from authoritative seed data
rather than extracted from an external source system.

**Derived columns:**
- `composite_readiness_score`: ROUND((feasibility_score + organizational_readiness_score) / 2.0, 1)
- `handoff_ready_flag`: TRUE when delivery_handoff_status IN ('Ready', 'In Delivery', 'Live')
- `strategic_risk_flag`: TRUE when risk_tier IN ('High', 'Critical') AND feasibility_score <= 2

**Exported as:** `data/silver/bp_portfolio.json` (14 rows)

---

## Audit Layer

`audit.dq_check_results` and `audit.reconciliation_results` are written by:
- `sql/data_quality_checks.sql` (24 checks)
- `sql/reconciliation_checks.sql` (16 checks)

Both are exported via `scripts/export_silver_to_json.py` as `audit_dq_results.json` and `audit_reconciliation.json`.

`audit.run_log` is available for logging ETL runs; not currently written by any automated job in this portfolio version.
