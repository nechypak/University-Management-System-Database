-- Average credits per course, plus total count of courses 

SELECT d.name department, 
	ROUND(AVG(c.credits)::NUMERIC, 2) AS avg_credits,
	COUNT(*) AS total_courses
FROM departments d
JOIN courses c ON c.department_id = d.department_id
GROUP BY department 
ORDER BY total_courses DESC; 