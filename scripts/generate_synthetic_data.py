"""
generate_synthetic_data.py
AI Solution Delivery Control Tower — synthetic data generator.

Generates realistic, referentially consistent data and loads it into the
raw schema of ai_control_tower. Uses Faker for names/text and numpy for
statistically normalised day distributions.

Usage:
    python scripts/generate_synthetic_data.py [--use-cases N] [--months M] [--reset]

    --use-cases N   Number of AI use cases to generate (default: 20)
    --months M      Months of monitoring history per production model (default: 12)
    --reset         Truncate all raw tables before inserting
"""

import argparse
import random
import sys
from datetime import date, timedelta
from decimal import Decimal

import numpy as np
import psycopg2
import psycopg2.extras
from faker import Faker

# ── Config ────────────────────────────────────────────────────────────────────

DB_DSN = "dbname=ai_control_tower user=nickhidalgo"

STAGE_PIPELINE = [
    ("Intake",      1, 14),
    ("Scoping",     2, 21),
    ("Development", 3, 60),
    ("Validation",  4, 30),
    ("Staging",     5, 21),
    ("Production",  6, 365),
]

USE_CASE_TYPES = [
    "Predictive", "Forecasting", "Classification", "NLP",
    "Recommender", "Optimization", "Graph ML", "Analytics",
]

PRIORITIES = ["High", "High", "Medium", "Medium", "Medium", "Low"]

MODEL_TYPES = [
    "XGBoost", "Random Forest", "LSTM", "Transformer", "BERT",
    "Gradient Boosting", "Logistic Regression", "Prophet", "SARIMAX",
    "Isolation Forest", "Collaborative Filter", "GNN", "LLM",
]

FRAMEWORKS = [
    "scikit-learn", "TensorFlow", "PyTorch", "HuggingFace",
    "LightGBM", "XGBoost", "statsmodels", "Facebook Prophet",
    "Azure OpenAI", "OpenAI API", "RLlib", "PyTorch Geometric",
]

BIAS_VALUES = ["Low", "Low", "Medium", "High", "Not Assessed"]

DRIFT_VALUES = ["None", "None", "None", "Low", "Medium", "Significant"]

DEPLOYMENT_ENVS = ["Development", "Staging", "Staging", "Production"]

REVIEWER_ROLES = [
    "AI Delivery Lead", "Data Science Manager", "ML Engineer",
    "AI Product Owner", "Risk & Compliance Lead", "Senior Data Scientist",
    "AI Delivery Manager", "ML Operations Engineer",
    "Governance & Ethics Lead", "Data Engineering Lead",
    "AI Strategy Director", "Model Risk Analyst",
]

REVIEW_TYPES = [
    "Initial Risk Assessment", "Annual Review",
    "Interim Review", "Follow-up Review",
]

REVIEW_OUTCOMES = [
    "Approved", "Approved", "Approved",
    "Approved with Conditions", "Deferred",
]

METRIC_CATEGORIES = ["Financial", "Operational"]

METRIC_NAMES_FIN = [
    "Cost Savings", "Revenue Retained", "Fraud Losses Prevented",
    "Downtime Avoidance", "Cost Avoidance", "Efficiency Gains",
]

METRIC_NAMES_OPS = [
    "Cycle Time Reduction", "Throughput Improvement", "Error Rate Reduction",
    "CSAT Score Improvement", "Attrition Rate", "Stockout Rate",
]

BREACH_REASONS = [
    "Scope creep: additional requirements added mid-sprint",
    "Data access delayed due to governance approval backlog",
    "Model performance below threshold; required additional training iterations",
    "Third-party data pipeline schema change required rebuild",
    "GPU resource contention on shared compute cluster",
    "Legal review of training data took longer than estimated",
    "Stakeholder availability constrained sign-off timeline",
    "Infrastructure provisioning delayed by procurement cycle",
    "Annotated training dataset sourcing required additional budget approval",
    "Model council requested explainability layer not in original scope",
]

