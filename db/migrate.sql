\set ON_ERROR_STOP on
-- One transaction and one advisory lock: no partial or concurrent migrations.
BEGIN;
SELECT pg_advisory_xact_lock(864020261);
CREATE TABLE IF NOT EXISTS schema_migrations (
    version INT PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
SELECT NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = 1) AS apply_001 \gset
\if :apply_001
    \ir migrations/001_initial.sql
    INSERT INTO schema_migrations (version, description) VALUES (1, 'Initial university schema');
\endif
SELECT NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = 2) AS apply_002 \gset
\if :apply_002
    \ir migrations/002_normalize_and_constrain.sql
    INSERT INTO schema_migrations (version, description) VALUES (2, 'Normalize offerings and enforce integrity');
\endif
COMMIT;
