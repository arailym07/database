-- Part A

-- 1. Создание базы данных
CREATE DATABASE advanced_lab;

-- Используем эту базу
\c advanced_lab;   -- (для PostgreSQL; в MySQL будет USE advanced_lab;)

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INT,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100),
    budget INT,
    manager_id INT
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INT,
    start_date DATE,
    end_date DATE,
    budget INT
);



-- Part B

-- 2. Вставляем данные 
INSERT INTO employees (first_name, last_name, department)
VALUES ('Alice', 'Johnson', 'HR');

-- 3. salary и status возьмут значения по умолчанию (salary = NULL, status = 'Active')
INSERT INTO employees (first_name, last_name, department)
VALUES ('Bob', 'Smith', 'Finance');

-- 4. Добавляем 3 отдела за один раз
INSERT INTO departments (dept_name, budget, manager_id)
VALUES 
    ('HR', 100000, 1),
    ('Finance', 200000, 2),
    ('IT', 300000, 3);

-- 5. 
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Charlie', 'Brown', 'IT', 50000 * 1.1, CURRENT_DATE);

-- 6. Создаем временную таблицу temp_employees
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE 1=0;  -- создаем структуру без данных

INSERT INTO temp_employees
SELECT * FROM employees WHERE department = 'IT';



-- Part C

-- 7. Увеличиваем зарплату всех сотрудников на 10%
UPDATE employees
SET salary = salary * 1.10;

-- 8. Делаем статус 'Senior' для сотрудников с зарплатой > 60000 и датой найма до 2020-01-01
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- 9. 
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- 10.
ALTER TABLE employees ALTER COLUMN department SET DEFAULT 'General';  -- на всякий случай задаём дефолт
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. 
UPDATE departments d
SET budget = (
    SELECT AVG(e.salary) * 1.20
    FROM employees e
    WHERE e.department = d.dept_name
);

-- 12. В отделе Sales: увеличить зарплату на 15% и изменить статус
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';



-- Part D

-- 13. Удаляем всех сотрудников со статусом 'Terminated'
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. Удаляем сотрудников: зарплата < 40000, дата найма после 2023-01-01 и департамент NULL
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 15. Удаляем отделы, которые не используются в таблице employees
DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

-- 16. Удаляем проекты, у которых дата окончания раньше 2023-01-01, и возвращаем удаленные строки
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;



-- Part E

-- 17. Добавляем сотрудника без зарплаты и департамента
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Dana', 'White', NULL, NULL);

-- 18. Всем сотрудникам без департамента проставляем "Unassigned"
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. Удаляем всех сотрудников, у которых либо зарплата NULL, либо департамент NULL
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;



-- Part F

-- 20. 
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Eva', 'Green', 'Marketing', 60000, CURRENT_DATE)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21. 
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

-- 22. Удаляем сотрудников, нанятых до 2020-01-01, и возвращаем все их данные
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;



-- Part G

-- 23. 
INSERT INTO employees (first_name, last_name, department)
SELECT 'Unique', 'Person', 'R&D'
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'Unique' AND last_name = 'Person'
);

-- 24. 
UPDATE employees
SET salary = salary * CASE
    WHEN (SELECT budget FROM departments d WHERE d.dept_name = employees.department) > 100000
    THEN 1.1 ELSE 1.05 END;

-- 25. 
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
('E1', 'L1', 'Sales', 40000, CURRENT_DATE),
('E2', 'L2', 'Sales', 42000, CURRENT_DATE),
('E3', 'L3', 'Sales', 43000, CURRENT_DATE),
('E4', 'L4', 'Sales', 44000, CURRENT_DATE),
('E5', 'L5', 'Sales', 45000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.1
WHERE last_name LIKE 'L%';

-- 26. Создаем таблицу для архива
CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE 1=0;

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

-- 27. Complex business logic
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND (
    SELECT COUNT(*) FROM employees e
    WHERE e.department = (SELECT d.dept_name FROM departments d WHERE d.dept_id = p.dept_id)
  ) > 3;


