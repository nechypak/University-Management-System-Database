\set ON_ERROR_STOP on
BEGIN;
-- Tests run in a transaction: the demo is unchanged, including after expected errors.
CREATE FUNCTION pg_temp.expect_error(statement TEXT, expected_state TEXT, expected_constraint TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE actual_constraint TEXT;
BEGIN
    BEGIN
        EXECUTE statement;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS actual_constraint = CONSTRAINT_NAME;
        IF SQLSTATE = expected_state AND actual_constraint = expected_constraint THEN
            RETURN;
        END IF;
        RAISE;
    END;
    RAISE EXCEPTION 'Expected % / % but statement succeeded: %', expected_state, expected_constraint, statement;
END;
$$;

DO $$
BEGIN
    IF (SELECT count(*) FROM departments) <> 10
       OR (SELECT count(*) FROM professors) <> 45
       OR (SELECT count(*) FROM students) <> 60
       OR (SELECT count(*) FROM courses) <> 50
       OR (SELECT count(*) FROM course_offerings) <> 50
       OR (SELECT count(*) FROM enrollments) <> 320 THEN
        RAISE EXCEPTION 'Unexpected demo row counts';
    END IF;
    IF (SELECT count(*) FROM schema_migrations) <> 2 THEN
        RAISE EXCEPTION 'Missing migration history';
    END IF;
END;
$$;

-- Use UPDATE so failed inserts do not consume non-transactional sequence values.
SELECT pg_temp.expect_error('UPDATE students SET major_department_id = -1 WHERE student_id = 1', '23503', 'students_department_fk');
SELECT pg_temp.expect_error('UPDATE professors SET department_id = -1 WHERE professor_id = 1', '23503', 'professors_department_fk');
SELECT pg_temp.expect_error('UPDATE courses SET department_id = -1 WHERE course_id = 1', '23503', 'courses_department_fk');
SELECT pg_temp.expect_error('UPDATE course_offerings SET course_id = -1 WHERE offering_id = 1', '23503', 'course_offerings_course_id_fkey');
SELECT pg_temp.expect_error('UPDATE course_offerings SET professor_id = -1 WHERE offering_id = 1', '23503', 'course_offerings_professor_id_fkey');
SELECT pg_temp.expect_error('UPDATE course_offerings SET term_id = -1 WHERE offering_id = 1', '23503', 'course_offerings_term_id_fkey');
SELECT pg_temp.expect_error('UPDATE enrollments SET student_id = -1 WHERE enrollment_id = 1', '23503', 'enrollments_student_fk');
SELECT pg_temp.expect_error('UPDATE enrollments SET offering_id = -1 WHERE enrollment_id = 1', '23503', 'enrollments_offering_fk');
SELECT pg_temp.expect_error('UPDATE courses SET credits = 0 WHERE course_id = 1', '23514', 'courses_credits_check');
SELECT pg_temp.expect_error('UPDATE courses SET credits = 13 WHERE course_id = 1', '23514', 'courses_credits_check');
SELECT pg_temp.expect_error('UPDATE students SET enrollment_year = 1800 WHERE student_id = 1', '23514', 'students_year_check');
SELECT pg_temp.expect_error('UPDATE academic_terms SET name = ''Autumn''', '23514', 'academic_terms_name_check');
SELECT pg_temp.expect_error('UPDATE academic_terms SET year = 2201', '23514', 'academic_terms_year_check');
SELECT pg_temp.expect_error('UPDATE course_offerings SET section = '' '' WHERE offering_id = 1', '23514', 'course_offerings_section_check');
SELECT pg_temp.expect_error('UPDATE enrollments SET status = ''enrolled'', grade = ''A'' WHERE enrollment_id = 1', '23514', 'enrollments_grade_status_check');
SELECT pg_temp.expect_error('UPDATE enrollments SET status = ''completed'', grade = NULL WHERE enrollment_id = 1', '23514', 'enrollments_grade_status_check');
SELECT pg_temp.expect_error('UPDATE enrollments SET status = ''completed'', grade = ''Z'' WHERE enrollment_id = 1', '23514', 'enrollments_grade_status_check');
SELECT pg_temp.expect_error('UPDATE enrollments SET status = ''dropped'', grade = NULL WHERE enrollment_id = 1', '23514', 'enrollments_grade_status_check');
SELECT pg_temp.expect_error('UPDATE enrollments SET status = ''dropped'', grade = ''A'' WHERE enrollment_id = 1', '23514', 'enrollments_grade_status_check');
-- NULL grade satisfies the grade check for enrolled; the separate status check rejects pending.
SELECT pg_temp.expect_error('UPDATE enrollments SET status = ''pending'', grade = NULL WHERE enrollment_id = 1', '23514', 'enrollments_status_check');
SELECT pg_temp.expect_error('DELETE FROM students WHERE student_id = (SELECT student_id FROM enrollments LIMIT 1)', '23503', 'enrollments_student_fk');
SELECT pg_temp.expect_error('INSERT INTO enrollments (enrollment_id, student_id, offering_id, enrolled_on, status, grade) SELECT -1, student_id, offering_id, enrolled_on, status, grade FROM enrollments LIMIT 1', '23505', 'enrollments_student_offering_key');
SELECT pg_temp.expect_error('INSERT INTO course_offerings (offering_id, course_id, professor_id, term_id, section) SELECT -1, course_id, professor_id, term_id, section FROM course_offerings LIMIT 1', '23505', 'course_offerings_course_id_term_id_section_key');

-- Valid states and retakes: same student, same catalog course, different offering.
INSERT INTO academic_terms (term_id, name, year) VALUES (-1, 'Fall', 2099);
INSERT INTO course_offerings (offering_id, course_id, professor_id, term_id, section)
SELECT -1, o.course_id, o.professor_id, -1, '001'
FROM course_offerings o JOIN enrollments e USING (offering_id)
WHERE e.enrollment_id = 1;
INSERT INTO enrollments (enrollment_id, student_id, offering_id, enrolled_on, status, grade)
SELECT -1, student_id, -1, '2099-09-01', 'enrolled', NULL FROM enrollments WHERE enrollment_id = 1;
UPDATE enrollments SET status = 'completed', grade = 'F' WHERE enrollment_id = -1;
UPDATE enrollments SET status = 'dropped', grade = 'W' WHERE enrollment_id = -1;

ROLLBACK;
\echo 'Integrity checks passed.'
