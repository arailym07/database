
-- 3.1 Setup: Create Test Database

DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- Insert test data
INSERT INTO accounts (name, balance) VALUES
('Alice', 1000.00),
('Bob', 500.00),
('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
('Joe''s Shop', 'Coke', 2.50),
('Joe''s Shop', 'Pepsi', 3.00);


-- 3.2 Task 1: Basic Transaction with COMMIT

BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
COMMIT;

SELECT * FROM accounts;


-- 3.3 Task 2: Using ROLLBACK

BEGIN;
UPDATE accounts SET balance = balance - 500.00 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';


-- 3.4 Task 3: Working with SAVEPOINTS

BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';

SAVEPOINT my_savepoint;

UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';

ROLLBACK TO my_savepoint;

UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';

COMMIT;

SELECT * FROM accounts;


-- 3.5 Task 4: Isolation Level Demonstration

-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop'; -- Видит Coke, Pepsi
-- Ждем Terminal 2
SELECT * FROM products WHERE shop = 'Joe''s Shop'; -- Видит только Fanta (после COMMIT Terminal 2)
COMMIT;

-- Terminal 2
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;


-- 3.6 Task 5: Phantom Read (REPEATABLE READ)

-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop'; -- MAX: 3.00, MIN: 2.50
-- Ждем Terminal 2
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop'; -- MAX: 3.00, MIN: 2.50
COMMIT;

-- Terminal 2:
BEGIN;
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;


-- 3.7 Task 6: Dirty Read (READ UNCOMMITTED)

-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop'; -- Видит исходные данные
-- Ждем Terminal 2 UPDATE
SELECT * FROM products WHERE shop = 'Joe''s Shop'; -- Видит Fanta с ценой 99.99
-- Ждем Terminal 2 ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop'; -- Видит исходную цену Fanta
COMMIT;

-- Terminal 2:
BEGIN;
UPDATE products SET price = 99.99 WHERE product = 'Fanta';
-- Ждем (не коммитим)
ROLLBACK;


-- 4. Independent 1
BEGIN;
DO $$
DECLARE
    bob_balance DECIMAL;
BEGIN
    SELECT balance INTO bob_balance FROM accounts WHERE name = 'Bob';
    IF bob_balance >= 200 THEN
        UPDATE accounts SET balance = balance - 200 WHERE name = 'Bob';
        UPDATE accounts SET balance = balance + 200 WHERE name = 'Wally';
        COMMIT;
        RAISE NOTICE 'Перевод успешно выполнен';
    ELSE
        ROLLBACK;
        RAISE NOTICE 'Недостаточно средств у Bob';
    END IF;
END $$;


-- 4. Independent 2
BEGIN;
INSERT INTO products (shop, product, price) VALUES ('New Shop', 'Water', 1.00);
SAVEPOINT sp1;
UPDATE products SET price = 1.50 WHERE product = 'Water';
SAVEPOINT sp2;
DELETE FROM products WHERE product = 'Water';
ROLLBACK TO sp1;
COMMIT;
-- В таблице products есть запись ('New Shop', 'Water', 1.00)


-- 4. Independent 3
-- Terminal 1 (READ COMMITTED - может привести к overdraft)
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alice'; -- 900.00
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
-- Terminal 2 одновременно делает то же самое
COMMIT;

-- Terminal 1 (SERIALIZABLE - предотвращает конфликт)
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';


-- 4. Independent Exercise 4
-- MAX < MIN problem demonstration
-- Terminal 1
UPDATE Sells SET price = 5.00 WHERE product = 'Coke';
-- Terminal 2
SELECT MAX(price) FROM Sells WHERE shop = 'Joe''s Shop'; -- Может получить 5.00
-- Terminal 1
UPDATE Sells SET price = 1.00 WHERE product = 'Pepsi';
-- Terminal 2
SELECT MIN(price) FROM Sells WHERE shop = 'Joe''s Shop'; -- Может получить 1.00
-- Рез: MAX = 5.00, MIN = 1.00

-- transaction
-- Terminal 2:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM Sells WHERE shop = 'Joe''s Shop';
COMMIT;
