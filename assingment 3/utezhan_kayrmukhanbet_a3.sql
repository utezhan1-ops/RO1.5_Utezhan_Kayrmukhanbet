ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM restaurant_service_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT ON TABLES FROM restaurant_service_readonly;

DROP OWNED BY restaurant_service_admin CASCADE;
DROP OWNED BY restaurant_service_readonly CASCADE;

DROP USER IF EXISTS db_admin_user;
DROP USER IF EXISTS db_reader_user;
DROP ROLE IF EXISTS restaurant_service_admin;
DROP ROLE IF EXISTS restaurant_service_readonly;

DROP SCHEMA IF EXISTS restaurant_service CASCADE;
CREATE SCHEMA restaurant_service;

SET search_path TO restaurant_service, public;

CREATE TABLE employee_roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    salary_rate NUMERIC(10, 2) NOT NULL CHECK (salary_rate > 0)
);

CREATE TABLE menu_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE inventory (
    ingredient_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    unit VARCHAR(10) NOT NULL
);

CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    role_id INT NOT NULL REFERENCES employee_roles(role_id) ON DELETE RESTRICT
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email_address VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dining_tables (
    table_id SERIAL PRIMARY KEY,
    table_num INT NOT NULL UNIQUE CHECK (table_num > 0),
    capacity INT NOT NULL CHECK (capacity > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'Available' CHECK (status IN ('Available', 'Occupied', 'Reserved'))
);

CREATE TABLE menu_items (
    item_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    current_price NUMERIC(10, 2) NOT NULL CHECK (current_price > 0),
    category_id INT NOT NULL REFERENCES menu_categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE recipe_items (
    recipe_id SERIAL PRIMARY KEY,
    weight NUMERIC(6, 3) NOT NULL CHECK (weight > 0),
    ingredient_id INT NOT NULL REFERENCES inventory(ingredient_id) ON DELETE CASCADE,
    item_id INT NOT NULL REFERENCES menu_items(item_id) ON DELETE CASCADE
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    table_id INT NOT NULL REFERENCES dining_tables(table_id) ON DELETE CASCADE,
    reserv_time TIMESTAMP NOT NULL,
    guests_count INT NOT NULL CHECK (guests_count > 0)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    open_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'Closed', 'Cancelled')),
    table_id INT NOT NULL REFERENCES dining_tables(table_id) ON DELETE RESTRICT,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE RESTRICT
);

CREATE TABLE order_details (
    detail_id SERIAL PRIMARY KEY,
    quantity INT NOT NULL CHECK (quantity > 0),
    price_at_sale NUMERIC(10, 2) NOT NULL CHECK (price_at_sale > 0),
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    item_id INT NOT NULL REFERENCES menu_items(item_id) ON DELETE RESTRICT
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    total_sum NUMERIC(10, 2) NOT NULL CHECK (total_sum >= 0),
    method VARCHAR(20) NOT NULL CHECK (method IN ('Cash', 'Card')),
    pay_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_id INT NOT NULL UNIQUE REFERENCES orders(order_id) ON DELETE CASCADE
);

CREATE ROLE restaurant_service_admin;
CREATE ROLE restaurant_service_readonly;

GRANT USAGE ON SCHEMA restaurant_service TO restaurant_service_admin;
GRANT USAGE ON SCHEMA restaurant_service TO restaurant_service_readonly;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA restaurant_service TO restaurant_service_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA restaurant_service TO restaurant_service_readonly;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA restaurant_service TO restaurant_service_admin;

CREATE USER db_admin_user WITH PASSWORD 'admin_secure_pass_2026';
GRANT restaurant_service_admin TO db_admin_user;

CREATE USER db_reader_user WITH PASSWORD 'reader_secure_pass_2026';
GRANT restaurant_service_readonly TO db_reader_user;

REVOKE UPDATE, DELETE, INSERT ON ALL TABLES IN SCHEMA restaurant_service FROM restaurant_service_readonly;

SET search_path TO restaurant_service, public;

INSERT INTO employee_roles (role_name, salary_rate) VALUES 
    ('Manager', 3500.00),
    ('Head Chef', 4000.00),
    ('Sous Chef', 2800.00),
    ('Senior Waiter', 1800.00),
    ('Bartender', 2000.00);

INSERT INTO menu_categories (category_name) VALUES 
    ('Appetizers'),
    ('Main Courses'),
    ('Desserts'),
    ('Alcoholic Drinks'),
    ('Soft Drinks');

