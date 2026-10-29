-- Students who have taken at least one course outside their major department
SELECT DISTINCT s.student_id, s.first_name, s.last_name
FROM students s
WHERE EXISTS ( -- given subquery fetch all required data and filters it using WHERE
	SELECT 1
	FROM enrollments e
	JOIN course_offerings o ON o.offering_id = e.offering_id
	JOIN courses c ON c.course_id = o.course_id
	WHERE e.student_id = s.student_id
		AND s.major_department_id <> c.department_id
)
ORDER BY s.student_id;
