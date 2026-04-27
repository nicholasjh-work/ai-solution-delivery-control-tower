-- AI Solution Delivery Control Tower
-- Synthetic seed data — portfolio / demo purposes only
-- Nicholas Hidalgo | Portfolio Project | Synthetic Data

SET search_path TO raw;

-- ── dim_business_unit (8 units) ───────────────────────────────────────────────
INSERT INTO raw.dim_business_unit (unit_code, unit_name, division, region) VALUES
('FIN',  'Finance & Accounting',        'Corporate Functions',   'North America'),
('MKTG', 'Marketing & Growth',          'Commercial',            'North America'),
('OPS',  'Operations & Supply Chain',   'Enterprise Operations', 'Global'),
('HR',   'Human Resources',             'Corporate Functions',   'North America'),
('RISK', 'Enterprise Risk Management',  'Corporate Functions',   'Global'),
('PROD', 'Product Development',         'Technology',            'North America'),
('CUST', 'Customer Experience',         'Commercial',            'APAC'),
('TECH', 'Technology & Infrastructure', 'Technology',            'Europe');

-- ── dim_risk_tier (4 tiers) ───────────────────────────────────────────────────
INSERT INTO raw.dim_risk_tier (tier_code, tier_name, description, approval_level, review_frequency) VALUES
('T1', 'Critical',  'High-impact models with regulatory or financial exposure; requires board-level sign-off',  'Executive Sponsor + CAIO', 'Quarterly'),
('T2', 'High',      'Significant business impact; requires VP-level governance review',                        'VP Delivery + Risk Committee', 'Semi-Annual'),
('T3', 'Medium',    'Moderate risk; internal use cases with limited downstream impact',                        'Delivery Lead',               'Annual'),
('T4', 'Low',       'Experimental or sandbox models with no production exposure',                              'Team Lead',                   'Annual');

-- ── dim_ai_use_case (20 use cases) ───────────────────────────────────────────
INSERT INTO raw.dim_ai_use_case (use_case_code, use_case_name, business_unit_id, use_case_type, description, priority, current_stage) VALUES
('UC-FIN-001', 'Invoice Anomaly Detection',           1, 'Predictive',    'Detect fraudulent or erroneous invoices before payment processing', 'High',   'Production'),
('UC-FIN-002', 'Cash Flow Forecasting',               1, 'Forecasting',   'ML-driven 13-week rolling cash flow prediction',                    'High',   'Validation'),
('UC-MKTG-001','Churn Propensity Model',              2, 'Predictive',    'Predict customer churn 90 days in advance to enable retention',     'High',   'Production'),
('UC-MKTG-002','Campaign ROI Attribution',            2, 'Analytics',     'Multi-touch attribution model for digital marketing spend',         'Medium', 'Staging'),
('UC-OPS-001', 'Demand Forecasting',                  3, 'Forecasting',   'SKU-level demand forecasting for inventory optimization',           'High',   'Production'),
('UC-OPS-002', 'Predictive Maintenance',              3, 'Predictive',    'Equipment failure prediction to reduce unplanned downtime',        'High',   'Validation'),
('UC-OPS-003', 'Route Optimization',                  3, 'Optimization',  'Last-mile delivery routing using reinforcement learning',          'Medium', 'Development'),
('UC-HR-001',  'Attrition Risk Scoring',              4, 'Predictive',    'Identify high-flight-risk employees for proactive engagement',     'Medium', 'Production'),
('UC-HR-002',  'Resume Screening Assistant',          4, 'NLP',           'LLM-powered resume ranking aligned to job description vectors',    'Low',    'Intake'),
('UC-RISK-001','Credit Risk Re-scoring',              5, 'Predictive',    'Real-time credit risk re-scoring using alternative data signals',  'High',   'Validation'),
('UC-RISK-002','Regulatory Breach Classifier',        5, 'Classification','NLP classifier to flag potential regulatory breach events',        'High',   'Staging'),
('UC-RISK-003','Fraud Network Detection',             5, 'Graph ML',      'Graph neural network to detect coordinated fraud rings',           'High',   'Production'),
('UC-PROD-001','Feature Recommendation Engine',       6, 'Recommender',   'Personalized feature suggestion within product UI',               'Medium', 'Production'),
('UC-PROD-002','Code Quality Analyzer',               6, 'NLP',           'Static analysis augmented by LLM to surface code smell patterns', 'Low',    'Development'),
('UC-CUST-001','Sentiment Analysis Pipeline',         7, 'NLP',           'Real-time NLP scoring of customer support transcripts',           'Medium', 'Production'),
('UC-CUST-002','Next Best Action Engine',             7, 'Recommender',   'Contextual recommendation engine for service agents',             'High',   'Staging'),
('UC-TECH-001','Infrastructure Anomaly Detection',    8, 'Predictive',    'Time-series anomaly detection on cloud infrastructure metrics',   'High',   'Production'),
('UC-TECH-002','Capacity Planning Model',             8, 'Forecasting',   'Predict compute capacity needs 6 months forward',                 'Medium', 'Validation'),
('UC-FIN-003', 'GL Account Classifier',               1, 'Classification','Auto-classify journal entries into GL accounts using NLP',        'Medium', 'Staging'),
('UC-MKTG-003','Pricing Optimization Model',         2, 'Optimization',  'Dynamic pricing recommendation engine for subscription tiers',    'High',   'Development');

