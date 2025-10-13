
-- PART 1: CHECK Constraints

-- Task 1.1: Basic CHECK Constraint - employees
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65), -- Age must be between 18 and 65
    salary NUMERIC CHECK (salary > 0)          -- Salary must be positive
);

-- Valid data
INSERT INTO employees VALUES (1, 'Alice', 'Smith', 30, 50000);
INSERT INTO employees VALUES (2, 'Bob', 'Johnson', 45, 70000);

-- Invalid data (will fail)
-- INSERT INTO employees VALUES (3, 'Charlie', 'Brown', 16, 40000); -- age < 18
-- INSERT INTO employees VALUES (4, 'Diana', 'White', 28, 0);       -- salary = 0

-- Task 1.2: Named CHECK Constraint - products_catalog
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND
        discount_price > 0 AND
        discount_price < regular_price
    )
);

-- Valid data
INSERT INTO products_catalog VALUES (1, 'Laptop', 1200, 1000);
INSERT INTO products_catalog VALUES (2, 'Monitor', 300, 250);

-- Invalid data (will fail)
-- INSERT INTO products_catalog VALUES (3, 'Keyboard', 0, 10);    -- regular_price = 0
-- INSERT INTO products_catalog VALUES (4, 'Mouse', 25, 0);       -- discount_price = 0
-- INSERT INTO products_catalog VALUES (5, 'Headphones', 100, 120); -- discount > regular

-- Task 1.3: Multiple Column CHECK - bookings
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER,
    CHECK (num_guests BETWEEN 1 AND 10),               -- Guests must be 1-10
    CHECK (check_out_date > check_in_date)             -- Dates must be valid
);

-- Valid data
INSERT INTO bookings VALUES (1, '2025-11-01', '2025-11-05', 2);
INSERT INTO bookings VALUES (2, '2025-12-10', '2025-12-15', 4);

-- Invalid data
-- INSERT INTO bookings VALUES (3, '2025-11-01', '2025-11-03', 0);  -- guests = 0
-- INSERT INTO bookings VALUES (4, '2025-11-10', '2025-11-09', 3);  -- check_out < check_in



-- PART 2: NOT NULL Constraints

-- Task 2.1: NOT NULL - customers
CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,                    -- nullable
    registration_date DATE NOT NULL
);

-- Valid
INSERT INTO customers VALUES (1, 'alice@example.com', '123-456-7890', '2025-01-10');
INSERT INTO customers VALUES (2, 'bob@example.com', NULL, '2025-02-15');

-- Invalid
-- INSERT INTO customers VALUES (3, NULL, '555-0000', '2025-03-01');  -- email is NULL
-- INSERT INTO customers VALUES (4, 'kate@example.com', '555-1234', NULL); -- registration_date is NULL

-- Task 2.2: Combine NOT NULL + CHECK - inventory
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Valid
INSERT INTO inventory VALUES (1, 'USB Cable', 100, 5.99, NOW());
INSERT INTO inventory VALUES (2, 'HDMI Cable', 50, 9.99, NOW());

-- Invalid
-- INSERT INTO inventory VALUES (3, NULL, 20, 5.99, NOW()); -- item_name is NULL
-- INSERT INTO inventory VALUES (4, 'Mouse Pad', -5, 3.99, NOW()); -- quantity < 0
-- INSERT INTO inventory VALUES (5, 'Adapter', 10, 0, NOW()); -- unit_price = 0



-- PART 3: UNIQUE Constraints

-- Task 3.1: UNIQUE - users
CREATE TABLE users (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

-- Valid
INSERT INTO users VALUES (1, 'alice123', 'alice@example.com', NOW());
INSERT INTO users VALUES (2, 'bob456', 'bob@example.com', NOW());

-- Invalid
-- INSERT INTO users VALUES (3, 'alice123', 'kate@example.com', NOW()); -- duplicate username
-- INSERT INTO users VALUES (4, 'charlie789', 'bob@example.com', NOW()); -- duplicate email

-- Task 3.2: Multi-column UNIQUE
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);

-- Valid
INSERT INTO course_enrollments VALUES (1, 1001, 'CS101', 'Fall2025');
INSERT INTO course_enrollments VALUES (2, 1002, 'CS101', 'Fall2025');

-- Invalid
-- INSERT INTO course_enrollments VALUES (3, 1001, 'CS101', 'Fall2025'); -- duplicate combination



-- PART 4: PRIMARY KEY Constraints--

-- Task 4.1: Single-column PRIMARY KEY - departments
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

-- Valid
INSERT INTO departments VALUES (1, 'HR', 'New York');
INSERT INTO departments VALUES (2, 'IT', 'Chicago');
INSERT INTO departments VALUES (3, 'Finance', 'Los Angeles');

-- Invalid
-- INSERT INTO departments VALUES (1, 'Marketing', 'Miami'); -- duplicate dept_id
-- INSERT INTO departments VALUES (NULL, 'Legal', 'Boston'); -- NULL primary key

-- Task 4.2: Composite PRIMARY KEY - student_courses
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

-- Valid
INSERT INTO student_courses VALUES (2001, 101, '2025-09-01', 'A');
INSERT INTO student_courses VALUES (2002, 101, '2025-09-01', 'B');

-- Invalid
-- INSERT INTO student_courses VALUES (2001, 101, '2025-09-01', 'C'); -- duplicate PK



-- PART 5: FOREIGN KEY Constraints

-- Task 5.1: Basic FOREIGN KEY - employees_dept
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

-- Valid
INSERT INTO employees_dept VALUES (1, 'John Doe', 1, '2025-03-10');
INSERT INTO employees_dept VALUES (2, 'Jane Roe', 2, '2025-04-01');

-- Invalid
-- INSERT INTO employees_dept VALUES (3, 'Ghost Employee', 99, '2025-05-01'); -- non-existent dept_id

-- Task 5.2: Library schema with multiple FOREIGN KEYs
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

-- Sample data
INSERT INTO authors VALUES (1, 'J.K. Rowling', 'UK'), (2, 'George Orwell', 'UK');
INSERT INTO publishers VALUES (1, 'Penguin Books', 'London'), (2, 'Bloomsbury', 'Oxford');
INSERT INTO books VALUES (1, '1984', 2, 1, 1949, '978-0451524935');
INSERT INTO books VALUES (2, '
