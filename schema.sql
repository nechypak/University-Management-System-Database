-- psql entry point for a NEW demo database. Does not drop existing tables.
-- For schema-only changes, run db/migrate.sql instead.
\set ON_ERROR_STOP on
\ir db/migrate.sql
\ir db/seeds/demo.sql