-- ── dim_model (20 models, one per use case) ───────────────────────────────────
INSERT INTO raw.dim_model (model_code, model_name, use_case_id, model_type, framework, version, risk_tier_id, deployment_env, performance_score, bias_assessment, drift_status, is_active) VALUES
('MDL-FIN-001', 'InvoiceAD-XGB-v3',         1,  'XGBoost',          'scikit-learn',   '3.0', 2, 'Production',   0.9412, 'Low',          'None',     TRUE),
('MDL-FIN-002', 'CashFlowFCT-LSTM-v1',      2,  'LSTM',             'TensorFlow',     '1.0', 2, 'Staging',      0.8765, 'Not Assessed', 'None',     TRUE),
('MDL-MKTG-001','ChurnProp-RF-v4',          3,  'Random Forest',    'scikit-learn',   '4.0', 2, 'Production',   0.8931, 'Medium',       'Low',      TRUE),
('MDL-MKTG-002','CampaignAttr-Shapley-v1',  4,  'Shapley Value',    'Custom Python',  '1.0', 3, 'Staging',      0.8204, 'Not Assessed', 'None',     TRUE),
('MDL-OPS-001', 'DemandFCT-Prophet-v2',     5,  'Prophet',          'Facebook Prophet','2.0',2, 'Production',   0.9023, 'Low',          'Low',      TRUE),
('MDL-OPS-002', 'PredMaint-LSTM-v1',        6,  'LSTM',             'PyTorch',        '1.0', 2, 'Staging',      0.8654, 'Not Assessed', 'None',     TRUE),
('MDL-OPS-003', 'RouteOpt-RL-v1',           7,  'Reinforcement',    'RLlib',          '1.0', 3, 'Development',  0.7890, 'Not Assessed', 'None',     TRUE),
('MDL-HR-001',  'AttritionRS-LR-v2',        8,  'Logistic Regression','scikit-learn', '2.0', 3, 'Production',   0.8102, 'High',         'Low',      TRUE),
('MDL-HR-002',  'ResumeScreen-LLM-v1',      9,  'LLM',              'OpenAI API',     '1.0', 3, 'Development',  0.7450, 'Not Assessed', 'None',     FALSE),
('MDL-RISK-001','CreditRS-GBM-v3',          10, 'Gradient Boosting','LightGBM',       '3.0', 1, 'Staging',      0.9187, 'Low',          'Medium',   TRUE),
('MDL-RISK-002','RegBreachCLS-BERT-v1',     11, 'BERT',             'HuggingFace',    '1.0', 1, 'Staging',      0.8763, 'Not Assessed', 'None',     TRUE),
('MDL-RISK-003','FraudNet-GNN-v2',          12, 'GNN',              'PyTorch Geometric','2.0',1,'Production',   0.9501, 'Low',          'None',     TRUE),
('MDL-PROD-001','FeatRec-CF-v3',            13, 'Collaborative Filter','Surprise',    '3.0', 3, 'Production',   0.8456, 'Medium',       'Low',      TRUE),
('MDL-PROD-002','CodeQA-GPT-v1',            14, 'LLM',              'Azure OpenAI',   '1.0', 4, 'Development',  0.7210, 'Not Assessed', 'None',     TRUE),
('MDL-CUST-001','SentAna-RoBERTa-v2',       15, 'RoBERTa',          'HuggingFace',    '2.0', 3, 'Production',   0.9034, 'Low',          'None',     TRUE),
('MDL-CUST-002','NBA-Engine-v1',            16, 'Hybrid Recommender','Custom Python', '1.0', 2, 'Staging',      0.8321, 'Not Assessed', 'None',     TRUE),
('MDL-TECH-001','InfraAD-IF-v2',            17, 'Isolation Forest', 'scikit-learn',   '2.0', 2, 'Production',   0.9210, 'Low',          'None',     TRUE),
('MDL-TECH-002','CapPlan-SARIMAX-v1',       18, 'SARIMAX',          'statsmodels',    '1.0', 3, 'Staging',      0.8532, 'Not Assessed', 'None',     TRUE),
('MDL-FIN-003', 'GLClassify-DistilBERT-v1', 19, 'DistilBERT',       'HuggingFace',   '1.0', 3, 'Staging',      0.8840, 'Not Assessed', 'None',     TRUE),
('MDL-MKTG-003','PricingOpt-XGB-v1',        20, 'XGBoost',          'scikit-learn',   '1.0', 2, 'Development',  0.8112, 'Not Assessed', 'None',     TRUE);

