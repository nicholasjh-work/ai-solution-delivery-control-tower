-- AI Solution Delivery Control Tower
-- Business Partner Portfolio: raw table, seed data, and silver view
-- Models the Data & AI Business Partner operating model:
--   intake -> value hypothesis -> feasibility -> org readiness ->
--   risk/governance triage -> roadmap prioritization ->
--   delivery handoff -> value realization review -> reuse identification
-- Nicholas Hidalgo | Portfolio Project | Synthetic Data

-- ── Raw table ─────────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS raw.dim_bp_portfolio CASCADE;

CREATE TABLE raw.dim_bp_portfolio (
    bp_id                       SERIAL          PRIMARY KEY,
    business_unit               VARCHAR(100)    NOT NULL,
    business_function           VARCHAR(50)     NOT NULL,
    business_partner_role       VARCHAR(100)    NOT NULL,
    business_problem            TEXT            NOT NULL,
    value_hypothesis            TEXT            NOT NULL,
    estimated_value_usd         NUMERIC(15,2)   NOT NULL,
    feasibility_score           INT             NOT NULL CHECK (feasibility_score BETWEEN 1 AND 5),
    organizational_readiness_score INT          NOT NULL CHECK (organizational_readiness_score BETWEEN 1 AND 5),
    risk_tier                   VARCHAR(20)     NOT NULL CHECK (risk_tier IN ('Low','Medium','High','Critical')),
    recommended_solution_pattern VARCHAR(100)   NOT NULL,
    reuse_candidate_flag        BOOLEAN         NOT NULL DEFAULT FALSE,
    delivery_handoff_status     VARCHAR(20)     NOT NULL
                                    CHECK (delivery_handoff_status IN
                                           ('Not Ready','Ready','In Delivery','Live')),
    success_metric              TEXT            NOT NULL,
    roadmap_quarter             VARCHAR(10),
    intake_date                 DATE            NOT NULL DEFAULT CURRENT_DATE,
    created_at                  TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- ── Seed data: 14 initiatives across 6 business functions ─────────────────────

INSERT INTO raw.dim_bp_portfolio (
    business_unit, business_function, business_partner_role,
    business_problem, value_hypothesis, estimated_value_usd,
    feasibility_score, organizational_readiness_score,
    risk_tier, recommended_solution_pattern, reuse_candidate_flag,
    delivery_handoff_status, success_metric, roadmap_quarter, intake_date
) VALUES

-- Finance (3)
(
    'Finance & Accounting', 'Finance',
    'Data & AI Business Partner, Finance',
    'Accounts payable team manually reviews 40,000 invoices per month to detect duplicate payments and billing errors. Current error detection rate is 68 percent and the process consumes 2.4 FTE.',
    'An ML-based invoice anomaly detection model applied at point of receipt will increase error detection to above 92 percent, reduce manual review volume by 70 percent, and recover an estimated $1.8M annually in prevented duplicate payments.',
    1800000.00, 4, 3, 'High',
    'Supervised classification with rules overlay', TRUE,
    'Live', 'Error detection rate >= 92%; manual review FTE reduction >= 1.5', 'Q1-2024', '2023-09-15'
),
(
    'Finance & Accounting', 'Finance',
    'Data & AI Business Partner, Finance',
    'The 13-week cash flow forecast is produced manually in Excel using historical averages and static seasonal adjustments. Forecast error averages 18 percent, causing suboptimal short-term investment and liquidity decisions.',
    'An ML-driven rolling cash flow model incorporating accounts receivable aging, payment history, and external signals will reduce forecast error to below 8 percent, enabling the treasury team to optimize $40M in short-term instrument allocation.',
    620000.00, 3, 3, 'High',
    'Time-series regression with ensemble layer', FALSE,
    'In Delivery', 'Mean absolute percentage error <= 8% on 13-week horizon', 'Q2-2024', '2024-01-10'
),
(
    'Finance & Accounting', 'Finance',
    'Data & AI Business Partner, Finance',
    'General ledger coding requires finance analysts to manually assign GL account codes to 15,000 journal entries per month. Miscoding rate is 6 percent, triggering restatements and audit findings.',
    'A natural language classification model trained on five years of journal entry descriptions and validated GL codes will automate coding for 80 percent of entries with above 95 percent accuracy, reducing analyst time by 1.2 FTE and eliminating recurring audit findings.',
    410000.00, 4, 4, 'Medium',
    'NLP text classification (DistilBERT)', TRUE,
    'Live', 'Automation rate >= 80%; coding accuracy >= 95%; audit findings = 0', 'Q3-2024', '2024-03-20'
),

-- Operations (2)
(
    'Operations & Supply Chain', 'Operations',
    'Data & AI Business Partner, Operations',
    'Unplanned equipment downtime at three manufacturing sites costs an estimated $4.2M per year. Maintenance is scheduled on fixed intervals regardless of actual equipment condition, leading to both over-maintenance and unexpected failures.',
    'A predictive maintenance model using vibration, temperature, and run-time sensor data will identify failure signatures 72 hours in advance with above 85 percent recall, enabling condition-based maintenance that reduces unplanned downtime by 60 percent.',
    2500000.00, 3, 2, 'High',
    'Time-series anomaly detection with LSTM', FALSE,
    'In Delivery', 'Unplanned downtime reduction >= 60%; false positive rate <= 15%', 'Q2-2024', '2023-11-05'
),
(
    'Operations & Supply Chain', 'Operations',
    'Data & AI Business Partner, Operations',
    'Last-mile delivery routing is managed through a legacy system that does not account for real-time traffic, delivery time windows, or driver shift constraints. On-time delivery rate is 81 percent against a customer commitment of 95 percent.',
    'A reinforcement learning route optimization engine incorporating real-time traffic feeds, time-window constraints, and driver availability will improve on-time delivery to above 94 percent and reduce fuel cost by 12 percent across the fleet.',
    1100000.00, 2, 2, 'Medium',
    'Reinforcement learning (constraint-based routing)', FALSE,
    'Not Ready', 'On-time delivery rate >= 94%; fuel cost per delivery reduction >= 10%', 'Q4-2024', '2024-02-14'
),

-- Commercial (2)
(
    'Marketing & Growth', 'Commercial',
    'Data & AI Business Partner, Commercial',
    'Customer churn in the core subscription segment runs at 8.4 percent annually. The retention team contacts all customers equally at renewal, with no signal on which customers are at elevated flight risk. Conversion rate on outbound retention calls is 22 percent.',
    'A propensity-to-churn model scoring customers 90 days before renewal will enable the retention team to prioritize the top 20 percent of at-risk customers, increasing retention call conversion to above 45 percent and recovering an estimated $2.1M in annual recurring revenue.',
    2100000.00, 4, 4, 'High',
    'Gradient boosting classifier with feature importance explainability', TRUE,
    'Live', 'Churn rate reduction >= 2 percentage points; retention call conversion >= 45%', 'Q1-2024', '2023-07-22'
),
(
    'Marketing & Growth', 'Commercial',
    'Data & AI Business Partner, Commercial',
    'Subscription pricing is set annually through a manual competitive review. The team lacks the capability to test dynamic pricing at the segment level, resulting in estimated revenue leakage of $800K annually from customers who would accept a higher price point.',
    'A dynamic pricing optimization model using price elasticity estimates, customer lifetime value segmentation, and competitive signal feeds will recommend segment-level price adjustments that capture above $600K in additional annual revenue without increasing churn.',
    600000.00, 2, 2, 'High',
    'Price elasticity modeling with multi-arm bandit optimization', FALSE,
    'Not Ready', 'Incremental revenue >= $600K annually; churn delta <= 0.5 percentage points', 'Q1-2025', '2024-06-03'
),

-- HR (2)
(
    'Human Resources', 'HR',
    'Data & AI Business Partner, HR',
    'Annual voluntary attrition runs at 18.5 percent, with exit interviews indicating that 42 percent of leavers had been considering departure for more than six months before resigning. HR has no early warning signal to enable proactive engagement.',
    'An attrition risk scoring model run quarterly will identify the top quartile of flight-risk employees six months before their likely departure, enabling targeted retention conversations and reducing voluntary attrition by 4 percentage points, saving an estimated $1.4M in replacement costs.',
    1400000.00, 3, 3, 'Medium',
    'Logistic regression with fairness audit (Disparate Impact analysis)', TRUE,
    'Live', 'Voluntary attrition reduction >= 3 percentage points over 12 months', 'Q1-2024', '2023-10-11'
),
(
    'Human Resources', 'HR',
    'Data & AI Business Partner, HR',
    'Talent acquisition team spends an average of 4.2 hours per open role screening resumes before shortlisting. Time-to-fill averages 47 days against a benchmark of 32 days, and hiring managers report low satisfaction with shortlist quality.',
    'An LLM-powered resume screening assistant that ranks candidates against structured job description vectors will reduce recruiter screening time by 60 percent, lower time-to-fill to below 35 days, and improve hiring manager shortlist satisfaction score from 3.1 to above 4.0 out of 5.',
    380000.00, 3, 2, 'Medium',
    'LLM embedding similarity with structured scoring overlay', FALSE,
    'Not Ready', 'Screening time reduction >= 50%; time-to-fill <= 35 days; hiring manager score >= 4.0', 'Q3-2024', '2024-04-01'
),

-- Supply Chain (3)
(
    'Operations & Supply Chain', 'Supply Chain',
    'Data & AI Business Partner, Supply Chain',
    'SKU-level demand forecasting is performed monthly using a legacy ERP-embedded statistical model. Forecast accuracy at the SKU-week level is 71 percent, contributing to $3.2M in excess inventory carrying cost and a 4.2 percent stockout rate.',
    'A modern demand forecasting stack using hierarchical time-series models with promotional lift and external demand signals will improve SKU-week forecast accuracy to above 88 percent, reducing inventory carrying cost by $1.1M and cutting stockout rate below 2 percent.',
    1100000.00, 4, 4, 'Medium',
    'Hierarchical time-series forecasting (Prophet with regressors)', TRUE,
    'Live', 'Forecast accuracy >= 88% at SKU-week; stockout rate <= 2%; carrying cost reduction >= $900K', 'Q4-2023', '2023-05-18'
),
(
    'Operations & Supply Chain', 'Supply Chain',
    'Data & AI Business Partner, Supply Chain',
    'Supplier risk is assessed annually using a manual scorecard that relies on publicly available data. The process does not capture real-time signals such as financial distress indicators, geopolitical events, or quality performance trends.',
    'An automated supplier risk monitoring platform that aggregates financial, operational, and external risk signals will provide real-time alerts for at-risk suppliers, enabling procurement to diversify supply before disruption, with an estimated $900K in avoided emergency procurement premium.',
    900000.00, 3, 3, 'High',
    'Multi-signal risk scoring with NLP news monitoring', FALSE,
    'Ready', 'Alert lead time >= 30 days before disruption; emergency procurement premium reduction >= 40%', 'Q3-2024', '2024-01-25'
),
(
    'Operations & Supply Chain', 'Supply Chain',
    'Data & AI Business Partner, Supply Chain',
    'Warehouse labor scheduling is managed weekly by shift supervisors using spreadsheets. Overstaffing and understaffing events cost an estimated $480K annually in overtime premium and productivity loss.',
    'A workforce demand forecasting model combining order volume forecasts, historical labor throughput, and seasonal patterns will generate optimized shift schedules that reduce labor cost variance by 35 percent and eliminate the majority of emergency overtime callouts.',
    480000.00, 4, 3, 'Low',
    'Regression-based demand forecasting with schedule optimization', TRUE,
    'Ready', 'Labor cost variance reduction >= 30%; overtime callout reduction >= 50%', 'Q2-2024', '2024-02-08'
),

-- Customer Service (2)
(
    'Customer Experience', 'Customer Service',
    'Data & AI Business Partner, Customer Experience',
    'Customer support agents handle 22,000 contacts per month without real-time guidance on next best action. First-contact resolution rate is 64 percent, and average handle time is 8.5 minutes, both below industry benchmarks.',
    'A next best action recommendation engine that surfaces relevant knowledge base articles, escalation triggers, and resolution pathways in real time will increase first-contact resolution to above 78 percent and reduce average handle time to below 6.5 minutes, saving $1.2M annually in contact center cost.',
    1200000.00, 3, 3, 'Medium',
    'Hybrid recommender (collaborative filtering + knowledge graph)', TRUE,
    'In Delivery', 'First-contact resolution >= 78%; average handle time <= 6.5 min', 'Q3-2024', '2024-01-15'
),
(
    'Customer Experience', 'Customer Service',
    'Data & AI Business Partner, Customer Experience',
    'Customer satisfaction scores are collected via post-contact survey with an 11 percent response rate, providing lagging and unrepresentative signal. The support organization cannot detect emerging satisfaction issues until they appear in quarterly NPS reporting.',
    'A real-time sentiment analysis pipeline applied to 100 percent of support transcripts will provide daily satisfaction signal at the agent, team, and issue-type level, enabling the operations team to intervene on emerging trends 6 to 8 weeks earlier than the current survey cycle.',
    340000.00, 4, 4, 'Low',
    'NLP sentiment classification (RoBERTa fine-tuned on support corpus)', TRUE,
    'Live', 'Sentiment signal coverage >= 95% of contacts; trend detection lead time improvement >= 6 weeks', 'Q3-2023', '2023-04-10'
);

-- ── Silver view ───────────────────────────────────────────────────────────────
-- Reads directly from raw.dim_bp_portfolio (no staging layer needed:
-- the table is clean at insert time and has no dirty-data conformance issues).

DROP VIEW IF EXISTS silver.v_bp_portfolio CASCADE;

CREATE VIEW silver.v_bp_portfolio AS
SELECT
    bp_id,
    business_unit,
    business_function,
    business_partner_role,
    business_problem,
    value_hypothesis,
    estimated_value_usd,
    feasibility_score,
    organizational_readiness_score,
    risk_tier,
    recommended_solution_pattern,
    reuse_candidate_flag,
    delivery_handoff_status,
    success_metric,
    roadmap_quarter,
    intake_date,
    ROUND((feasibility_score + organizational_readiness_score) / 2.0, 1)
        AS composite_readiness_score,
    CASE
        WHEN delivery_handoff_status IN ('Ready', 'In Delivery', 'Live') THEN TRUE
        ELSE FALSE
    END AS handoff_ready_flag,
    CASE
        WHEN risk_tier IN ('High', 'Critical') AND feasibility_score <= 2 THEN TRUE
        ELSE FALSE
    END AS strategic_risk_flag
FROM raw.dim_bp_portfolio
ORDER BY business_function, risk_tier, feasibility_score DESC;
