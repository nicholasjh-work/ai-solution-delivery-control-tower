"""
export_silver_to_json.py
AI Solution Delivery Control Tower — silver layer JSON exporter.

Reads exclusively from silver views and audit tables.
Writes one JSON file per view into data/silver/.
Intended to feed the React dashboard without a live DB connection.

Usage:
    python scripts/export_silver_to_json.py [--out-dir PATH]
"""

import argparse
import json
import sys
from datetime import date, datetime, timezone
from decimal import Decimal
from pathlib import Path

import psycopg2
import psycopg2.extras

DB_DSN = "dbname=ai_control_tower user=nickhidalgo"

DEFAULT_OUT_DIR = Path(__file__).parent.parent / "data" / "silver"

# Views to export: (source_query, output_filename)
EXPORTS = [
    ("SELECT * FROM silver.v_portfolio_summary  ORDER BY use_case_code",
     "portfolio_summary.json"),
    ("SELECT * FROM silver.v_intake_metrics     ORDER BY stage_sequence, business_unit, priority",
     "intake_metrics.json"),
    ("SELECT * FROM silver.v_governance_status  ORDER BY review_date DESC",
     "governance_status.json"),
    ("SELECT * FROM silver.v_model_health       ORDER BY model_code, monitoring_date",
     "model_health.json"),
    ("SELECT * FROM silver.v_sla_compliance     ORDER BY breach_date DESC",
     "sla_compliance.json"),
    ("SELECT * FROM silver.v_executive_delivery ORDER BY business_unit",
     "executive_delivery.json"),
    # Audit tables are part of the allowed export surface
    ("SELECT * FROM audit.run_log               ORDER BY run_timestamp DESC",
     "audit_run_log.json"),
    ("SELECT * FROM audit.dq_check_results      ORDER BY check_timestamp DESC",
     "audit_dq_results.json"),
    ("SELECT * FROM audit.reconciliation_results ORDER BY check_timestamp DESC",
     "audit_reconciliation.json"),
]


def json_serial(obj):
    """JSON serialiser for types psycopg2 returns that json.dumps can't handle."""
    if isinstance(obj, (date, datetime)):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Type {type(obj)} not serialisable")


def export_query(cur, query: str, out_path: Path) -> int:
    cur.execute(query)
    cols = [d[0] for d in cur.description]
    rows = [dict(zip(cols, row)) for row in cur.fetchall()]
    payload = {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "row_count": len(rows),
        "data": rows,
    }
    out_path.write_text(
        json.dumps(payload, default=json_serial, indent=2, ensure_ascii=False)
    )
    return len(rows)


def main():
    parser = argparse.ArgumentParser(
        description="Export silver views and audit tables to JSON."
    )
    parser.add_argument(
        "--out-dir", type=Path, default=DEFAULT_OUT_DIR,
        help="Directory to write JSON files (default: data/silver/)"
    )
    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)

    conn = psycopg2.connect(DB_DSN)
    conn.autocommit = True
    cur = conn.cursor()

    print(f"Exporting to {args.out_dir}/\n")
    total_rows = 0

    try:
        for query, filename in EXPORTS:
            out_path = args.out_dir / filename
            n = export_query(cur, query, out_path)
            total_rows += n
            print(f"  {filename:<35} {n:>6} rows  →  {out_path}")
    except Exception as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        cur.close()
        conn.close()

    print(f"\nExported {total_rows} total rows across {len(EXPORTS)} files.")


if __name__ == "__main__":
    main()
