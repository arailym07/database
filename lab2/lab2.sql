-- Part 1
-- 1.1

CREATE DATABASE university_main
    WITH OWNER = CURRENT_USER
    TEMPLATE = template0
    ENCODING = 'UTF8';

CREATE DATABASE university_archive
    WITH OWNER = CURRENT_USER
    TEMPLATE = template0
    CONNECTION LIMIT = 50;

CREATE DATABASE university_test
    WITH OWNER = CURRENT_USER
    TEMPLATE = template0
    CONNECTION LIMIT = 10
    IS_TEMPLATE = true;


-- 1.2

CREATE TABLESPACE student_data
    LOCATION '/data/students';

CREATE TABLESPACE course_data
    OWNER CURRENT_USER
    LOCATION '/data/courses';

CREATE DATABASE university_distributed
    WITH OWNER = CURRENT_USER
    TABLESPACE = student_data
    ENCODING = 'LATIN9';



-- Part 2
-- 2.1

-- Подключение к базе данных university_main
SET search_path TO public;

-- Таблица: students (студенты)
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,       -- уникальный ID студента
    first_name VARCHAR(50),              -- имя
    last_name VARCHAR(50),               -- фамилия
    email VARCHAR(100),                  -- почта
    phone VARCHAR(15),                   -- телефон
    date_of_birth DATE,                  -- дата рождения
    enrollment_date DATE,                 -- дата зачисления
    gpa NUMERIC(4,2),                    -- средний балл (GPA)
    is_active BOOLEAN,                   -- активен ли студент
    graduation_year SMALLINT             -- год выпуска
);

-- Таблица: professors (преподаватели)
CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,     -- уникальный ID преподавателя
    first_name VARCHAR(50),              -- имя
    last_name VARCHAR(50),               -- фамилия
    email VARCHAR(100),                  -- почта
    office_number VARCHAR(20),           -- номер кабинета
    hire_date DATE,                      -- дата найма
    salary NUMERIC(12,2),                -- зарплата
    is_tenured BOOLEAN,                  -- наличие бессрочного контракта
    years_experience INTEGER             -- стаж (в годах)
);

-- Таблица: courses (курсы)
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,        -- уникальный ID курса
    course_code VARCHAR(10),             -- код курса
    course_title VARCHAR(100),           -- название курса
    description TEXT,                    -- описание
    credits SMALLINT,                    -- кредиты
    max_enrollment INTEGER,              -- макс. количество студентов
    course_fee NUMERIC(10,2),            -- стоимость курса
    is_online BOOLEAN,                   -- онлайн или оффлайн
    created_at TIMESTAMP                 -- дата создания
);

-- 2.2: Временные и специализированные таблицы

-- Таблица: class_schedule (расписание занятий)
CREATE TABLE class_schedule (
    schedule_id SERIAL PRIMARY KEY,      -- уникальный ID расписания
    course_id INTEGER,                   -- ID курса
    professor_id INTEGER,                -- ID преподавателя
    classroom VARCHAR(30),               -- аудитория
    class_date DATE,                     -- дата занятия
    start_time TIME,                     -- время начала
    end_time TIME,                       -- время окончания
    duration INTERVAL                    -- продолжительность
);

-- Таблица: student_records (учебные записи студентов)
CREATE TABLE student_records (
    record_id SERIAL PRIMARY KEY,        -- уникальный ID записи
    student_id INTEGER,                  -- ID студента
    course_id INTEGER,                   -- ID курса
    semester VARCHAR(20),                -- семестр
    year INTEGER,                        -- учебный год
    grade VARCHAR(5),                    -- оценка
    attendance_percentage NUMERIC(4,1),  -- посещаемость (%)
    submission_timestamp TIMESTAMPTZ,    -- время сдачи
    last_updated TIMESTAMPTZ             -- последнее обновление
);

-- Part 3: Расширенные операции ALTER TABLE
-- 3.1

-- Изменение таблицы students
ALTER TABLE students
    ADD COLUMN middle_name VARCHAR(30),              -- отчество
    ADD COLUMN student_status VARCHAR(20) DEFAULT 'ACTIVE', -- статус студента
    ALTER COLUMN phone TYPE VARCHAR(20),             -- изменить тип телефона
    ALTER COLUMN gpa SET DEFAULT 0.00;               -- задать дефолт для GPA

