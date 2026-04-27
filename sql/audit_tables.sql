-- AI Solution Delivery Control Tower
-- Audit schema DDL: run logs, DQ check results, reconciliation results
-- Nicholas Hidalgo | Portfolio Project | Synthetic Data

DROP TABLE IF EXISTS audit.reconciliation_results CASCADE;
DROP TABLE IF EXISTS audit.dq_check_results       CASCADE;
DROP TABLE IF EXISTS audit.run_log                CASCADE;

CREATE TABLE audit.run_log (
    run_id              SERIAL PRIMARY KEY,
    run_timestamp       TIMESTAMP    NOT NULL DEFAULT NOW(),
    step                VARCHAR(100) NOT NULL,
    status              VARCHAR(20)  NOT NULL DEFAULT 'Running',
    records_processed   INT,
    duration_seconds    NUMERIC(10,2),
    error_message       TEXT,
    initiated_by        VARCHAR(100)
);

CREATE TABLE audit.dq_check_results (
    check_id            SERIAL PRIMARY KEY,
    check_name          VARCHAR(100) NOT NULL,
    check_timestamp     TIMESTAMP    NOT NULL DEFAULT NOW(),
    status              VARCHAR(10)  NOT NULL,
    expected            TEXT,
    actual              TEXT,
    severity            VARCHAR(20)  NOT NULL DEFAULT 'Error',
    notes               TEXT
);

CREATE TABLE audit.reconciliation_results (
    check_id            SERIAL PRIMARY KEY,
    check_name          VARCHAR(100) NOT NULL,
    check_timestamp     TIMESTAMP    NOT NULL DEFAULT NOW(),
    left_count          INT,
    right_count         INT,
    difference          INT,
    status              VARCHAR(10)  NOT NULL,
    notes               TEXT
);