fake = Faker()
rng = np.random.default_rng(42)


# ── Helpers ───────────────────────────────────────────────────────────────────

def rand_days(mean: int, std_pct: float = 0.25) -> int:
    """Return a positive integer day count drawn from a normal distribution."""
    std = mean * std_pct
    return max(1, int(rng.normal(mean, std)))


def rand_date_after(d: date, mean_days: int) -> date:
    return d + timedelta(days=rand_days(mean_days))


def pick(seq):
    return random.choice(seq)


def breached(actual: int, target: int) -> bool:
    return actual > target


# ── Loaders ───────────────────────────────────────────────────────────────────

def load_business_units(cur, n: int = 8):
    divisions = ["Corporate Functions", "Commercial", "Enterprise Operations",
                 "Technology", "Risk & Compliance"]
    regions = ["North America", "Europe", "APAC", "Global", "LATAM"]
    rows = []
    used_codes = set()
    for i in range(n):
        code = fake.unique.lexify("???").upper()
        while code in used_codes:
            code = fake.unique.lexify("???").upper()
        used_codes.add(code)
        rows.append((
            code,
            fake.bs().title()[:95],
            pick(divisions),
            pick(regions),
        ))
    cur.executemany(
        "INSERT INTO raw.dim_business_unit (unit_code, unit_name, division, region) "
        "VALUES (%s, %s, %s, %s)",
        rows,
    )
    cur.execute("SELECT business_unit_id FROM raw.dim_business_unit")
    return [r[0] for r in cur.fetchall()]


def load_risk_tiers(cur):
    tiers = [
        ("T1", "Critical",  "High-impact models with regulatory or financial exposure",
         "Executive Sponsor + CAIO", "Quarterly"),
        ("T2", "High",      "Significant business impact; requires VP-level governance",
         "VP Delivery + Risk Committee", "Semi-Annual"),
        ("T3", "Medium",    "Moderate risk; internal use with limited downstream impact",
         "Delivery Lead", "Annual"),
        ("T4", "Low",       "Experimental or sandbox; no production exposure",
         "Team Lead", "Annual"),
    ]
    cur.executemany(
        "INSERT INTO raw.dim_risk_tier "
        "(tier_code, tier_name, description, approval_level, review_frequency) "
        "VALUES (%s, %s, %s, %s, %s)",
        tiers,
    )
    cur.execute("SELECT risk_tier_id FROM raw.dim_risk_tier ORDER BY tier_code")
    return [r[0] for r in cur.fetchall()]


def load_owners(cur, bu_ids: list, n: int = 16):
    rows = []
    for _ in range(n):
        rows.append((
            fake.name()[:99],
            pick(REVIEWER_ROLES),
            pick(bu_ids),
            fake.company_email().lower()[:149],
            True,
        ))
    cur.executemany(
        "INSERT INTO raw.dim_owner "
        "(owner_name, owner_role, business_unit_id, email, is_active) "
        "VALUES (%s, %s, %s, %s, %s)",
        rows,
    )
    cur.execute("SELECT owner_id FROM raw.dim_owner")
    return [r[0] for r in cur.fetchall()]


def load_use_cases(cur, bu_ids: list, n: int = 20):
    rows = []
    used_codes = set()
    # Derive a realistic current_stage distribution: some in each stage
    stage_weights = [0.05, 0.05, 0.15, 0.15, 0.20, 0.40]
    stages = [s[0] for s in STAGE_PIPELINE]
    for i in range(n):
        code = f"UC-{fake.lexify('???').upper()}-{str(i+1).zfill(3)}"
        while code in used_codes:
            code = f"UC-{fake.lexify('???').upper()}-{str(i+1).zfill(3)}"
        used_codes.add(code)
        current = rng.choice(stages, p=stage_weights)
        rows.append((
            code,
            fake.bs().title()[:195],
            pick(bu_ids),
            pick(USE_CASE_TYPES),
            fake.sentence(nb_words=12)[:499],
            pick(PRIORITIES),
            current,
        ))
    cur.executemany(
        "INSERT INTO raw.dim_ai_use_case "
        "(use_case_code, use_case_name, business_unit_id, use_case_type, "
        "description, priority, current_stage) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s)",
        rows,
    )
    cur.execute("SELECT use_case_id, current_stage FROM raw.dim_ai_use_case")
    return cur.fetchall()


