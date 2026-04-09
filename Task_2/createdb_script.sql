CREATE TABLE IF NOT EXISTS employee_roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL,
    salary_rate DECIMAL(10, 2) NOT NULL
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

CREATE TABLE IF NOT EXISTS menu_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS menu_items (
    item_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    current_price DECIMAL(10, 2) NOT NULL,
    category_id INT NOT NULL,
    CONSTRAINT fk_menu_cat FOREIGN KEY (category_id) REFERENCES menu_categories(category_id)
);

CREATE TABLE IF NOT EXISTS inventory (
    ingredient_id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    balance DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    CONSTRAINT check_inv_balance CHECK (balance >= 0)
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