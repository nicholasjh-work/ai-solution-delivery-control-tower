"""
run_quality_checks.py
AI Solution Delivery Control Tower — quality check runner.

Executes data_quality_checks.sql and reconciliation_checks.sql against the
database, prints a formatted summary, and exits non-zero if any check fails.

Usage:
    python scripts/run_quality_checks.py [--verbose]
"""

import argparse
import sys
from pathlib import Path

import psycopg2
import psycopg2.extras

DB_DSN = "dbname=ai_control_tower user=nickhidalgo"

SQL_DIR = Path(__file__).parent.parent / "sql"
DQ_SQL  = SQL_DIR / "data_quality_checks.sql"
REC_SQL = SQL_DIR / "reconciliation_checks.sql"


def run_sql_file(cur, path: Path) -> None:
    sql = path.read_text()
    # Strip the trailing SELECT summary so we can read results ourselves
    statements = [s.strip() for s in sql.split(";") if s.strip()]
    for stmt in statements:
        # Skip the summary SELECT at the end of each file
        if stmt.upper().startswith("SELECT"):
            continue
        cur.execute(stmt)


def fetch_dq_results(cur) -> list[dict]:
    cur.execute("""
        SELECT check_name, status, expected, actual, severity
        FROM audit.dq_check_results
        WHERE check_timestamp >= NOW() - INTERVAL '5 minutes'
        ORDER BY status DESC, severity, check_name
    """)
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


def fetch_rec_results(cur) -> list[dict]:
    cur.execute("""
        SELECT check_name, left_count, right_count, difference, status
        FROM audit.reconciliation_results
        WHERE check_timestamp >= NOW() - INTERVAL '5 minutes'
        ORDER BY status DESC, check_name
    """)
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, row)) for row in cur.fetchall()]


def print_section(title: str) -> None:
    print(f"\n{'─' * 70}")
    print(f"  {title}")
    print(f"{'─' * 70}")


def print_dq(rows: list[dict], verbose: bool) -> int:
    fails = [r for r in rows if r["status"] in ("FAIL", "WARN")]
    passes = [r for r in rows if r["status"] == "PASS"]

    if verbose or fails:
        for r in rows:
            icon = "✓" if r["status"] == "PASS" else "✗"
            print(f"  {icon} [{r['severity']:<8}] {r['check_name']}")
            if r["status"] != "PASS" or verbose:
                print(f"           expected: {r['expected']}  |  actual: {r['actual']}")
    else:
        print(f"  All {len(passes)} checks passed.")

    print(f"\n  Summary: {len(passes)} PASS  |  {len(fails)} FAIL/WARN")
    return len(fails)


def print_rec(rows: list[dict], verbose: bool) -> int:
    fails = [r for r in rows if r["status"] != "PASS"]
    passes = [r for r in rows if r["status"] == "PASS"]

    if verbose or fails:
        for r in rows:
            icon = "✓" if r["status"] == "PASS" else "✗"
            diff = r["difference"]
            print(f"  {icon} {r['check_name']}")
            if r["status"] != "PASS" or verbose:
                print(f"           left={r['left_count']}  right={r['right_count']}  diff={diff}")
    else:
        print(f"  All {len(passes)} checks passed.")

    print(f"\n  Summary: {len(passes)} PASS  |  {len(fails)} FAIL")
    return len(fails)


def main():
    parser = argparse.ArgumentParser(description="Run AI Control Tower quality checks.")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Print all checks, not just failures")
    args = parser.parse_args()

    conn = psycopg2.connect(DB_DSN)
    conn.autocommit = False
    cur = conn.cursor()

    total_failures = 0

    try:
        print_section("DATA QUALITY CHECKS")
        run_sql_file(cur, DQ_SQL)
        dq_rows = fetch_dq_results(cur)
        total_failures += print_dq(dq_rows, args.verbose)

        print_section("RECONCILIATION CHECKS")
        run_sql_file(cur, REC_SQL)
        rec_rows = fetch_rec_results(cur)
        total_failures += print_rec(rec_rows, args.verbose)

        conn.commit()

    except Exception as e:
        conn.rollback()
        print(f"\nERROR executing checks: {e}", file=sys.stderr)
        sys.exit(2)
    finally:
        cur.close()
        conn.close()

    print(f"\n{'═' * 70}")
    if total_failures == 0:
        print("  ALL CHECKS PASSED")
    else:
        print(f"  {total_failures} CHECK(S) FAILED — review audit tables for details")
    print(f"{'═' * 70}\n")

    sys.exit(0 if total_failures == 0 else 1)


if __name__ == "__main__":
    main()
