# Governance Model

**AI Solution Delivery Control Tower**  
Nicholas Hidalgo | Portfolio Project | Synthetic Data

This document defines the business logic rules applied in the silver layer. These definitions are the authoritative source for any downstream consumer interpreting the derived fields.

---

## health_status (v_model_health)

Classifies a model's operational health based on three signals from `dim_model`: `performance_score`, `drift_status`, and `bias_assessment`. Applied at the model level (not monitoring-row level).

```
Priority order (evaluated top-down):

1. At Risk
   → drift_status = 'Significant'
   OR bias_assessment IN ('High', 'Review Required')

2. Degraded
   → performance_score < 0.80

3. Healthy
   → performance_score >= 0.85
   AND drift_status = 'None'
   AND bias_assessment NOT IN ('High', 'Review Required')

4. Monitor  (default — all other combinations)
```

**Rationale:**
- At Risk takes priority over Degraded because a biased or drifting model presents systemic risk regardless of headline accuracy.
- The Healthy band requires all three conditions to be met simultaneously; a high-performing model with unknown bias assessment falls to Monitor.
- Degraded is a performance-only signal — it does not imply safety risk, but does indicate retraining may be required.

---

## gate_status (v_portfolio_summary, v_governance_status)

Indicates whether a use case has cleared all governance gates required to progress.

### v_portfolio_summary (use-case level)

Aggregates across all governance reviews for a use case:

```
Clear   → COUNT of reviews where outcome IN
          ('Approved with Conditions', 'Pending', 'Deferred') = 0
          (i.e. every review is 'Approved' or the use case has no reviews)

Blocked → any review has outcome IN
          ('Approved with Conditions', 'Pending', 'Deferred')
```

**Rationale:** A conditional approval is not a clearance — the use case must not advance until conditions are met. A single outstanding condition blocks the gate for the entire use case.

### v_governance_status (review level)

Applied per review row:

```
Clear   → review_outcome = 'Approved'
Blocked → all other outcomes
```

---

## days_over_sla (v_sla_compliance, v_portfolio_summary)

The number of calendar days a stage exceeded its SLA target. Computed in-view, not stored.

```
days_over_sla = actual_days − sla_target_days
```

- Always positive in `v_sla_compliance` (breach table only contains breached stages).
- In `v_portfolio_summary`, floored at 0 via GREATEST(days_over_sla, 0) for in-progress stages.

---

## breach_severity (v_sla_compliance)

Categorises how far a stage exceeded its SLA:

| days_over_sla | Severity |
|---|---|
| ≥ 30 days | Critical |
| 14–29 days | High |
| 7–13 days | Medium |
| < 7 days | Low |

---

## review_health (staging.stg_fact_governance_review)

Derived in the staging view (carried through to silver):

```
Overdue   → next_review_date < CURRENT_DATE
Due Soon  → next_review_date < CURRENT_DATE + 14
On Track  → otherwise
N/A       → next_review_date IS NULL
```

---

## Risk Tier Definitions

| Tier | Name | Approval Required | Review Cadence |
|---|---|---|---|
| T1 | Critical | Executive Sponsor + CAIO | Quarterly |
| T2 | High | VP Delivery + Risk Committee | Semi-Annual |
| T3 | Medium | Delivery Lead | Annual |
| T4 | Low | Team Lead | Annual |

T1 and T2 models require governance review before staging promotion. T3 and T4 require review before production deployment.

---

## Stage SLA Targets

| Stage | Sequence | SLA Target (days) |
|---|---|---|
| Intake | 1 | 14 |
| Scoping | 2 | 21 |
| Development | 3 | 60 |
| Validation | 4 | 30 |
| Staging | 5 | 21 |
| Production | 6 | Ongoing (365 review cycle) |

An SLA breach is recorded in `fact_sla_breach` when `actual_days > sla_target_days` for any completed stage. The `is_sla_breached` flag on `fact_ai_delivery_stage` is set at insert time.
