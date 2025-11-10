
-- Part 1: Database Setup

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

-- Part 2: CROSS JOIN Exercises

-- 2.1
-- Show all possible combinations of employees and departments
SELECT e.emp_name, d.dept_name
FROM employees e
CROSS JOIN departments d;

-- 2.2
-- a) Comma notation (old-style implicit cross join)
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

-- b) INNER JOIN with TRUE condition (explicit equivalent)
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

-- 2.3

SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;


-- Part 3: INNER JOIN Exercises
-- 3.1 
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- 3.2

SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);

-- 3.3

SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

-- 3.4
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id
ORDER BY e.emp_name, p.project_name;


-- Part 4: LEFT JOIN Exercises

-- 4.1

SELECT e.emp_name,
       e.dept_id AS emp_dept,
       d.dept_id AS dept_dept,
       d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
ORDER BY e.emp_id;

-- 4.2
SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id)
ORDER BY emp_id;

-- 4.3
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

-- 4.4
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;


-- Part 5: RIGHT JOIN Exercises

-- 5.1
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_id, e.emp_name;

-- 5.2
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
ORDER BY d.dept_id, e.emp_name;

-- 5.3
SELECT d.dept_name, d.location
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;


-- Part 6: FULL JOIN Exercises

-- 6.1: Basic FULL JOIN
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
ORDER BY COALESCE(e.emp_id, d.dept_id);

-- 6.2: FULL JOIN with Projects
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_id, p.project_id;

-- 6.3: Find Orphaned Records
SELECT
CASE
    WHEN e.emp_id IS NULL THEN 'Department without employees'
    WHEN d.dept_id IS NULL THEN 'Employee without department'
    ELSE 'Matched'
END AS record_status,
e.emp_name,
d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL
ORDER BY record_status, e.emp_name;


-- Part 7: ON vs WHERE Clause

-- 7.1
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A'
ORDER BY e.emp_id;

-- 7.2
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A'
ORDER BY e.emp_id;


SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';


-- Part 8: Complex JOIN Scenarios
-- 8.1
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

-- 8.2
ALTER TABLE employees ADD COLUMN manager_id INT;

-- Update with sample data
UPDATE employees SET manager_id = 3 WHERE emp_id = 1; -- John Smith -> manager Mike Johnson
UPDATE employees SET manager_id = 3 WHERE emp_id = 2; -- Jane Doe -> manager Mike Johnson
UPDATE employees SET manager_id = NULL WHERE emp_id = 3; -- Mike Johnson -> no manager
UPDATE employees SET manager_id = 3 WHERE emp_id = 4; -- Sarah Williams -> manager Mike Johnson
UPDATE employees SET manager_id = 3 WHERE emp_id = 5; -- Tom Brown -> manager Mike Johnson

-- Self join query: show employee and their manager name
SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
ORDER BY e.emp_id;

-- 8.3: Join with Subquery

SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;


-- Lab Questions 

-- 1) 
--    INNER JOIN: returns only rows where there is a match in both tables.
--    LEFT JOIN: returns all rows from the left table and matched rows from the right table; unmatched right-side columns are NULL.
-- When to use: use INNER JOIN when you only want matched data; LEFT JOIN when you want all left-side rows even if no match.

-- 2) When you need all combinations (cartesian product), e.g., scheduling/availability matrix, creating test data combinations, price matrix for product options.

-- 3) For outer joins (LEFT/RIGHT), placing a filter in ON affects which rows match and which become NULL but retains all rows from preserved side; placing filter in WHERE filters entire result after join, possibly removing rows that were preserved by the outer join. For INNER JOIN, non-matching rows are discarded anyway so ON vs WHERE yields same result.

-- 4) 5 * 10 = 50

-- 5) NATURAL JOIN automatically joins on all columns with the same name in both tables.

-- 6) Ambiguity and accidental joins on unintended columns (if a column with same name exists but isn't a logical join key), maintenance problems when schema changes (new columns with same names), less readability.

-- 7) Convert this LEFT JOIN to a RIGHT JOIN:
--    SELECT * FROM A LEFT JOIN B ON A.id = B.id
-- Conversion (swap order):
--    SELECT * FROM B RIGHT JOIN A ON A.id = B.id

-- 8) Use FULL OUTER JOIN when you need all rows from both tables, including unmatched rows from either side, with NULLs where matches are missing. Useful for identifying or combining data where both sides may have exclusive records.







-- 1

SELECT
    d.dept_name,
    d.location,
    COUNT(DISTINCT e.emp_id) AS employee_count,
    COUNT(DISTINCT p.proj_id) AS project_count,
FROM departments d
    LEFT JOIN employees e ON d.dept_id = e.dept_id
    LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name, d.location
HAVING()


--  2

SELECT
    emp_name,
    salary,
    dept_id
FROM employees
WHERE dept_id IS NULL


-- 3

SELECT
    project_name,
    budget,
    dept_id
FROM projects
WHERE dept_id IS NULL