def load_models(cur, use_cases: list, risk_tier_ids: list):
    # Weight: most use cases are T3/T4, fewer T1
    tier_weights = [0.10, 0.25, 0.45, 0.20]
    rows = []
    used_codes = set()
    for uc_id, current_stage in use_cases:
        code = f"MDL-{fake.lexify('????').upper()}"
        while code in used_codes:
            code = f"MDL-{fake.lexify('????').upper()}"
        used_codes.add(code)
        env = current_stage if current_stage in ("Production", "Staging", "Development") \
              else "Development"
        tier = rng.choice(risk_tier_ids, p=tier_weights)
        rows.append((
            code,
            f"{fake.word().title()} {pick(MODEL_TYPES)} Model"[:195],
            uc_id,
            pick(MODEL_TYPES),
            pick(FRAMEWORKS),
            f"{rng.integers(1, 5)}.{rng.integers(0, 9)}",
            int(tier),
            env,
            float(round(rng.uniform(0.70, 0.98), 4)),
            pick(BIAS_VALUES),
            pick(DRIFT_VALUES),
            env == "Production",
        ))
    cur.executemany(
        "INSERT INTO raw.dim_model "
        "(model_code, model_name, use_case_id, model_type, framework, version, "
        "risk_tier_id, deployment_env, performance_score, bias_assessment, "
        "drift_status, is_active) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
        rows,
    )
    cur.execute("SELECT model_id, use_case_id FROM raw.dim_model")
    return cur.fetchall()


def load_delivery_stages(cur, use_cases: list, owner_ids: list):
    """
    For each use case, generate pipeline stages up to current_stage.
    Uses normally-distributed day counts so stages vary realistically.
    Returns a list of (stage_id, use_case_id, is_sla_breached).
    """
    stage_name_to_seq = {s[0]: s[1] for s in STAGE_PIPELINE}
    stage_sla = {s[0]: s[2] for s in STAGE_PIPELINE}

    all_rows = []
    start_date = date(2023, 1, 1)

    for uc_id, current_stage in use_cases:
        current_seq = stage_name_to_seq[current_stage]
        entry = start_date + timedelta(days=int(rng.integers(0, 365)))
        for stage_name, seq, sla_target in STAGE_PIPELINE:
            if seq > current_seq:
                break
            actual_days = rand_days(sla_target, std_pct=0.30)
            is_in_progress = (seq == current_seq)
            if is_in_progress:
                exit_d = None
                actual_days_stored = None
            else:
                exit_d = entry + timedelta(days=actual_days)
                actual_days_stored = actual_days
            sla_breached = (not is_in_progress) and breached(actual_days, sla_target)
            all_rows.append((
                uc_id,
                pick(owner_ids),
                stage_name,
                seq,
                entry,
                exit_d,
                actual_days_stored,
                sla_target,
                "In Progress" if is_in_progress else "Completed",
                "",
                sla_breached,
            ))
            if exit_d:
                entry = exit_d

    cur.executemany(
        "INSERT INTO raw.fact_ai_delivery_stage "
        "(use_case_id, owner_id, stage_name, stage_sequence, entry_date, exit_date, "
        "actual_days, sla_target_days, stage_status, exit_reason, is_sla_breached) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
        all_rows,
    )
    cur.execute(
        "SELECT stage_id, use_case_id, is_sla_breached, actual_days, "
        "sla_target_days, exit_date, entry_date "
        "FROM raw.fact_ai_delivery_stage"
    )
    return cur.fetchall()


