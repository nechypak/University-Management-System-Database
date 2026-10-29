-- Original table structure, retained as the migration baseline.
CREATE TABLE departments (
  department_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  building TEXT NOT NULL
);

CREATE TABLE professors (
  professor_id SERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  department_id INT NOT NULL
);

CREATE TABLE students (
  student_id SERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  enrollment_year INT NOT NULL,
  major_department_id INT NOT NULL
);

CREATE TABLE courses (
  course_id SERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  department_id INT NOT NULL,
  professor_id INT NOT NULL,
  credits INT NOT NULL,
  term TEXT NOT NULL,
  year INT NOT NULL
);

CREATE TABLE enrollments (
  enrollment_id SERIAL PRIMARY KEY,
  student_id INT NOT NULL,
  course_id INT NOT NULL,
  enrolled_on DATE NOT NULL,
  status TEXT NOT NULL,
  grade TEXT
);
