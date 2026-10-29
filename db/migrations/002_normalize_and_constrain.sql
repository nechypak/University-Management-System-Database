-- Preserve existing IDs and enrollments while separating catalog from delivery.
CREATE TABLE academic_terms (
    term_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL CHECK (name IN ('Winter', 'Spring', 'Summer', 'Fall')),
    year INT NOT NULL CHECK (year BETWEEN 1900 AND 2200),
    UNIQUE (name, year)
);

INSERT INTO academic_terms (name, year)
SELECT DISTINCT term, year FROM courses ORDER BY year, term;

CREATE TABLE course_offerings (
    offering_id SERIAL PRIMARY KEY,
    course_id INT NOT NULL REFERENCES courses(course_id),
    professor_id INT NOT NULL REFERENCES professors(professor_id),
    term_id INT NOT NULL REFERENCES academic_terms(term_id),
    section TEXT NOT NULL CHECK (btrim(section) <> ''),
    UNIQUE (course_id, term_id, section)
);

INSERT INTO course_offerings (offering_id, course_id, professor_id, term_id, section)
SELECT c.course_id, c.course_id, c.professor_id, t.term_id, '001'
FROM courses c
JOIN academic_terms t ON t.name = c.term AND t.year = c.year;

-- setval(..., false) keeps an empty migration's first generated ID at 1.
SELECT setval(pg_get_serial_sequence('course_offerings', 'offering_id'),
              COALESCE(max(offering_id), 1), max(offering_id) IS NOT NULL)
FROM course_offerings;

ALTER TABLE enrollments RENAME COLUMN course_id TO offering_id;
ALTER TABLE courses DROP COLUMN professor_id, DROP COLUMN term, DROP COLUMN year;

ALTER TABLE professors
    ADD CONSTRAINT professors_department_fk FOREIGN KEY (department_id) REFERENCES departments(department_id);
ALTER TABLE students
    ADD CONSTRAINT students_department_fk FOREIGN KEY (major_department_id) REFERENCES departments(department_id),
    ADD CONSTRAINT students_year_check CHECK (enrollment_year BETWEEN 1900 AND 2200);
ALTER TABLE courses
    ADD CONSTRAINT courses_department_fk FOREIGN KEY (department_id) REFERENCES departments(department_id),
    ADD CONSTRAINT courses_credits_check CHECK (credits BETWEEN 1 AND 12);
ALTER TABLE enrollments
    ADD CONSTRAINT enrollments_student_fk FOREIGN KEY (student_id) REFERENCES students(student_id),
    ADD CONSTRAINT enrollments_offering_fk FOREIGN KEY (offering_id) REFERENCES course_offerings(offering_id),
    ADD CONSTRAINT enrollments_student_offering_key UNIQUE (student_id, offering_id),
    ADD CONSTRAINT enrollments_status_check CHECK (status IN ('enrolled', 'completed', 'dropped')),
    ADD CONSTRAINT enrollments_grade_status_check CHECK (
        status NOT IN ('enrolled', 'completed', 'dropped')
        OR (status = 'enrolled' AND grade IS NULL)
        OR (status = 'dropped' AND grade IS NOT DISTINCT FROM 'W')
        OR (status = 'completed' AND grade IS NOT NULL
            AND grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F'))
    );

-- Unique constraints already index their leading columns; index the other FK paths.
CREATE INDEX professors_department_idx ON professors(department_id);
CREATE INDEX students_department_idx ON students(major_department_id);
CREATE INDEX courses_department_idx ON courses(department_id);
CREATE INDEX offerings_professor_idx ON course_offerings(professor_id);
CREATE INDEX offerings_term_idx ON course_offerings(term_id);
CREATE INDEX enrollments_offering_idx ON enrollments(offering_id);
