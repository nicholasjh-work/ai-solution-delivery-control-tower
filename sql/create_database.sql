-- AI Solution Delivery Control Tower
-- Nicholas Hidalgo | Portfolio Project | Synthetic Data

CREATE DATABASE ai_control_tower;

\connect ai_control_tower

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS audit;
