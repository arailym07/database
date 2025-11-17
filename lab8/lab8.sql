-- Part 1: Database Setup
-- Drop tables if they exist
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- Create tables
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    salary DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget DECIMAL(12,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- Insert sample data
INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);

-- Part 2: Creating Basic Indexes
-- 2.1: Create a Simple B-tree Index
CREATE INDEX emp_salary_idx ON employees(salary);

-- Verify the index
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';

-- 2.2: Create an Index on a Foreign Key
CREATE INDEX emp_dept_idx ON employees(dept_id);

-- Test the index usage
EXPLAIN SELECT * FROM employees WHERE dept_id = 101;

-- 2.3: View Index Information
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Part 3: Multicolumn Indexes
-- 3.1: Create a Multicolumn Index
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

-- Test the multicolumn index
EXPLAIN SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

-- 3.2: Understanding Column Order
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

-- Compare with queries
EXPLAIN SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
EXPLAIN SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;

-- Part 4: Unique Indexes
-- 4.1: Create a Unique Index
ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- Test the uniqueness constraint (this should fail)
-- INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
-- VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

-- 4.2: Unique Index vs UNIQUE Constraint
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

-- View the indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';

-- Part 5: Indexes and Sorting
-- 5.1: Create an Index for Sorting
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

-- Test with an ORDER BY query
EXPLAIN SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

-- 5.2: Index with NULL Handling
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

-- Test the index
EXPLAIN SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;

-- Part 6: Indexes on Expressions
-- 6.1: Create a Function-Based Index
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

-- Test the expression index
EXPLAIN SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';

-- 6.2: Index on Calculated Values
ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

-- Create index on the year extracted from hire_date
CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

-- Test the index
EXPLAIN SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

-- Part 7: Managing Indexes
-- 7.1: Rename an Index
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

-- Verify the rename
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- 7.2: Drop Unused Indexes
DROP INDEX emp_salary_dept_idx;

-- 7.3: Reindex
REINDEX INDEX employees_salary_index;

-- Part 8: Practical Scenarios
-- 8.1: Optimize a Slow Query
-- Index for the WHERE clause
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;

-- 8.2: Partial Index
CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;

-- Test the partial index
EXPLAIN SELECT proj_name, budget
FROM projects
WHERE budget > 80000;

-- 8.3: Analyze Index Usage
EXPLAIN SELECT * FROM employees WHERE salary > 52000;

-- Part 9: Index Types Comparison
-- 9.1: Create a Hash Index
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

-- Test the hash index
EXPLAIN SELECT * FROM departments WHERE dept_name = 'IT';

-- 9.2: Compare Index Types
-- B-tree index
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
-- Hash index
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);

-- Test with different queries
EXPLAIN SELECT * FROM projects WHERE proj_name = 'Website Redesign';
EXPLAIN SELECT * FROM projects WHERE proj_name > 'Database';

-- Part 10: Cleanup and Best Practices
-- 10.1: Review All Indexes
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 10.2: Drop Unnecessary Indexes
DROP INDEX IF EXISTS proj_name_hash_idx;

-- 10.3: Document Your Indexes
CREATE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    CASE 
        WHEN indexname LIKE '%salary%' THEN 'Improves salary-based queries'
        WHEN indexname LIKE '%dept%' THEN 'Improves department-based queries'
        WHEN indexname LIKE '%name%' THEN 'Improves name-based searches'
        ELSE 'General purpose index'
    END as purpose
FROM pg_indexes
WHERE schemaname = 'public';

SELECT * FROM index_documentation;
