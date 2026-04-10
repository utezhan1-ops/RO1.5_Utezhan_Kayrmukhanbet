CREATE SCHEMA IF NOT EXISTS restaurant_service;
SET search_path TO restaurant_service;

CREATE TABLE IF NOT EXISTS employee_roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL,
    salary_rate DECIMAL(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS menu_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS inventory (
    ingredient_id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    balance DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    CONSTRAINT check_inv_balance CHECK (balance >= 0)
);

CREATE TABLE IF NOT EXISTS employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    role_id INT NOT NULL,
    CONSTRAINT fk_emp_role FOREIGN KEY (role_id) REFERENCES employee_roles(role_id)
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    email_address VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS dining_tables (
    table_id SERIAL PRIMARY KEY,
    table_num INT NOT NULL UNIQUE,
    capacity INT NOT NULL,
    status VARCHAR(15) DEFAULT 'Available',
    CONSTRAINT check_table_status CHECK (status IN ('Available', 'Occupied', 'Reserved'))
);

CREATE TABLE IF NOT EXISTS menu_items (
    item_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    current_price DECIMAL(10, 2) NOT NULL,
    category_id INT NOT NULL,
    CONSTRAINT fk_menu_cat FOREIGN KEY (category_id) REFERENCES menu_categories(category_id)
);

CREATE TABLE IF NOT EXISTS recipe_items (
    recipe_id SERIAL PRIMARY KEY,
    weight DECIMAL(10, 2) NOT NULL,
    ingredient_id INT NOT NULL,
    item_id INT NOT NULL,
    CONSTRAINT check_recipe_weight CHECK (weight > 0),
    CONSTRAINT fk_recipe_inv FOREIGN KEY (ingredient_id) REFERENCES inventory(ingredient_id),
    CONSTRAINT fk_recipe_menu FOREIGN KEY (item_id) REFERENCES menu_items(item_id)
);

CREATE TABLE IF NOT EXISTS reservations (
    reservation_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    table_id INT NOT NULL,
    reserv_time TIMESTAMP NOT NULL,
    guests_count INT NOT NULL,
    CONSTRAINT check_reserv_date CHECK (reserv_time > '2026-01-01 00:00:00'),
    CONSTRAINT fk_res_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_res_table FOREIGN KEY (table_id) REFERENCES dining_tables(table_id)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    open_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(15) NOT NULL,
    table_id INT NOT NULL,
    employee_id INT NOT NULL,
    CONSTRAINT fk_ord_table FOREIGN KEY (table_id) REFERENCES dining_tables(table_id),
    CONSTRAINT fk_ord_emp FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE IF NOT EXISTS order_details (
    detail_id SERIAL PRIMARY KEY,
    quantity INT NOT NULL,
    price_at_sale DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * price_at_sale) STORED,
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    CONSTRAINT check_qty CHECK (quantity > 0),
    CONSTRAINT fk_det_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_det_item FOREIGN KEY (item_id) REFERENCES menu_items(item_id)
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id SERIAL PRIMARY KEY,
    total_sum DECIMAL(10, 2) NOT NULL,
    method VARCHAR(10) NOT NULL,
    pay_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    order_id INT UNIQUE NOT NULL,
    CONSTRAINT fk_pay_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

INSERT INTO employee_roles (role_name, salary_rate) VALUES 
('Manager', 55.00), 
('Waiter', 20.00), 
('Chef', 45.00);

INSERT INTO menu_categories (category_name) VALUES 
('Starters'), 
('Main Course'), 
('Drinks');

INSERT INTO inventory (name, balance, unit) VALUES 
('Potato', 50.50, 'kg'), 
('Salmon', 10.00, 'kg'), 
('Coffee beans', 5.00, 'kg');

INSERT INTO employees (first_name, last_name, phone_number, role_id) VALUES 
('John', 'Doe', '+123456789', 1), 
('Alice', 'Smith', '+198765432', 2);

INSERT INTO customers (first_name, last_name, email_address) VALUES 
('Bob', 'Marley', 'bob@example.com'), 
('Charlie', 'Brown', 'charlie@example.com');

INSERT INTO dining_tables (table_num, capacity, status) VALUES 
(1, 4, 'Available'), 
(2, 2, 'Available'), 
(3, 6, 'Reserved');

INSERT INTO menu_items (name, current_price, category_id) VALUES 
('Steak', 25.99, 2), 
('Cappuccino', 4.50, 3);

INSERT INTO recipe_items (weight, ingredient_id, item_id) VALUES 
(0.3, 2, 1), 
(0.02, 3, 2);

INSERT INTO reservations (customer_id, table_id, reserv_time, guests_count) VALUES 
(1, 3, '2026-05-20 19:00:00', 4);

INSERT INTO orders (status, table_id, employee_id) VALUES 
('Open', 1, 2);

INSERT INTO order_details (quantity, price_at_sale, order_id, item_id) VALUES 
(2, 25.99, 1, 1), 
(1, 4.50, 1, 2);

INSERT INTO payments (total_sum, method, order_id) VALUES 
(56.48, 'Card', 1);