# Migration guide

## New database

Run `make setup`, or use `psql -X -v ON_ERROR_STOP=1 -d university_db -f schema.sql` against an empty database.

`db/migrate.sql` applies `001_initial.sql` and `002_normalize_and_constrain.sql`, recording them in `schema_migrations`. The original five-table structure is retained as migration 001 to make the evolution explicit. The seed is separate and loads into the final schema.

The migration runner uses one transaction and a transaction-level advisory lock. Failed migrations roll back together. Repeating the runner skips applied versions. It intentionally has no automatic rollback or checksum system. Do not edit migrations after publishing them; add new ones.

## Upgrade an original database

This path is only for the original five-table database with no `schema_migrations` table. First make a backup with `pg_dump` and verify that it can be restored in a separate database.

```sh
pg_dump -d university_db -Fc -f university_before_upgrade.dump
psql -X -v ON_ERROR_STOP=1 -d university_db -f db/adopt_legacy.sql
```

Adoption records version 001 and applies version 002 in one transaction. A pre-existing migration history table causes adoption to fail safely. If original data violates the new rules, the transaction aborts; inspect and resolve the reported violation before retrying. Do not seed an existing database.

Breaking SQL changes:

- `enrollments.course_id` becomes `enrollments.offering_id`.
- `courses.professor_id` moves to `course_offerings.professor_id`.
- `courses.term` and `courses.year` move to `academic_terms.name` and `academic_terms.year`.
- Course-to-enrollment joins now pass through `course_offerings`.

Repository examples have been updated. External queries must be updated too. The original enrollments and their associations are preserved.

## Add a future migration

1. Create the next numbered SQL file in `db/migrations/`.
2. Add its guarded include and version record to `db/migrate.sql` inside the existing transaction.
3. Add tests for both valid behavior and rejected data, and for any data transformation.
4. Run migration twice, integrity checks and example queries against a dedicated database.
5. Describe the migration impact in the pull request.

## Retest from scratch

For local development only, `docker compose down -v` removes this Compose project's database volume permanently. Start a fresh demo with `make setup`. Ordinary `make down` preserves the data.