-- ── dim_owner (16 owners) ─────────────────────────────────────────────────────
INSERT INTO raw.dim_owner (owner_name, owner_role, business_unit_id, email, is_active) VALUES
('Alexandra Chen',    'AI Delivery Lead',          1, 'a.chen@company.com',       TRUE),
('Marcus Williams',   'Data Science Manager',      2, 'm.williams@company.com',   TRUE),
('Priya Sharma',      'ML Engineer',               3, 'p.sharma@company.com',     TRUE),
('James O''Brien',    'AI Product Owner',          4, 'j.obrien@company.com',     TRUE),
('Sofia Rodriguez',   'Risk & Compliance Lead',    5, 's.rodriguez@company.com',  TRUE),
('David Kim',         'Senior Data Scientist',     6, 'd.kim@company.com',        TRUE),
('Aisha Patel',       'AI Delivery Manager',       7, 'a.patel@company.com',      TRUE),
('Thomas Mueller',    'ML Operations Engineer',    8, 't.mueller@company.com',    TRUE),
('Rachel Thompson',   'Governance & Ethics Lead',  5, 'r.thompson@company.com',   TRUE),
('Carlos Mendes',     'Data Engineering Lead',     3, 'c.mendes@company.com',     TRUE),
('Linda Park',        'AI Strategy Director',      1, 'l.park@company.com',       TRUE),
('Kevin Johnson',     'Model Risk Analyst',        5, 'k.johnson@company.com',    TRUE),
('Nina Volkov',       'AI Delivery Lead',          2, 'n.volkov@company.com',     TRUE),
('Omar Hassan',       'Data Scientist',            7, 'o.hassan@company.com',     TRUE),
('Yuki Tanaka',       'MLOps Engineer',            8, 'y.tanaka@company.com',     TRUE),
('Grace Osei',        'AI Product Manager',        6, 'g.osei@company.com',       TRUE);