INSERT INTO inventory (name, balance, unit) VALUES 
    ('Wagyu Beef Ribeye', 25.50, 'kg'), 
    ('Atlantic Salmon', 18.00, 'kg'),     
    ('Organic Avocados', 40.00, 'pcs'),   
    ('Espresso Beans', 15.50, 'kg'),     
    ('Dark Chocolate', 12.00, 'kg');     

INSERT INTO employees (first_name, last_name, phone_number, role_id) VALUES 
    ('Alexander', 'King', '+77015551122', (SELECT role_id FROM employee_roles WHERE role_name = 'Manager')),
    ('Dmitry', 'Petrov', '+77025553344', (SELECT role_id FROM employee_roles WHERE role_name = 'Head Chef')),
    ('Svetlana', 'Ivanova', '+77035555566', (SELECT role_id FROM employee_roles WHERE role_name = 'Senior Waiter')),
    ('Arman', 'Saparov', '+77055557788', (SELECT role_id FROM employee_roles WHERE role_name = 'Bartender')),
    ('Maria', 'Kuznetsova', '+77075559900', (SELECT role_id FROM employee_roles WHERE role_name = 'Sous Chef'));

INSERT INTO customers (first_name, last_name, email_address) VALUES 
    ('Askar', 'Smailov', 'askar.s@example.kz'),
    ('Elena', 'Kim', 'elena.kim@example.kz'),
    ('Rustam', 'Akhmetov', 'rustam.a@example.kz'),
    ('Aisulu', 'Omarova', 'aisulu.o@example.kz'),
    ('Murat', 'Muratov', 'murat.m@example.kz');

INSERT INTO dining_tables (table_num, capacity, status) VALUES 
    (1, 2, 'Available'),
    (2, 4, 'Occupied'),
    (3, 4, 'Available'),
    (4, 6, 'Reserved'),
    (5, 8, 'Available');

INSERT INTO menu_items (name, current_price, category_id) VALUES 
    ('Grilled Wagyu Steak', 18500.00, (SELECT category_id FROM menu_categories WHERE category_name = 'Main Courses')),
    ('Pan-Seared Salmon', 12500.00, (SELECT category_id FROM menu_categories WHERE category_name = 'Main Courses')),
    ('Avocado Tartare', 4500.00, (SELECT category_id FROM menu_categories WHERE category_name = 'Appetizers')),
    ('Chocolate Fondant', 3500.00, (SELECT category_id FROM menu_categories WHERE category_name = 'Desserts')),
    ('Signature Espresso', 1500.00, (SELECT category_id FROM menu_categories WHERE category_name = 'Soft Drinks'));

INSERT INTO recipe_items (weight, ingredient_id, item_id) VALUES 
    (0.35, (SELECT ingredient_id FROM inventory WHERE name = 'Wagyu Beef Ribeye'), (SELECT item_id FROM menu_items WHERE name = 'Grilled Wagyu Steak')),
    (0.25, (SELECT ingredient_id FROM inventory WHERE name = 'Atlantic Salmon'), (SELECT item_id FROM menu_items WHERE name = 'Pan-Seared Salmon')),
    (0.15, (SELECT ingredient_id FROM inventory WHERE name = 'Organic Avocados'), (SELECT item_id FROM menu_items WHERE name = 'Avocado Tartare')),
    (0.08, (SELECT ingredient_id FROM inventory WHERE name = 'Dark Chocolate'), (SELECT item_id FROM menu_items WHERE name = 'Chocolate Fondant')),
    (0.02, (SELECT ingredient_id FROM inventory WHERE name = 'Espresso Beans'), (SELECT item_id FROM menu_items WHERE name = 'Signature Espresso'));

INSERT INTO reservations (customer_id, table_id, reserv_time, guests_count) VALUES 
    ((SELECT customer_id FROM customers WHERE email_address = 'askar.s@example.kz'), (SELECT table_id FROM dining_tables WHERE table_num = 4), '2026-06-01 19:00:00', 5),
    ((SELECT customer_id FROM customers WHERE email_address = 'elena.kim@example.kz'), (SELECT table_id FROM dining_tables WHERE table_num = 1), '2026-06-01 20:00:00', 2),
    ((SELECT customer_id FROM customers WHERE email_address = 'rustam.a@example.kz'), (SELECT table_id FROM dining_tables WHERE table_num = 3), '2026-06-02 18:30:00', 4),
    ((SELECT customer_id FROM customers WHERE email_address = 'aisulu.o@example.kz'), (SELECT table_id FROM dining_tables WHERE table_num = 5), '2026-06-02 21:00:00', 6),
    ((SELECT customer_id FROM customers WHERE email_address = 'murat.m@example.kz'), (SELECT table_id FROM dining_tables WHERE table_num = 2), '2026-06-03 13:00:00', 2);

