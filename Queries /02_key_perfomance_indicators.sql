-- Query demonstrates one row per department showing key metrics like: majors_count, 
--		courses_offered, completed_enrollments, avg_gpa, drop_rate
-- As well as returns top professor based on total completions

WITH dept_base AS (
	SELECT d.department_id, d.name
	FROM departments d
),

grade_map AS (  -- CTE translates varchar grade ('A', 'A-' and etc.) to numeric values
	SELECT e.enrollment_id, e.course_id, e.student_id, e.status,
		CASE e.grade 
			WHEN 'A'  THEN 4.0 WHEN 'A-' THEN 3.7
			WHEN 'B+' THEN 3.3 WHEN 'B'  THEN 3.0 WHEN 'B-' THEN 2.7
	        WHEN 'C+' THEN 2.3 WHEN 'C'  THEN 2.0 WHEN 'C-' THEN 1.7
	        WHEN 'D'  THEN 1.0 WHEN 'F'  THEN 0.0
	        	ELSE NULL  -- case when course is incomplete, withdrawn or in progress (NULL)
	        		END AS gpa
	  FROM enrollments e
),

dept_course_stats AS ( -- dept_course_stats CTE shows how many distinct courses each department offers 
	SELECT d.department_id, 
		COUNT(DISTINCT c.course_id) AS courses_offered 
	FROM dept_base d
	LEFT JOIN courses c ON d.department_id = c.department_id 
	GROUP BY d.department_id
),

dept_major_stats AS (   -- how many student majors in each department 
  SELECT d.department_id,
         COUNT(DISTINCT s.student_id) AS majors_count
  FROM dept_base d
  LEFT JOIN students s ON s.major_department_id = d.department_id
  GROUP BY d.department_id
),

dept_enrollment_stats AS ( -- totals, drops, avg GPA and completions 
	SELECT d.department_id,
		COUNT(e.enrollment_id) AS total_enrollments,
		COUNT(*) FILTER (WHERE e.status = 'completed') AS completed_enrollments,
		COUNT(*) FILTER (WHERE e.status = 'dropped') AS dropped_enrollments,
		AVG(g.gpa) FILTER (WHERE e.status = 'completed') AS avg_gpa
	FROM dept_base d
	LEFT JOIN courses c ON d.department_id = c.department_id	
	LEFT JOIN enrollments e ON e.course_id = c.course_id
  	LEFT JOIN grade_map g ON g.enrollment_id = e.enrollment_id
 	GROUP BY d.department_id
),

prof_completions AS (  -- completions per professor 
	SELECT p.professor_id,p.department_id,
		COUNT(*) FILTER (WHERE e.status = 'completed') AS completions
	FROM professors p
	LEFT JOIN courses c ON c.professor_id = p.professor_id
	LEFT JOIN enrollments e ON e.course_id = c.course_id
	GROUP BY p.professor_id, p.department_id
),

top_prof AS (  -- pick top prof per department by completions (ties handled by name)
	SELECT t.department_id, t.professor_id, t.completions,	p.first_name, p.last_name,
		RANK() OVER (PARTITION BY t.department_id
			ORDER BY t.completions DESC, p.last_name, p.first_name) AS rnk
	FROM prof_completions t
	JOIN professors p ON p.professor_id = t.professor_id
),

dept_kpis AS (  -- combine all department-level indicators (KPI) 
	SELECT d.department_id, d.name AS department, m.majors_count, cs.courses_offered, es.completed_enrollments,
		ROUND(es.avg_gpa::numeric, 2) AS avg_gpa,
		ROUND(CASE WHEN es.total_enrollments > 0
				THEN (es.dropped_enrollments::numeric / es.total_enrollments) * 100
				ELSE NULL END, 1) AS drop_rate_pct
	FROM dept_base d
	LEFT JOIN dept_major_stats m USING (department_id)
	LEFT JOIN dept_course_stats cs USING (department_id)
	LEFT JOIN dept_enrollment_stats es USING (department_id)
)

SELECT dk.department, dk.majors_count, dk.courses_offered, dk.completed_enrollments, dk.avg_gpa, dk.drop_rate_pct,
		FORMAT('%s %s', tp.first_name, tp.last_name) AS top_professor, -- join two columns 'first_name' and 'last_name' into one
		tp.completions AS top_prof_completed
FROM dept_kpis dk
LEFT JOIN top_prof tp ON tp.department_id = dk.department_id
	AND tp.rnk = 1
ORDER BY dk.department;
