-- Compare professors within the same department
-- Shows pairs of colleagues with large gap
-- in courses taught and total completions

WITH prof_load AS (
	SELECT p.professor_id, p.first_name, p.last_name, p.department_id,
		COUNT(DISTINCT c.course_id) AS courses_taught,
		COUNT(e.enrollment_id) FILTER (WHERE e.status = 'completed') AS completions
	FROM professors p
	JOIN courses c ON c.professor_id = p.professor_id -- exclude professors with no courses
	LEFT JOIN enrollments e ON e.course_id = c.course_id
	GROUP BY p.professor_id
)

SELECT d.name department, 
	FORMAT('%s %s', p1.first_name, p1.last_name) AS prof_a,
	FORMAT('%s %s', p2.first_name, p2.last_name) AS prof_b,
	p1.courses_taught AS courses_a, p2.courses_taught AS courses_b,
	(p1.courses_taught - p2.courses_taught) AS courses_diff,
	p1.completions AS completions_a, p2.completions AS completions_b,
	(p1.completions - p2.completions) AS completions_diff
FROM prof_load p1 -- 1st professor
JOIN prof_load p2 -- 2nd professor 
	ON p1.department_id = p2.department_id
	AND p1.professor_id < p2.professor_id
JOIN departments d ON d.department_id = p1.department_id
WHERE ABS(p1.courses_taught - p2.courses_taught) >= 3
	OR ABS(p1.completions - p2.completions) >= 30
ORDER BY d.name;