INSERT INTO orders (open_time, status, table_id, employee_id) VALUES 
    ('2026-05-25 12:00:00', 'Closed', (SELECT table_id FROM dining_tables WHERE table_num = 1), (SELECT employee_id FROM employees WHERE phone_number = '+77035555566')),
    ('2026-05-25 13:30:00', 'Closed', (SELECT table_id FROM dining_tables WHERE table_num = 2), (SELECT employee_id FROM employees WHERE phone_number = '+77035555566')),
    ('2026-05-25 18:00:00', 'Open', (SELECT table_id FROM dining_tables WHERE table_num = 4), (SELECT employee_id FROM employees WHERE phone_number = '+77035555566')),
    ('2026-05-25 19:15:00', 'Cancelled', (SELECT table_id FROM dining_tables WHERE table_num = 3), (SELECT employee_id FROM employees WHERE phone_number = '+77035555566')),
    ('2026-05-25 20:00:00', 'Open', (SELECT table_id FROM dining_tables WHERE table_num = 5), (SELECT employee_id FROM employees WHERE phone_number = '+77035555566'));

INSERT INTO order_details (quantity, price_at_sale, order_id, item_id) VALUES 
    (1, 18500.00, (SELECT order_id FROM orders WHERE open_time = '2026-05-25 12:00:00'), (SELECT item_id FROM menu_items WHERE name = 'Grilled Wagyu Steak')),
    (2, 1500.00, (SELECT order_id FROM orders WHERE open_time = '2026-05-25 12:00:00'), (SELECT item_id FROM menu_items WHERE name = 'Signature Espresso')),
    (1, 12500.00, (SELECT order_id FROM orders WHERE open_time = '2026-05-25 13:30:00'), (SELECT item_id FROM menu_items WHERE name = 'Pan-Seared Salmon')),
    (1, 4500.00, (SELECT order_id FROM orders WHERE open_time = '2026-05-25 18:00:00'), (SELECT item_id FROM menu_items WHERE name = 'Avocado Tartare')),
    (2, 3500.00, (SELECT order_id FROM orders WHERE open_time = '2026-05-25 19:15:00'), (SELECT item_id FROM menu_items WHERE name = 'Chocolate Fondant'));

INSERT INTO payments (total_sum, method, pay_time, order_id) VALUES 
    (21500.00, 'Card', '2026-05-25 13:10:00', (SELECT order_id FROM orders WHERE open_time = '2026-05-25 12:00:00')),
    (12500.00, 'Cash', '2026-05-25 14:45:00', (SELECT order_id FROM orders WHERE open_time = '2026-05-25 13:30:00')),
    (4500.00, 'Card', '2026-05-25 19:30:00', (SELECT order_id FROM orders WHERE open_time = '2026-05-25 18:00:00')),
    (0.00, 'Cash', '2026-05-25 19:20:00', (SELECT order_id FROM orders WHERE open_time = '2026-05-25 19:15:00')),
    (7000.00, 'Card', '2026-05-25 21:15:00', (SELECT order_id FROM orders WHERE open_time = '2026-05-25 20:00:00'));

SET search_path TO restaurant_service, public;

SELECT first_name, email_address FROM customers WHERE email_address = 'askar.s@example.kz';
UPDATE customers SET email_address = 'askar.smailov.new@example.kz' WHERE email_address = 'askar.s@example.kz';

SELECT name, current_price FROM menu_items WHERE name = 'Grilled Wagyu Steak';
UPDATE menu_items SET current_price = 19500.00 WHERE name = 'Grilled Wagyu Steak';

SELECT m.name, m.current_price, c.category_name FROM menu_items m JOIN menu_categories c ON m.category_id = c.category_id WHERE c.category_name = 'Desserts';
UPDATE menu_items m SET current_price = m.current_price * 0.90 FROM menu_categories c WHERE m.category_id = c.category_id AND c.category_name = 'Desserts';

SET search_path TO restaurant_service, public;

BEGIN;

DELETE FROM payments WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'Cancelled');
DELETE FROM order_details WHERE order_id IN (SELECT order_id FROM orders WHERE status = 'Cancelled');
DELETE FROM orders WHERE status = 'Cancelled';

SELECT COUNT(*) AS remaining_cancelled_orders FROM orders WHERE status = 'Cancelled';

ROLLBACK;