-- ── fact_ai_delivery_stage (pipeline stages for 20 use cases) ────────────────
-- Stages: Intake(1) → Scoping(2) → Development(3) → Validation(4) → Staging(5) → Production(6)
INSERT INTO raw.fact_ai_delivery_stage (use_case_id, owner_id, stage_name, stage_sequence, entry_date, exit_date, actual_days, sla_target_days, stage_status, exit_reason, is_sla_breached) VALUES
-- UC-FIN-001: fully in Production
(1,  1, 'Intake',      1, '2024-01-08', '2024-01-19', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(1,  1, 'Scoping',     2, '2024-01-19', '2024-02-09', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(1,  1, 'Development', 3, '2024-02-09', '2024-04-12', 63,  60, 'Completed', 'Model validated',        TRUE),
(1,  1, 'Validation',  4, '2024-04-12', '2024-05-10', 28,  30, 'Completed', 'UAT passed',             FALSE),
(1,  1, 'Staging',     5, '2024-05-10', '2024-05-24', 14,  21, 'Completed', 'Deployed to prod',       FALSE),
(1,  1, 'Production',  6, '2024-05-24', NULL,          NULL,365,'In Progress','',                      FALSE),
-- UC-FIN-002: in Validation
(2,  1, 'Intake',      1, '2024-06-03', '2024-06-14', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(2,  1, 'Scoping',     2, '2024-06-14', '2024-07-05', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(2,  1, 'Development', 3, '2024-07-05', '2024-10-11', 98,  60, 'Completed', 'Model validated',        TRUE),
(2,  1, 'Validation',  4, '2024-10-11', NULL,          NULL, 30, 'In Progress','',                    FALSE),
-- UC-MKTG-001: fully in Production
(3,  13,'Intake',      1, '2023-09-04', '2023-09-15', 11,  14, 'Completed', 'Approved for scoping',   FALSE),
(3,  13,'Scoping',     2, '2023-09-15', '2023-10-06', 21,  21, 'Completed', 'Requirements finalized', FALSE),
(3,  13,'Development', 3, '2023-10-06', '2023-12-15', 70,  60, 'Completed', 'Model built',            TRUE),
(3,  13,'Validation',  4, '2023-12-15', '2024-01-12', 28,  30, 'Completed', 'UAT passed',             FALSE),
(3,  13,'Staging',     5, '2024-01-12', '2024-01-26', 14,  21, 'Completed', 'Approved for prod',      FALSE),
(3,  13,'Production',  6, '2024-01-26', NULL,          NULL,365,'In Progress','',                      FALSE),
-- UC-MKTG-002: in Staging
(4,  13,'Intake',      1, '2024-08-05', '2024-08-16', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(4,  13,'Scoping',     2, '2024-08-16', '2024-09-06', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(4,  13,'Development', 3, '2024-09-06', '2024-11-15', 70,  60, 'Completed', 'Model validated',        TRUE),
(4,  13,'Validation',  4, '2024-11-15', '2024-12-13', 28,  30, 'Completed', 'UAT passed',             FALSE),
(4,  13,'Staging',     5, '2024-12-13', NULL,          NULL, 21, 'In Progress','',                    FALSE),
-- UC-OPS-001: fully in Production
(5,  10,'Intake',      1, '2023-06-05', '2023-06-16', 11,  14, 'Completed', 'Approved',               FALSE),
(5,  10,'Scoping',     2, '2023-06-16', '2023-07-07', 21,  21, 'Completed', 'Requirements finalized', FALSE),
(5,  10,'Development', 3, '2023-07-07', '2023-09-01', 56,  60, 'Completed', 'Model built',            FALSE),
(5,  10,'Validation',  4, '2023-09-01', '2023-09-29', 28,  30, 'Completed', 'UAT passed',             FALSE),
(5,  10,'Staging',     5, '2023-09-29', '2023-10-13', 14,  21, 'Completed', 'Approved for prod',      FALSE),
(5,  10,'Production',  6, '2023-10-13', NULL,          NULL,365,'In Progress','',                      FALSE),
-- UC-OPS-002: in Validation
(6,  10,'Intake',      1, '2024-07-01', '2024-07-12', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(6,  10,'Scoping',     2, '2024-07-12', '2024-08-02', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(6,  10,'Development', 3, '2024-08-02', '2024-10-25', 84,  60, 'Completed', 'Model validated',        TRUE),
(6,  10,'Validation',  4, '2024-10-25', NULL,          NULL, 30, 'In Progress','',                    FALSE),
-- UC-OPS-003: in Development (blocked)
(7,  3, 'Intake',      1, '2024-10-07', '2024-10-18', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(7,  3, 'Scoping',     2, '2024-10-18', '2024-11-08', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(7,  3, 'Development', 3, '2024-11-08', NULL,          NULL, 60, 'Blocked',  'Data access blocked',    FALSE),
-- UC-HR-001: fully in Production
(8,  4, 'Intake',      1, '2023-11-06', '2023-11-17', 11,  14, 'Completed', 'Approved',               FALSE),
(8,  4, 'Scoping',     2, '2023-11-17', '2023-12-08', 21,  21, 'Completed', 'Requirements finalized', FALSE),
(8,  4, 'Development', 3, '2023-12-08', '2024-02-02', 56,  60, 'Completed', 'Model built',            FALSE),
(8,  4, 'Validation',  4, '2024-02-02', '2024-03-01', 28,  30, 'Completed', 'UAT passed',             FALSE),
(8,  4, 'Staging',     5, '2024-03-01', '2024-03-15', 14,  21, 'Completed', 'Approved for prod',      FALSE),
(8,  4, 'Production',  6, '2024-03-15', NULL,          NULL,365,'In Progress','',                      FALSE),
-- UC-HR-002: Intake only
(9,  4, 'Intake',      1, '2025-01-06', NULL,          NULL, 14, 'In Progress','',                    FALSE),
-- UC-RISK-001: in Validation
(10, 9, 'Intake',      1, '2024-04-01', '2024-04-12', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(10, 9, 'Scoping',     2, '2024-04-12', '2024-05-03', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(10, 9, 'Development', 3, '2024-05-03', '2024-08-16', 105, 60, 'Completed', 'Model validated',        TRUE),
(10, 9, 'Validation',  4, '2024-08-16', NULL,          NULL, 30, 'In Progress','',                    FALSE),
-- UC-RISK-002: in Staging
(11, 9, 'Intake',      1, '2024-05-06', '2024-05-17', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(11, 9, 'Scoping',     2, '2024-05-17', '2024-06-07', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(11, 9, 'Development', 3, '2024-06-07', '2024-08-16', 70,  60, 'Completed', 'Model validated',        TRUE),
(11, 9, 'Validation',  4, '2024-08-16', '2024-09-13', 28,  30, 'Completed', 'UAT passed',             FALSE),
(11, 9, 'Staging',     5, '2024-09-13', NULL,          NULL, 21, 'In Progress','',                    FALSE),
-- UC-RISK-003: fully in Production
(12, 5, 'Intake',      1, '2023-03-06', '2023-03-17', 11,  14, 'Completed', 'Approved',               FALSE),
(12, 5, 'Scoping',     2, '2023-03-17', '2023-04-07', 21,  21, 'Completed', 'Requirements finalized', FALSE),
(12, 5, 'Development', 3, '2023-04-07', '2023-06-02', 56,  60, 'Completed', 'Model built',            FALSE),
(12, 5, 'Validation',  4, '2023-06-02', '2023-06-30', 28,  30, 'Completed', 'UAT passed',             FALSE),
(12, 5, 'Staging',     5, '2023-06-30', '2023-07-14', 14,  21, 'Completed', 'Approved for prod',      FALSE),
(12, 5, 'Production',  6, '2023-07-14', NULL,          NULL,365,'In Progress','',                      FALSE),
-- UC-PROD-001: fully in Production
(13, 16,'Intake',      1, '2023-08-07', '2023-08-18', 11,  14, 'Completed', 'Approved',               FALSE),
(13, 16,'Scoping',     2, '2023-08-18', '2023-09-08', 21,  21, 'Completed', 'Requirements finalized', FALSE),
(13, 16,'Development', 3, '2023-09-08', '2023-11-03', 56,  60, 'Completed', 'Model built',            FALSE),
(13, 16,'Validation',  4, '2023-11-03', '2023-12-01', 28,  30, 'Completed', 'UAT passed',             FALSE),
(13, 16,'Staging',     5, '2023-12-01', '2023-12-15', 14,  21, 'Completed', 'Approved for prod',      FALSE),
(13, 16,'Production',  6, '2023-12-15', NULL,          NULL,365,'In Progress','',                      FALSE),
-- UC-PROD-002: in Development
(14, 6, 'Intake',      1, '2024-11-04', '2024-11-15', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(14, 6, 'Scoping',     2, '2024-11-15', '2024-12-06', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(14, 6, 'Development', 3, '2024-12-06', NULL,          NULL, 60, 'In Progress','',                    FALSE),
-- UC-CUST-001: fully in Production
(15, 14,'Intake',      1, '2023-04-03', '2023-04-14', 11,  14, 'Completed', 'Approved',               FALSE),
(15, 14,'Scoping',     2, '2023-04-14', '2023-05-05', 21,  21, 'Completed', 'Requirements finalized', FALSE),
(15, 14,'Development', 3, '2023-05-05', '2023-06-30', 56,  60, 'Completed', 'Model built',            FALSE),
(15, 14,'Validation',  4, '2023-06-30', '2023-07-28', 28,  30, 'Completed', 'UAT passed',             FALSE),
(15, 14,'Staging',     5, '2023-07-28', '2023-08-11', 14,  21, 'Completed', 'Approved for prod',      FALSE),
(15, 14,'Production',  6, '2023-08-11', NULL,          NULL,365,'In Progress','',                      FALSE),
-- UC-CUST-002: in Staging
(16, 7, 'Intake',      1, '2024-09-02', '2024-09-13', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(16, 7, 'Scoping',     2, '2024-09-13', '2024-10-04', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(16, 7, 'Development', 3, '2024-10-04', '2024-12-06', 63,  60, 'Completed', 'Model validated',        TRUE),
(16, 7, 'Validation',  4, '2024-12-06', '2025-01-03', 28,  30, 'Completed', 'UAT passed',             FALSE),
(16, 7, 'Staging',     5, '2025-01-03', NULL,          NULL, 21, 'In Progress','',                    FALSE),
-- UC-TECH-001: fully in Production
(17, 15,'Intake',      1, '2023-05-01', '2023-05-12', 11,  14, 'Completed', 'Approved',               FALSE),
(17, 15,'Scoping',     2, '2023-05-12', '2023-06-02', 21,  21, 'Completed', 'Requirements finalized', FALSE),
(17, 15,'Development', 3, '2023-06-02', '2023-07-28', 56,  60, 'Completed', 'Model built',            FALSE),
(17, 15,'Validation',  4, '2023-07-28', '2023-08-25', 28,  30, 'Completed', 'UAT passed',             FALSE),
(17, 15,'Staging',     5, '2023-08-25', '2023-09-08', 14,  21, 'Completed', 'Approved for prod',      FALSE),
(17, 15,'Production',  6, '2023-09-08', NULL,          NULL,365,'In Progress','',                      FALSE),
-- UC-TECH-002: in Validation
(18, 8, 'Intake',      1, '2024-09-02', '2024-09-13', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(18, 8, 'Scoping',     2, '2024-09-13', '2024-10-04', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(18, 8, 'Development', 3, '2024-10-04', '2024-12-27', 84,  60, 'Completed', 'Model validated',        TRUE),
(18, 8, 'Validation',  4, '2024-12-27', NULL,          NULL, 30, 'In Progress','',                    FALSE),
-- UC-FIN-003: in Staging
(19, 1, 'Intake',      1, '2024-07-01', '2024-07-12', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(19, 1, 'Scoping',     2, '2024-07-12', '2024-08-02', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(19, 1, 'Development', 3, '2024-08-02', '2024-10-04', 63,  60, 'Completed', 'Model validated',        TRUE),
(19, 1, 'Validation',  4, '2024-10-04', '2024-11-01', 28,  30, 'Completed', 'UAT passed',             FALSE),
(19, 1, 'Staging',     5, '2024-11-01', NULL,          NULL, 21, 'In Progress','',                    FALSE),
-- UC-MKTG-003: in Development
(20, 2, 'Intake',      1, '2024-12-02', '2024-12-13', 11,  14, 'Completed', 'Scoping approved',       FALSE),
(20, 2, 'Scoping',     2, '2024-12-13', '2025-01-03', 21,  21, 'Completed', 'Requirements signed off', FALSE),
(20, 2, 'Development', 3, '2025-01-03', NULL,          NULL, 60, 'In Progress','',                    FALSE);

-- ── fact_model_monitoring (12 months × 10 production models) ─────────────────
-- Production models: 1,3,5,8,12,13,15,17 + Staging models with monitoring: 2,6
INSERT INTO raw.fact_model_monitoring
    (model_id, monitoring_date, accuracy_score, precision_score, recall_score, f1_score, drift_score, data_quality_score, prediction_volume, alert_triggered, alert_type, alert_severity, retrain_required)
SELECT
    m.model_id,
    gs::DATE                                         AS monitoring_date,
    ROUND((0.88 + random()*0.10)::NUMERIC, 4)        AS accuracy_score,
    ROUND((0.86 + random()*0.10)::NUMERIC, 4)        AS precision_score,
    ROUND((0.84 + random()*0.12)::NUMERIC, 4)        AS recall_score,
    ROUND((0.85 + random()*0.10)::NUMERIC, 4)        AS f1_score,
    ROUND((random()*0.15)::NUMERIC, 4)               AS drift_score,
    ROUND((0.92 + random()*0.07)::NUMERIC, 4)        AS data_quality_score,
    (5000 + floor(random()*20000))::INT              AS prediction_volume,
    (random() < 0.12)                                AS alert_triggered,
    CASE WHEN random() < 0.12
         THEN (ARRAY['Data Drift','Performance Degradation','Data Quality','Volume Spike'])[floor(random()*4+1)::INT]
         ELSE 'None' END                             AS alert_type,
    CASE WHEN random() < 0.12
         THEN (ARRAY['Low','Medium','High'])[floor(random()*3+1)::INT]
         ELSE 'None' END                             AS alert_severity,
    (random() < 0.07)                                AS retrain_required
FROM
    (VALUES (1),(3),(5),(8),(12),(13),(15),(17)) AS m(model_id),
    generate_series('2024-03-01'::DATE, '2025-01-01'::DATE, '1 month'::INTERVAL) gs;

-- Staging model monitoring (fewer months)
INSERT INTO raw.fact_model_monitoring
    (model_id, monitoring_date, accuracy_score, precision_score, recall_score, f1_score, drift_score, data_quality_score, prediction_volume, alert_triggered, alert_type, alert_severity, retrain_required)
SELECT
    m.model_id,
    gs::DATE,
    ROUND((0.85 + random()*0.10)::NUMERIC, 4),
    ROUND((0.83 + random()*0.10)::NUMERIC, 4),
    ROUND((0.81 + random()*0.12)::NUMERIC, 4),
    ROUND((0.82 + random()*0.10)::NUMERIC, 4),
    ROUND((random()*0.10)::NUMERIC, 4),
    ROUND((0.90 + random()*0.09)::NUMERIC, 4),
    (1000 + floor(random()*5000))::INT,
    (random() < 0.08),
    CASE WHEN random() < 0.08 THEN (ARRAY['Data Drift','Performance Degradation'])[floor(random()*2+1)::INT] ELSE 'None' END,
    CASE WHEN random() < 0.08 THEN (ARRAY['Low','Medium'])[floor(random()*2+1)::INT] ELSE 'None' END,
    (random() < 0.05)
FROM
    (VALUES (2),(6),(10),(11)) AS m(model_id),
    generate_series('2024-10-01'::DATE, '2025-01-01'::DATE, '1 month'::INTERVAL) gs;

-- ── fact_value_realization (quarterly metrics for 8 production use cases) ─────
INSERT INTO raw.fact_value_realization
    (use_case_id, measurement_date, measurement_period, metric_name, metric_category, baseline_value, realized_value, target_value, unit_of_measure, confidence_level, is_validated, validated_by)
VALUES
-- UC-FIN-001 Invoice Anomaly Detection
(1, '2024-07-01', 'Q2-2024', 'Fraud Prevented',        'Financial',      180000,  425000,  400000,  'USD',       'High',   TRUE,  'Internal Audit'),
(1, '2024-10-01', 'Q3-2024', 'Fraud Prevented',        'Financial',      180000,  510000,  450000,  'USD',       'High',   TRUE,  'Internal Audit'),
(1, '2025-01-01', 'Q4-2024', 'Fraud Prevented',        'Financial',      180000,  490000,  450000,  'USD',       'High',   FALSE, ''),
(1, '2024-07-01', 'Q2-2024', 'Processing Time Saved',  'Operational',    120,     45,      50,      'Hours/mo',  'Medium', TRUE,  'Finance Controller'),
-- UC-MKTG-001 Churn Propensity
(3, '2024-04-01', 'Q1-2024', 'Churn Rate Reduction',   'Financial',      8.4,     6.1,     6.5,     '% Churn',   'High',   TRUE,  'CFO Office'),
(3, '2024-07-01', 'Q2-2024', 'Churn Rate Reduction',   'Financial',      8.4,     5.8,     6.0,     '% Churn',   'High',   TRUE,  'CFO Office'),
(3, '2024-10-01', 'Q3-2024', 'Revenue Retained',       'Financial',      0,       1850000, 2000000, 'USD',       'Medium', TRUE,  'Revenue Ops'),
(3, '2025-01-01', 'Q4-2024', 'Revenue Retained',       'Financial',      0,       2100000, 2000000, 'USD',       'Medium', FALSE, ''),
-- UC-OPS-001 Demand Forecasting
(5, '2024-01-01', 'Q4-2023', 'Inventory Cost Savings', 'Financial',      2400000, 2950000, 2800000, 'USD',       'High',   TRUE,  'Supply Chain VP'),
(5, '2024-04-01', 'Q1-2024', 'Inventory Cost Savings', 'Financial',      2400000, 3100000, 2900000, 'USD',       'High',   TRUE,  'Supply Chain VP'),
(5, '2024-07-01', 'Q2-2024', 'Stockout Rate',          'Operational',    4.2,     2.1,     2.5,     '% Stockout','High',   TRUE,  'Supply Chain VP'),
(5, '2024-10-01', 'Q3-2024', 'Stockout Rate',          'Operational',    4.2,     1.9,     2.0,     '% Stockout','High',   FALSE, ''),
-- UC-HR-001 Attrition
(8, '2024-04-01', 'Q1-2024', 'Attrition Rate',         'Operational',    18.5,    14.2,    15.0,    '% Annual',  'Medium', TRUE,  'CHRO'),
(8, '2024-07-01', 'Q2-2024', 'Attrition Rate',         'Operational',    18.5,    13.8,    14.5,    '% Annual',  'Medium', TRUE,  'CHRO'),
(8, '2024-10-01', 'Q3-2024', 'Cost Avoidance',         'Financial',      0,       620000,  700000,  'USD',       'Low',    FALSE, ''),
-- UC-RISK-003 Fraud Network Detection
(12,'2023-10-01', 'Q3-2023', 'Fraud Losses Prevented', 'Financial',      890000,  2100000, 2000000, 'USD',       'High',   TRUE,  'Chief Risk Officer'),
(12,'2024-01-01', 'Q4-2023', 'Fraud Losses Prevented', 'Financial',      890000,  2350000, 2200000, 'USD',       'High',   TRUE,  'Chief Risk Officer'),
(12,'2024-04-01', 'Q1-2024', 'Fraud Losses Prevented', 'Financial',      890000,  2400000, 2300000, 'USD',       'High',   TRUE,  'Chief Risk Officer'),
(12,'2024-07-01', 'Q2-2024', 'False Positive Rate',    'Operational',    12.0,    4.2,     5.0,     '% FP Rate', 'High',   TRUE,  'Risk Analytics'),
-- UC-PROD-001 Feature Recommendation
(13,'2024-04-01', 'Q1-2024', 'Feature Adoption Rate',  'Operational',    22.0,    34.5,    35.0,    '% Adoption','Medium', TRUE,  'Product Analytics'),
(13,'2024-07-01', 'Q2-2024', 'Feature Adoption Rate',  'Operational',    22.0,    38.2,    38.0,    '% Adoption','Medium', TRUE,  'Product Analytics'),
(13,'2024-10-01', 'Q3-2024', 'Revenue Impact',         'Financial',      0,       480000,  500000,  'USD',       'Low',    FALSE, ''),
-- UC-CUST-001 Sentiment Analysis
(15,'2023-11-01', 'Q3-2023', 'CSAT Score Improvement', 'Operational',    72.0,    78.5,    80.0,    'NPS Score', 'Medium', TRUE,  'CX Director'),
(15,'2024-02-01', 'Q4-2023', 'CSAT Score Improvement', 'Operational',    72.0,    81.2,    80.0,    'NPS Score', 'Medium', TRUE,  'CX Director'),
(15,'2024-05-01', 'Q1-2024', 'Handle Time Reduction',  'Operational',    8.5,     6.2,     6.5,     'Minutes',   'High',   TRUE,  'Ops Analytics'),
-- UC-TECH-001 Infrastructure AD
(17,'2023-12-01', 'Q3-2023', 'Incident MTTR',          'Operational',    145,     62,      75,      'Minutes',   'High',   TRUE,  'Infra Lead'),
(17,'2024-03-01', 'Q4-2023', 'Incident MTTR',          'Operational',    145,     55,      70,      'Minutes',   'High',   TRUE,  'Infra Lead'),
(17,'2024-06-01', 'Q1-2024', 'Downtime Avoidance',     'Financial',      0,       310000,  350000,  'USD',       'Medium', TRUE,  'CTO Office');

-- ── fact_sla_breach (SLA breaches for stages where is_sla_breached = TRUE) ────
INSERT INTO raw.fact_sla_breach
    (stage_id, use_case_id, breach_date, sla_target_days, actual_days, days_over_sla, breach_reason, escalated, escalated_to, resolved_date)
SELECT
    s.stage_id,
    s.use_case_id,
    COALESCE(s.exit_date, s.entry_date + s.sla_target_days) AS breach_date,
    s.sla_target_days,
    COALESCE(s.actual_days, s.sla_target_days + 10)         AS actual_days,
    COALESCE(s.actual_days, s.sla_target_days + 10) - s.sla_target_days AS days_over_sla,
    r.breach_reason,
    r.escalated,
    r.escalated_to,
    r.resolved_date
FROM raw.fact_ai_delivery_stage s
JOIN (VALUES
    (3,  'Complex feature engineering required additional sprints; stakeholder re-prioritisation mid-development', TRUE,  'AI Delivery Director', '2024-05-01'::DATE),
    (9,  'LSTM training time exceeded estimates; GPU resource contention on shared compute cluster',               FALSE, '',                     '2024-10-30'::DATE),
    (13, 'Scope creep: business added two new segment requirements after sprint 3',                               TRUE,  'VP Commercial',        '2024-01-15'::DATE),
    (19, 'Attribution model required additional validation dataset sourcing; legal review extended',              FALSE, '',                     '2024-12-05'::DATE),
    (30, 'Third-party sensor data API changed schema; required full data pipeline rebuild',                       TRUE,  'AI Delivery Director', '2024-10-20'::DATE),
    (44, 'GBM hyperparameter tuning required additional compute; model council requested explainability layer',   TRUE,  'Chief Risk Officer',   NULL::DATE),
    (48, 'BERT fine-tuning required annotated legal corpus; procurement of labelling service delayed 3 weeks',    FALSE, '',                     NULL::DATE),
    (74, 'Next Best Action model required extended A/B test period; business requested hold for Q4 freeze',       TRUE,  'Head of Engineering',  NULL::DATE),
    (85, 'SARIMAX model required additional historical data sourcing; data warehouse migration delayed pipeline', FALSE, '',                     NULL::DATE),
    (89, 'GL classifier required additional annotated training samples; finance team annotation delayed 4 weeks', TRUE,  'CTO Office',           '2025-01-10'::DATE)
) AS r(stage_id, breach_reason, escalated, escalated_to, resolved_date)
ON s.stage_id = r.stage_id;

-- ── fact_governance_review ────────────────────────────────────────────────────
INSERT INTO raw.fact_governance_review
    (use_case_id, risk_tier_id, review_type, review_date, reviewer_id, review_outcome, risk_score, findings_count, critical_findings, conditions, next_review_date)
VALUES
-- T1 Critical: UC-RISK-001, UC-RISK-002, UC-RISK-003
(10, 1, 'Initial Risk Assessment',  '2024-04-01', 9,  'Approved with Conditions', 72, 4, 1, 'Must pass independent model validation. Explainability layer required before staging.', '2024-10-01'),
(10, 1, 'Interim Review',           '2024-08-15', 9,  'Approved with Conditions', 65, 2, 0, 'GBM model drift monitoring to be implemented within 30 days of production.',             '2025-02-15'),
(11, 1, 'Initial Risk Assessment',  '2024-05-06', 9,  'Approved with Conditions', 78, 5, 2, 'Adversarial testing required. Bias audit on training corpus mandatory.',                  '2024-11-06'),
(12, 1, 'Annual Review',            '2024-07-14', 12, 'Approved',                 48, 1, 0, '',                                                                                        '2025-07-14'),
(12, 1, 'Interim Review',           '2023-10-14', 12, 'Approved',                 52, 2, 0, 'Minor: update model card with latest confusion matrix.',                                  '2024-04-14'),
-- T2 High: UC-FIN-001, UC-FIN-002, UC-MKTG-001, UC-OPS-001, UC-OPS-002, UC-RISK-003 (already done)
(1,  2, 'Initial Risk Assessment',  '2024-01-08', 11, 'Approved',                 38, 2, 0, '',                                                                                        '2025-01-08'),
(1,  2, 'Annual Review',            '2025-01-08', 11, 'Approved',                 35, 1, 0, '',                                                                                        '2026-01-08'),
(2,  2, 'Initial Risk Assessment',  '2024-06-03', 11, 'Approved with Conditions', 55, 3, 1, 'LSTM model must include confidence intervals in outputs. Data governance sign-off req.',  '2024-12-03'),
(3,  2, 'Initial Risk Assessment',  '2023-09-04', 13, 'Approved',                 42, 2, 0, '',                                                                                        '2024-09-04'),
(3,  2, 'Annual Review',            '2024-09-04', 13, 'Approved',                 39, 1, 0, '',                                                                                        '2025-09-04'),
(5,  2, 'Initial Risk Assessment',  '2023-06-05', 10, 'Approved',                 36, 1, 0, '',                                                                                        '2024-06-05'),
(5,  2, 'Annual Review',            '2024-06-05', 10, 'Approved',                 33, 0, 0, '',                                                                                        '2025-06-05'),
(6,  2, 'Initial Risk Assessment',  '2024-07-01', 10, 'Approved with Conditions', 58, 3, 0, 'Sensor data provenance documentation required. Validation on held-out plant data.',      '2025-01-01'),
(17, 2, 'Initial Risk Assessment',  '2023-05-01', 15, 'Approved',                 34, 1, 0, '',                                                                                        '2024-05-01'),
(17, 2, 'Annual Review',            '2024-05-01', 15, 'Approved',                 31, 0, 0, '',                                                                                        '2025-05-01'),
-- T3 Medium
(4,  3, 'Initial Risk Assessment',  '2024-08-05', 13, 'Approved',                 28, 1, 0, '',                                                                                        '2025-08-05'),
(7,  3, 'Initial Risk Assessment',  '2024-10-07', 3,  'Deferred',                 45, 3, 0, 'Re-assess once data access dispute resolved with legal.',                                 '2025-04-07'),
(8,  3, 'Initial Risk Assessment',  '2023-11-06', 4,  'Approved with Conditions', 52, 3, 1, 'High bias risk: independent fairness audit required before production.',                  '2024-05-06'),
(8,  3, 'Follow-up Review',         '2024-03-15', 9,  'Approved',                 44, 0, 0, 'Fairness audit completed; Disparate Impact ratio within acceptable thresholds.',          '2025-03-15'),
(13, 3, 'Initial Risk Assessment',  '2023-08-07', 16, 'Approved',                 30, 1, 0, '',                                                                                        '2024-08-07'),
(13, 3, 'Annual Review',            '2024-08-07', 16, 'Approved',                 27, 0, 0, '',                                                                                        '2025-08-07'),
(15, 3, 'Initial Risk Assessment',  '2023-04-03', 14, 'Approved',                 29, 1, 0, '',                                                                                        '2024-04-03'),
(15, 3, 'Annual Review',            '2024-04-03', 14, 'Approved',                 26, 0, 0, '',                                                                                        '2025-04-03'),
(16, 2, 'Initial Risk Assessment',  '2024-09-02', 7,  'Approved with Conditions', 50, 2, 0, 'Agent recommendation transparency disclosure required in UI.',                            '2025-03-02'),
(18, 3, 'Initial Risk Assessment',  '2024-09-02', 8,  'Approved',                 32, 1, 0, '',                                                                                        '2025-09-02'),
(19, 3, 'Initial Risk Assessment',  '2024-07-01', 1,  'Approved',                 31, 1, 0, '',                                                                                        '2025-07-01'),
-- T4 Low
(14, 4, 'Initial Risk Assessment',  '2024-11-04', 6,  'Approved',                 18, 0, 0, '',                                                                                        '2025-11-04'),
(9,  3, 'Initial Risk Assessment',  '2025-01-06', 4,  'Pending',                  0,  0, 0, '',                                                                                        NULL),
(20, 2, 'Initial Risk Assessment',  '2024-12-02', 13, 'Approved with Conditions', 46, 2, 0, 'Pricing algorithm must not produce discriminatory outcomes; bias audit required.',        '2025-06-02');
