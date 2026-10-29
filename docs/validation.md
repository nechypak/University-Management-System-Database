# Foundation validation

Local verification used the project's PostgreSQL 16 container and the original synthetic dataset:

- Fresh schema creation and demo seed completed successfully.
- A second `db/migrate.sql` run skipped applied migrations successfully.
- Integrity checks passed, including orphan references, NULL grade handling, duplicate registrations, deletion protection and a valid retake.
- The legacy upgrade fixture preserved enrollment IDs, grades, course associations and professor/term assignments; new offering IDs continued after migrated IDs.
- The complete original schema and all 320 enrollments were loaded into a separate database; `db/adopt_legacy.sql` and the integrity suite passed there too.
- All four analytical queries executed successfully.

Observed demo counts: 10 departments, 45 professors, 60 students, 50 courses, 50 offerings and 320 enrollments. The KPI query returned 10 departments, and the professor comparison returned 2 pairs.

The workflow additionally configures PostgreSQL 14 and 18. Consult actual GitHub Actions runs before treating those versions as verified. This stage does not include performance benchmarks or a credit-weighted GPA implementation.
