DROP DATABASE IF EXISTS restaurant_db;
CREATE DATABASE restaurant_db;
USE restaurant_db;

-- Decimal is chosen over float for exact financial calculations without rounding errors.
CREATE TABLE EMPLOYEE_ROLES (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    Role_name VARCHAR(50) NOT NULL,
    Salary_rate DECIMAL(10, 2) NOT NULL
);

-- Unique constraint prevents duplicate phone numbers in the system.
CREATE TABLE EMPLOYEES (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    First_name VARCHAR(20) NOT NULL,
    Last_name VARCHAR(20) NOT NULL,
    Phone_number VARCHAR(15) NOT NULL UNIQUE,
    role_id INT NOT NULL,
    CONSTRAINT fk_emp_role FOREIGN KEY (role_id) REFERENCES EMPLOYEE_ROLES(role_id)
);

-- Unique constraint ensures that no two customers can have the exact same email address.
CREATE TABLE CUSTOMERS (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    First_name VARCHAR(20) NOT NULL,
    Last_name VARCHAR(20) NOT NULL,
    Email_Address VARCHAR(50) NOT NULL UNIQUE
);

-- Check constraint restricts values to a specific set (equivalent to the 'gender' requirement).
CREATE TABLE DINING_TABLES (
    table_id INT AUTO_INCREMENT PRIMARY KEY,
    table_num INT NOT NULL,
    Capacity INT NOT NULL,
    Phone_number VARCHAR(15) NOT NULL UNIQUE,
    status VARCHAR(15) DEFAULT 'Available' CONSTRAINT check_table_status CHECK (status IN ('Available', 'Occupied', 'Reserved'))
);

CREATE TABLE MENU_CATEGORIES (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    Category_name VARCHAR(20) NOT NULL
);

CREATE TABLE MENU_ITEMS (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Current_price DECIMAL(10, 2) NOT NULL,
    category_id INT NOT NULL,
    CONSTRAINT fk_menu_cat FOREIGN KEY (category_id) REFERENCES MENU_CATEGORIES(category_id)
);

-- CHECK constraint ensures that physical stock measurement cannot fall below zero.
CREATE TABLE INVENTORY (
    ingredient_id INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(20) NOT NULL,
    Balance DECIMAL(10, 2) NOT NULL CONSTRAINT check_inv_balance CHECK (Balance >= 0),
    Unit VARCHAR(20) NOT NULL
);

-- Check constraint ensures that the ingredient weight in a recipe is always a positive number.
CREATE TABLE RECIPE_ITEMS (
    recipe_id INT AUTO_INCREMENT PRIMARY KEY,
    Weight DECIMAL(10, 2) NOT NULL CONSTRAINT check_recipe_weight CHECK (Weight > 0),
    ingredient_id INT NOT NULL,
    item_id INT NOT NULL,
    CONSTRAINT fk_recipe_inv FOREIGN KEY (ingredient_id) REFERENCES INVENTORY(ingredient_id),
    CONSTRAINT fk_recipe_menu FOREIGN KEY (item_id) REFERENCES MENU_ITEMS(item_id)
);

-- Check constraint fulfills the requirement to restrict dates strictly to after January 1, 2026.
CREATE TABLE RESERVATION (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    table_id INT NOT NULL,
    Reserv_time DATETIME NOT NULL CONSTRAINT check_reserv_date CHECK (Reserv_time > '2026-01-01 00:00:00'),
    Guests_count INT NOT NULL,
    CONSTRAINT fk_res_cust FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id),
    CONSTRAINT fk_res_table FOREIGN KEY (table_id) REFERENCES DINING_TABLES(table_id)
);

CREATE TABLE ORDERS (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    Open_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(10) NOT NULL,
    table_id INT NOT NULL,
    employee_id INT NOT NULL,
    CONSTRAINT fk_ord_table FOREIGN KEY (table_id) REFERENCES DINING_TABLES(table_id),
    CONSTRAINT fk_ord_emp FOREIGN KEY (employee_id) REFERENCES EMPLOYEES(employee_id)
);

-- Generated always as creates a stored calculated column to avoid manual math on queries.
CREATE TABLE ORDER_DETAILS (
    detail_id INT AUTO_INCREMENT PRIMARY KEY,
    Quantity INT NOT NULL CONSTRAINT check_qty CHECK (Quantity > 0),
    Price_at_sale DECIMAL(10, 2) NOT NULL,
    Total_price DECIMAL(10, 2) GENERATED ALWAYS AS (Quantity * Price_at_sale) STORED,
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    CONSTRAINT fk_det_order FOREIGN KEY (order_id) REFERENCES ORDERS(order_id),
    CONSTRAINT fk_det_item FOREIGN KEY (item_id) REFERENCES MENU_ITEMS(item_id)
);

CREATE TABLE PAYMENTS (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    Total_sum DECIMAL(10, 2) NOT NULL,
    method VARCHAR(10) NOT NULL,
    Pay_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    order_id INT UNIQUE NOT NULL,
    CONSTRAINT fk_pay_order FOREIGN KEY (order_id) REFERENCES ORDERS(order_id)
);

