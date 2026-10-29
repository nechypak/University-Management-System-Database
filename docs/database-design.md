# Database design decisions

## Catalog versus delivery

Originally, `courses` held the course code, title, credits, professor, term and year. A unique course code prevented a second delivery of the same course without changing the existing record.

The new model has three responsibilities:

- `courses`: catalog definition, credits and owning department.
- `academic_terms`: one row per term name and year.
- `course_offerings`: course, professor, term and section.

An enrollment points to an offering. `(course_id, term_id, section)` is unique, and `(student_id, offering_id)` is unique. Retaking a course in a different offering remains possible. The model does not yet prevent taking two sections of the same course in one term; that policy requires a separate design decision.

During migration, each original course creates one offering with the same numeric ID and section `001`. Original enrollment IDs, dates, statuses and grades are preserved. No legacy rows are silently discarded or repaired: incompatible data causes the migration transaction to fail.

## Integrity rules

| Rule | Mechanism |
|---|---|
| Every referenced student, professor, department, course, offering and term exists | Foreign keys |
| One enrollment per student per offering | Composite unique constraint |
| One section number per course per term | Composite unique constraint |
| Credits are 1–12; years are 1900–2200 | Named or table-level check constraints |
| Terms are Winter, Spring, Summer or Fall | Check constraint |
| Enrolled means no grade | Check constraint with explicit NULL handling |
| Completed means A through F from the supported grade scale | Check constraint |
| Dropped means W | Check constraint |

The year and credit bounds are explicit demo policies, not universal university rules. There are no automatic cascading deletes: removing a referenced student or course fails instead of deleting academic history.

`CHECK` expressions must account for NULL: PostgreSQL accepts both true and unknown. Completed grades therefore require an explicit `grade IS NOT NULL`; dropped grades use `IS NOT DISTINCT FROM 'W'`.

Foreign key columns have indexes for common joins and referenced-row checks. Unique constraints already provide indexes on their leading columns. These indexes are design choices, not measured performance improvements; benchmarking is a future milestone.

## Query semantics

- Outside-major enrollment includes all statuses, including dropped registrations. It answers who registered, not who successfully completed a course.
- Catalog course counts count course definitions, regardless of how often each course runs.
- Department completions and drop rates follow the course's owning department.
- Department average GPA is an unweighted mean over completed enrollments, including F as 0. It is not credit-weighted student GPA; the column retains the original query's meaning.
- Top professors are grouped by their home department, including any cross-department teaching. Ties are broken by last name, first name and ID, so each department has at most one winner. With no completions, the selected professor can have zero completions.
- Professor load compares offerings, not distinct catalog subjects, and excludes professors without offerings.
- The catalog summary uses an inner join and omits departments without courses.

## Known limitations

The inherited synthetic data has enrollment dates that do not consistently match course terms or student entry years. This stage preserves those values and does not claim date consistency. Terms have no start/end dates yet. Capacity, prerequisites, team teaching, degree requirements, grading history and permissions are future work.

Emails remain case-sensitive unique text, matching the original schema. A future email policy should consider normalization before enforcing case-insensitive uniqueness.

Reference: [PostgreSQL constraint documentation](https://www.postgresql.org/docs/16/ddl-constraints.html).
