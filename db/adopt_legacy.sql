\set ON_ERROR_STOP on
-- Only for a database created with the original pre-migration schema.sql.
-- Back up first. CREATE TABLE fails safely if migration tracking already exists.
BEGIN;
SELECT pg_advisory_xact_lock(864020261);
CREATE TABLE schema_migrations (
    version INT PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
INSERT INTO schema_migrations (version, description) VALUES (1, 'Adopt original university schema');
\ir migrations/002_normalize_and_constrain.sql
INSERT INTO schema_migrations (version, description) VALUES (2, 'Normalize offerings and enforce integrity');
COMMIT;
