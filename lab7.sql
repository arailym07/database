
-- Part 1
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10, 2)
);

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT,
    budget DECIMAL(10, 2)
);

INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);



-- Part 2
-- 2.1
CREATE OR REPLACE VIEW emploee_details AS
SELECT e.emp_id,
       e.emp_name,
       e.salary,
       d.dept_name,
       d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- 2.2
CREATE OR REPLACE VIEW dept_stat AS
SELECT d.dept_id,
       d.dept_name,
       COUNT(e.emp_id) AS employee_count,
       ROUND(AVG(e.salary)::numeric,2) AS average_salary,
       MAX(e.salary) AS max_salary,
       MIN(e.salary) AS min_salary
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name;

--2.3
CREATE OR REPLACE VIEW project_overview AS
SELECT p.project_id,
       p.project_name,
       p.budget,
       d.dept_id,
       d.dept_name,
       d.location,
       COALESCE(team.team_size, 0) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN (
    SELECT dept_id, COUNT(emp_id) AS team_size
    FROM employees
    GROUP BY ept_id
) team ON team.dept_id = d.dept_id;

--2.4
CREATE OR REPLACE VIEW high_earners AS
       SELECT e.emp_id,
              e.emp_name,
              e.salary,
              d.dept_name
       FROM employees e
       LEFT JOIN departments d ON e.dept_id = d.dept_id
       WHERE e.salary > 5000;



-- Part 3
-- 3.1
CREATE OR REPLACE VIEW employees_details AS
       SELECT e.emp_id,
              e.emp_name,
              e.salary,
              d.dept_name,
              d.location,
              CASE
                  WHEN e.salary > 60000 THEN "High",
                  WHEN e.salary > 50000 THEN "Medium",
                  ELSE "Standard"
              END AS  salary_grade
       FROM employees e
       JOIN departments d ON e.dept_id = d.dept_id;

-- 3.2
ALTER VIEW high_earners RENAME to top_performers;

-- 3.3
CREATE TEMPORARY VIEW temp_view AS
       SELECT emp_id, emp_name, salary FROM employees WHERE salary < 50000;
DROP VIEW IF EXISTS temp_view;



-- Part 4
-- 4.1
CREATE OR REPLACE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

-- 4.2
UPDATE empployee_salaries
SET salary = 52000
WHERE emp_name = "Oralova Arailym";

-- 4.3
INSERT_INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6,'Saltanat Kanaeva', 102, 58000);

-- 4.4
CREATE OR REPLACE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;



-- Part 5
-- 5.1
CREATE MATERIALIZED VIEW dept_summary_mv WITH DATA AS
SELECT d.dept_id,
d.dept_name,
COALESCE(emp_stats.total_employees,0) AS total_employees,
COALESCE(emp_stats.total_salaries,0) AS total_salaries,
COALESCE(proj_stats.total_projects,0) AS total_projects,
COALESCE(proj_stats.total_budget,0) AS total_project_budget
FROM departments d
LEFT JOIN (
SELECT dept_id, COUNT(*) AS total_employees, SUM(salary) AS total_salaries
FROM employees
GROUP BY dept_id
) emp_stats ON emp_stats.dept_id = d.dept_id
LEFT JOIN (
SELECT dept_id, COUNT(*) AS total_projects, SUM(budget) AS total_budget
FROM projects
GROUP BY dept_id
) proj_stats ON proj_stats.dept_id = d.dept_id;

--5.2
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

REFRESH MATERIALIZED VIEW dept_summary_mv;

--5.3
CREATE UNIQUE INDEX IF NOT EXISTS idx_dept_summary_mv_dept_id ON dept_summary_mv(dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

--5.4
CREATE MATERIALIZED VIEW project_stats_mv WITH NO DATA AS
SELECT p.project_id,
p.project_name,
p.budget,
d.dept_name,
COALESCE(emp_count.cnt,0) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN (
SELECT dept_id, COUNT(emp_id) AS cnt
FROM employees
GROUP BY dept_id
) emp_count ON emp_count.dept_id = p.dept_id;



-- Part 6
-- 6.1
CREATE ROLE analyst;
CREATE ROLE data_viewer LOGUN PASSWORD 'viewer123';
CREATE ROLE report_user LOGIN PASSWORD 'report456';

-- 6.2
CREATE ROLE db_creator LOGIN PASSWORD 'creator789' CREATEDB;
CREATE ROLE user_manager LOGIN PASSWORD 'manager101' CREATEROLE;
CREATE ROLE admin_user LOGIN PASSWORD 'admin999' SUPERUSER;

-- 6.3
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

-- 6.4
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE ROLE hr_user1 LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 LOGIN PASSWORD 'fin001';

GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

-- 6.5
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

-- 6.6
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL; -- removes password
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;



-- Part 7
-- 7.1
CREATE ROLE read_only;
DO $$
DECLARE r RECORD;
BEGIN
FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
EXECUTE format('GRANT SELECT ON TABLE public.%I TO read_only', r.tablename);
END LOOP;
END$$;

CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

GRANT INSERT, UPDATE ON employees TO senior_analyst;

--7.2
CREATE ROLE project_manager LOGIN PASSWORD 'pm123';
ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

--7.3
CREATE ROLE temp_owner LOGIN;
CREATE TABLE temp_table (id INT PRIMARY KEY);
ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;

DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

-- 7.4
CREATE OR REPLACE VIEW hr_employee_view AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 102;
GRANT SELECT ON hr_employee_view TO hr_team;

CREATE OR REPLACE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;
GRANT SELECT ON finance_employee_view TO finance_team;



-- Part 8
-- 8.1
CREATE OR REPLACE VIEW dept_dashboard AS
SELECT d.dept_id,
d.dept_name,
d.location,
COALESCE(ds.total_employees,0) AS employee_count,
ROUND(COALESCE(ds.average_salary,0)::numeric,2) AS average_salary,
COALESCE(p.active_projects,0) AS active_projects,
COALESCE(p.total_budget,0) AS total_project_budget,
CASE WHEN COALESCE(ds.total_employees,0) = 0 THEN 0
ELSE ROUND((COALESCE(p.total_budget,0) / ds.total_employees)::numeric,2)
END AS budget_per_employee
FROM departments d
LEFT JOIN (
SELECT dept_id, COUNT(*) AS total_employees, AVG(salary) AS average_salary
FROM employees GROUP BY dept_id
) ds ON ds.dept_id = d.dept_id
LEFT JOIN (
SELECT dept_id, COUNT(*) AS active_projects, COALESCE(SUM(budget),0) AS total_budget
FROM projects GROUP BY dept_id
) p ON p.dept_id = d.dept_id;

--8.2
ALTER TABLE projects
ADD COLUMN IF NOT EXISTS created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT p.project_id,
p.project_name,
p.budget,
d.dept_name,
p.created_date,
CASE
WHEN p.budget > 150000 THEN 'Critical Review Required'
WHEN p.budget > 100000 THEN 'Management Approval Needed'
ELSE 'Standard Process'
END AS approval_status
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

-- 8.3
--level 1
CREATE ROLE viewer_role;
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
EXECUTE format('GRANT SELECT ON TABLE public.%I TO viewer_role', r.tablename);
END LOOP;
END$$;

--2
CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

--3
CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

--4
CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

-- Create users and assign roles
CREATE ROLE alice LOGIN PASSWORD 'alice123';
CREATE ROLE bob LOGIN PASSWORD 'bob123';
CREATE ROLE charlie LOGIN PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;