-- Изменение таблицы professors
ALTER TABLE professors
    ADD COLUMN department_code CHAR(5),              -- код кафедры
    ADD COLUMN research_area TEXT,                   -- область исследований
    ADD COLUMN last_promotion_date DATE,             -- дата последнего повышения
    ALTER COLUMN years_experience TYPE SMALLINT,     -- изменить тип стажа
    ALTER COLUMN is_tenured SET DEFAULT false;       -- задать дефолт

-- Изменение таблицы courses
ALTER TABLE courses
    ADD COLUMN prerequisite_course_id INTEGER,       -- ID предшествующего курса
    ADD COLUMN difficulty_level SMALLINT,            -- уровень сложности
    ADD COLUMN lab_required BOOLEAN DEFAULT false,   -- нужна ли лабораторная работа
    ALTER COLUMN credits SET DEFAULT 3;              -- дефолт для кредитов

-- 3.2

-- Для таблицы class_schedule
ALTER TABLE class_schedule
    ADD COLUMN room_capacity INTEGER,                -- вместимость аудитории
    DROP COLUMN duration,                            -- удалить колонку duration
    ADD COLUMN session_type VARCHAR(15),             -- тип занятия (лекция/лаб)
    ADD COLUMN equipment_needed TEXT;                -- необходимое оборудование

-- Для таблицы student_records
ALTER TABLE student_records
    ADD COLUMN extra_credit_points NUMERIC(4,1) DEFAULT 0.0, -- доп. баллы
    ADD COLUMN final_exam_date DATE,                          -- дата финального экзамена
    DROP COLUMN last_updated;                                -- удалить колонку last_updated

-- Part 4
-- 4.1

-- Таблица: departments (кафедры)
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100),        -- название кафедры
    department_code CHAR(5),             -- код кафедры
    building VARCHAR(50),                -- корпус
    phone VARCHAR(15),                   -- телефон кафедры
    budget NUMERIC(12,2),                -- бюджет
    established_year INTEGER             -- год основания
);

-- Таблица: library_books (книги библиотеки)
CREATE TABLE library_books (
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13),                       -- ISBN
    title VARCHAR(200),                  -- название книги
    author VARCHAR(100),                 -- автор
    publisher VARCHAR(100),              -- издательство
    publication_date DATE,               -- дата публикации
    price NUMERIC(10,2),                 -- цена
    is_available BOOLEAN,                -- доступна ли книга
    acquisition_timestamp TIMESTAMP      -- дата поступления
);

-- Таблица: student_book_loans (выдача книг студентам)
CREATE TABLE student_book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_id INTEGER,                  -- ID студента
    book_id INTEGER,                     -- ID книги
    loan_date DATE,                      -- дата выдачи
    due_date DATE,                       -- дата возврата
    return_date DATE,                    -- фактическая дата возврата
    fine_amount NUMERIC(10,2),           -- штраф
    loan_status VARCHAR(20)              -- статус займа
);

-- 4.2

-- 1. Добавление внешних ключей
ALTER TABLE professors
    ADD COLUMN department_id INTEGER;    -- связь с кафедрой

ALTER TABLE students
    ADD COLUMN advisor_id INTEGER;       -- научный руководитель

ALTER TABLE courses
    ADD COLUMN department_id INTEGER;    -- связь с кафедрой

-- 2. Создание справочных таблиц

-- Таблица: grade_scale (шкала оценок)
CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),                -- буквенная оценка
    min_percentage NUMERIC(4,1),         -- минимальный %
    max_percentage NUMERIC(4,1),         -- максимальный %
    gpa_points NUMERIC(3,2)              -- баллы GPA
);

-- Таблица: semester_calendar (академический календарь)
CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),           -- название семестра
    academic_year INTEGER,               -- учебный год
    start_date DATE,                     -- начало семестра
    end_date DATE,                       -- конец семестра
    registration_deadline TIMESTAMPTZ,   -- дедлайн регистрации
    is_current BOOLEAN                   -- текущий семестр?
);

-- Part 5
-- 5.1

-- 1. Удаление таблиц, если они существуют
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

-- 2. Пересоздание таблицы grade_scale с дополнительным столбцом
CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage NUMERIC(4,1),
    max_percentage NUMERIC(4,1),
    gpa_points NUMERIC(3,2),
    description TEXT                     -- описание оценки
);

-- 3. Удаление и пересоздание таблицы semester_calendar с CASCADE
DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INTEGER,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN
);

-- 5.2

-- Операции с базами данных
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;

-- Создать резервную базу university_backup из university_main
CREATE DATABASE university_backup TEMPLATE university_main;
