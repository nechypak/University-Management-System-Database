# Roadmap

These are planned milestones, not implemented features or open GitHub issues.

## 1. Database foundation

- Separate catalog courses, academic terms and teaching offerings.
- Enforce referential integrity and enrollment rules.
- Provide migrations, synthetic seed data and reproducible local setup.
- Verify constraints, legacy migration and analytical query execution in CI.

Implementation is in this change. Release only after review and successful checks.

## 2. Student academic analytics

- Define grade-point policy and retake handling explicitly.
- Build a credit-weighted transcript with term and cumulative GPA.
- Test calculations against small, hand-calculated fixtures, including F, dropped courses and students with no grades.
- Add degree requirements and a report of remaining credits and required courses.

## 3. Advanced SQL

- Represent course prerequisites and traverse their chains with recursive CTEs.
- Prevent prerequisite cycles and explain the chosen strategy.
- Find eligible courses and compare cohort outcomes with window functions.

## 4. Transactions and performance

- Add capacity and registration using a documented locking strategy.
- Reproduce two concurrent registrations for the final place and verify the outcome.
- Generate a larger, repeatable dataset; capture EXPLAIN (ANALYZE, BUFFERS) before and after indexing.
- Report actual measurements and write-cost tradeoffs rather than promising a speedup.