def load_sla_breaches(cur, stages: list):
    breach_rows = [
        s for s in stages if s[2]  # is_sla_breached
    ]
    rows = []
    for stage_id, uc_id, _, actual_days, sla_target, exit_date, entry_date in breach_rows:
        breach_date = exit_date if exit_date else (entry_date + timedelta(days=sla_target))
        escalated = random.random() < 0.4
        rows.append((
            stage_id,
            uc_id,
            breach_date,
            sla_target,
            actual_days,
            actual_days - sla_target,
            pick(BREACH_REASONS),
            escalated,
            fake.name() if escalated else "",
            (breach_date + timedelta(days=int(rng.integers(5, 45)))) if random.random() < 0.6 else None,
        ))
    if rows:
        cur.executemany(
            "INSERT INTO raw.fact_sla_breach "
            "(stage_id, use_case_id, breach_date, sla_target_days, actual_days, "
            "days_over_sla, breach_reason, escalated, escalated_to, resolved_date) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            rows,
        )


def load_monitoring(cur, models: list, months: int = 12):
    rows = []
    prod_start = date.today() - timedelta(days=30 * months)
    for model_id, _ in models:
        d = prod_start
        while d <= date.today():
            alert = random.random() < 0.12
            rows.append((
                model_id,
                d,
                float(round(rng.uniform(0.78, 0.98), 4)),
                float(round(rng.uniform(0.76, 0.97), 4)),
                float(round(rng.uniform(0.74, 0.97), 4)),
                float(round(rng.uniform(0.75, 0.97), 4)),
                float(round(rng.uniform(0.00, 0.20), 4)),
                float(round(rng.uniform(0.88, 1.00), 4)),
                int(rng.integers(500, 25000)),
                alert,
                pick(["Data Drift", "Performance Degradation", "Data Quality", "Volume Spike"]) if alert else "None",
                pick(["Low", "Medium", "High"]) if alert else "None",
                random.random() < 0.07,
            ))
            d = d + timedelta(days=30)
    cur.executemany(
        "INSERT INTO raw.fact_model_monitoring "
        "(model_id, monitoring_date, accuracy_score, precision_score, recall_score, "
        "f1_score, drift_score, data_quality_score, prediction_volume, alert_triggered, "
        "alert_type, alert_severity, retrain_required) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
        rows,
    )


def load_value_realization(cur, use_cases: list):
    prod_uc = [uc_id for uc_id, stage in use_cases if stage == "Production"]
    rows = []
    for uc_id in prod_uc:
        for qtr in range(1, 5):
            m_date = date(2024, qtr * 3, 1)
            for _ in range(random.randint(1, 3)):
                category = pick(METRIC_CATEGORIES)
                metric = pick(METRIC_NAMES_FIN if category == "Financial" else METRIC_NAMES_OPS)
                baseline = float(round(rng.uniform(50000, 2000000) if category == "Financial"
                                       else rng.uniform(1, 100), 2))
                target = float(round(baseline * rng.uniform(1.1, 2.0), 2))
                realized = float(round(target * rng.uniform(0.75, 1.20), 2))
                rows.append((
                    uc_id,
                    m_date,
                    f"Q{qtr}-2024",
                    metric,
                    category,
                    baseline,
                    realized,
                    target,
                    "USD" if category == "Financial" else pick(["%", "Units", "Minutes", "Score"]),
                    pick(["High", "Medium", "Low"]),
                    random.random() < 0.7,
                    fake.name() if random.random() < 0.7 else "",
                ))
    if rows:
        cur.executemany(
            "INSERT INTO raw.fact_value_realization "
            "(use_case_id, measurement_date, measurement_period, metric_name, "
            "metric_category, baseline_value, realized_value, target_value, "
            "unit_of_measure, confidence_level, is_validated, validated_by) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            rows,
        )


