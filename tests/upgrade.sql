\set ON_ERROR_STOP on
BEGIN;
-- Exercise the data migration on an isolated legacy schema.
CREATE SCHEMA upgrade_test;
SET LOCAL search_path = upgrade_test;
\ir ../db/migrations/001_initial.sql
INSERT INTO departments VALUES (7, 'Computer Science', 'Engineering');
INSERT INTO professors VALUES (13, 'Ada', 'Lovelace', 'ada@example.edu', 7);
INSERT INTO students VALUES (21, 'Alex', 'Smith', 'alex@example.edu', 2024, 7);
INSERT INTO courses VALUES (42, 'CS101', 'Introduction', 7, 13, 4, 'Fall', 2024);
INSERT INTO enrollments VALUES (99, 21, 42, '2024-09-01', 'completed', 'A');
\ir ../db/migrations/002_normalize_and_constrain.sql
DO $$
DECLARE next_offering INT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM enrollments e
        JOIN course_offerings o USING (offering_id)
        JOIN courses c USING (course_id)
        JOIN academic_terms t USING (term_id)
        WHERE e.enrollment_id = 99 AND e.student_id = 21 AND e.grade = 'A'
          AND o.offering_id = 42 AND c.course_id = 42 AND c.credits = 4
          AND o.professor_id = 13 AND t.name = 'Fall' AND t.year = 2024
    ) THEN
        RAISE EXCEPTION 'Migration did not preserve the original enrollment and offering';
    END IF;
    INSERT INTO course_offerings (course_id, professor_id, term_id, section)
    SELECT 42, 13, term_id, '002' FROM academic_terms
    RETURNING offering_id INTO next_offering;
    IF next_offering <> 43 THEN
        RAISE EXCEPTION 'Offering sequence was not advanced: %', next_offering;
    END IF;
END;
$$;
ROLLBACK;
\echo 'Legacy upgrade checks passed.'