def load_governance(cur, use_cases: list, risk_tier_ids: list, owner_ids: list):
    rows = []
    for uc_id, _ in use_cases:
        tier = int(rng.choice(risk_tier_ids, p=[0.10, 0.25, 0.45, 0.20]))
        review_date = date(2023, 1, 1) + timedelta(days=int(rng.integers(0, 365)))
        outcome = pick(REVIEW_OUTCOMES)
        next_review = (review_date + timedelta(days=365)) if outcome == "Approved" \
                      else (review_date + timedelta(days=180))
        rows.append((
            uc_id,
            tier,
            "Initial Risk Assessment",
            review_date,
            pick(owner_ids),
            outcome,
            int(rng.integers(10, 90)),
            int(rng.integers(0, 5)),
            int(rng.integers(0, 2)),
            "Conditions noted." if outcome == "Approved with Conditions" else "",
            next_review,
        ))
        # Some use cases get an annual follow-up
        if random.random() < 0.4:
            second_date = review_date + timedelta(days=365)
            rows.append((
                uc_id,
                tier,
                "Annual Review",
                second_date,
                pick(owner_ids),
                pick(["Approved", "Approved", "Approved with Conditions"]),
                int(rng.integers(10, 70)),
                int(rng.integers(0, 3)),
                0,
                "",
                second_date + timedelta(days=365),
            ))
    cur.executemany(
        "INSERT INTO raw.fact_governance_review "
        "(use_case_id, risk_tier_id, review_type, review_date, reviewer_id, "
        "review_outcome, risk_score, findings_count, critical_findings, "
        "conditions, next_review_date) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
        rows,
    )


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Generate synthetic AI control tower data.")
    parser.add_argument("--use-cases", type=int, default=20)
    parser.add_argument("--months", type=int, default=12)
    parser.add_argument("--reset", action="store_true",
                        help="Truncate all raw tables before inserting")
    args = parser.parse_args()

    conn = psycopg2.connect(DB_DSN)
    conn.autocommit = False
    cur = conn.cursor()

    try:
        if args.reset:
            print("Truncating raw tables...")
            cur.execute("""
                TRUNCATE raw.fact_governance_review, raw.fact_sla_breach,
                         raw.fact_value_realization, raw.fact_model_monitoring,
                         raw.fact_ai_delivery_stage, raw.dim_owner, raw.dim_model,
                         raw.dim_risk_tier, raw.dim_ai_use_case, raw.dim_business_unit
                RESTART IDENTITY CASCADE
            """)

        print("Loading business units...")
        bu_ids = load_business_units(cur, n=8)

        print("Loading risk tiers...")
        rt_ids = load_risk_tiers(cur)

        print("Loading owners...")
        owner_ids = load_owners(cur, bu_ids, n=16)

        print(f"Loading {args.use_cases} use cases...")
        use_cases = load_use_cases(cur, bu_ids, n=args.use_cases)

        print("Loading models...")
        models = load_models(cur, use_cases, rt_ids)

        print("Loading delivery stages...")
        stages = load_delivery_stages(cur, use_cases, owner_ids)

        print("Loading SLA breaches...")
        load_sla_breaches(cur, stages)

        print(f"Loading {args.months} months of model monitoring...")
        load_monitoring(cur, models, months=args.months)

        print("Loading value realization metrics...")
        load_value_realization(cur, use_cases)

        print("Loading governance reviews...")
        load_governance(cur, use_cases, rt_ids, owner_ids)

        conn.commit()
        print("\nDone. Row counts:")

        for table in [
            "dim_business_unit", "dim_ai_use_case", "dim_risk_tier",
            "dim_model", "dim_owner", "fact_ai_delivery_stage",
            "fact_model_monitoring", "fact_value_realization",
            "fact_sla_breach", "fact_governance_review",
        ]:
            cur.execute(f"SELECT COUNT(*) FROM raw.{table}")
            print(f"  raw.{table}: {cur.fetchone()[0]}")

    except Exception as e:
        conn.rollback()
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
