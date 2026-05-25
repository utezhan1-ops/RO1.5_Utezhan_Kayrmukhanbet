-- Assignment 3: DCL and DML
-- Database domain: restaurant service
-- PostgreSQL script for pgAdmin Query Tool / plain PostgreSQL SQL.

set search_path to public;

-- Top cleanup for re-running the script.
drop schema if exists restaurant_service cascade;
drop user if exists db_admin_user;
drop user if exists db_reader_user;
drop role if exists restaurant_service_admin;
drop role if exists restaurant_service_readonly;

create schema restaurant_service;

set search_path to restaurant_service, public;

create table employee_roles (
    role_id serial primary key,
    role_name varchar(50) not null unique,
    salary_rate numeric(10, 2) not null check (salary_rate > 0)
);

create table menu_categories (
    category_id serial primary key,
    category_name varchar(50) not null unique
);

create table inventory (
    ingredient_id serial primary key,
    name varchar(100) not null unique,
    balance numeric(10, 2) not null default 0.00 check (balance >= 0),
    unit varchar(10) not null
);

create table employees (
    employee_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    phone_number varchar(20) not null unique,
    role_id integer not null references employee_roles(role_id) on delete restrict
);

create table customers (
    customer_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    email_address varchar(100) not null unique
);

create table dining_tables (
    table_id serial primary key,
    table_num integer not null unique check (table_num > 0),
    capacity integer not null check (capacity > 0),
    status varchar(20) not null default 'Available'
        check (status in ('Available', 'Occupied', 'Reserved'))
);

create table menu_items (
    item_id serial primary key,
    name varchar(100) not null unique,
    current_price numeric(10, 2) not null check (current_price > 0),
    category_id integer not null references menu_categories(category_id) on delete restrict
);

create table recipe_items (
    recipe_id serial primary key,
    weight numeric(6, 3) not null check (weight > 0),
    ingredient_id integer not null references inventory(ingredient_id) on delete cascade,
    item_id integer not null references menu_items(item_id) on delete cascade
);

create table reservations (
    reservation_id serial primary key,
    customer_id integer not null references customers(customer_id) on delete cascade,
    table_id integer not null references dining_tables(table_id) on delete cascade,
    reserv_time timestamp not null,
    guests_count integer not null check (guests_count > 0)
);

create table orders (
    order_id serial primary key,
    open_time timestamp not null default current_timestamp,
    status varchar(20) not null default 'Open'
        check (status in ('Open', 'Closed', 'Cancelled')),
    table_id integer not null references dining_tables(table_id) on delete restrict,
    employee_id integer not null references employees(employee_id) on delete restrict
);

create table order_details (
    detail_id serial primary key,
    quantity integer not null check (quantity > 0),
    price_at_sale numeric(10, 2) not null check (price_at_sale > 0),
    order_id integer not null references orders(order_id) on delete cascade,
    item_id integer not null references menu_items(item_id) on delete restrict
);

create table payments (
    payment_id serial primary key,
    total_sum numeric(10, 2) not null check (total_sum >= 0),
    method varchar(20) not null check (method in ('Cash', 'Card')),
    pay_time timestamp not null default current_timestamp,
    order_id integer not null unique references orders(order_id) on delete cascade
);

create role restaurant_service_admin;
create role restaurant_service_readonly;

grant usage on schema public to restaurant_service_admin;
grant usage on schema public to restaurant_service_readonly;
grant usage on schema restaurant_service to restaurant_service_admin;
grant usage on schema restaurant_service to restaurant_service_readonly;

grant select, insert, update, delete
on all tables in schema restaurant_service
to restaurant_service_admin;

grant select
on all tables in schema restaurant_service
to restaurant_service_readonly;

grant usage, select
on all sequences in schema restaurant_service
to restaurant_service_admin;

create user db_admin_user with password 'admin_secure_pass_2026';
grant restaurant_service_admin to db_admin_user;

create user db_reader_user with password 'reader_secure_pass_2026';
grant restaurant_service_readonly to db_reader_user;

revoke update, delete
on all tables in schema restaurant_service
from restaurant_service_readonly;

-- \dp restaurant_service.orders
--                                                   Access privileges
--       Schema       |  Name  | Type  |          Access privileges           | Column privileges | Policies
-- ------------------+--------+-------+--------------------------------------+-------------------+----------
-- restaurant_service | orders | table | postgres=arwdDxt/postgres          +|                   |
--                    |        |       | restaurant_service_admin=arwd/postgres+|                   |
--                    |        |       | restaurant_service_readonly=r/postgres |                   |

-- Truncate in FK order before inserting seed data.
truncate table
    payments,
    order_details,
    reservations,
    recipe_items,
    orders,
    employees,
    menu_items,
    dining_tables,
    customers,
    inventory,
    menu_categories,
    employee_roles
restart identity;

insert into employee_roles (role_name, salary_rate) values
    ('Manager', 3500.00),
    ('Head Chef', 4000.00),
    ('Sous Chef', 2800.00),
    ('Senior Waiter', 1800.00),
    ('Bartender', 2000.00);

insert into menu_categories (category_name) values
    ('Appetizers'),
    ('Main Courses'),
    ('Desserts'),
    ('Alcoholic Drinks'),
    ('Soft Drinks');

insert into inventory (name, balance, unit) values
    ('Wagyu Beef Ribeye', 25.50, 'kg'),
    ('Atlantic Salmon', 18.00, 'kg'),
    ('Organic Avocados', 40.00, 'pcs'),
    ('Espresso Beans', 15.50, 'kg'),
    ('Dark Chocolate', 12.00, 'kg');

insert into employees (first_name, last_name, phone_number, role_id) values
    (
        'Alexander',
        'King',
        '+77015551122',
        (select role_id from employee_roles where role_name = 'Manager')
    ),
    (
        'Dmitry',
        'Petrov',
        '+77025553344',
        (select role_id from employee_roles where role_name = 'Head Chef')
    ),
    (
        'Svetlana',
        'Ivanova',
        '+77035555566',
        (select role_id from employee_roles where role_name = 'Senior Waiter')
    ),
    (
        'Arman',
        'Saparov',
        '+77055557788',
        (select role_id from employee_roles where role_name = 'Bartender')
    ),
    (
        'Maria',
        'Kuznetsova',
        '+77075559900',
        (select role_id from employee_roles where role_name = 'Sous Chef')
    );

insert into customers (first_name, last_name, email_address) values
    ('Askar', 'Smailov', 'askar.s@example.kz'),
    ('Elena', 'Kim', 'elena.kim@example.kz'),
    ('Rustam', 'Akhmetov', 'rustam.a@example.kz'),
    ('Aisulu', 'Omarova', 'aisulu.o@example.kz'),
    ('Murat', 'Muratov', 'murat.m@example.kz');

insert into dining_tables (table_num, capacity, status) values
    (1, 2, 'Available'),
    (2, 4, 'Occupied'),
    (3, 4, 'Available'),
    (4, 6, 'Reserved'),
    (5, 8, 'Available');

insert into menu_items (name, current_price, category_id) values
    (
        'Grilled Wagyu Steak',
        18500.00,
        (select category_id from menu_categories where category_name = 'Main Courses')
    ),
    (
        'Pan-Seared Salmon',
        12500.00,
        (select category_id from menu_categories where category_name = 'Main Courses')
    ),
    (
        'Avocado Tartare',
        4500.00,
        (select category_id from menu_categories where category_name = 'Appetizers')
    ),
    (
        'Chocolate Fondant',
        3500.00,
        (select category_id from menu_categories where category_name = 'Desserts')
    ),
    (
        'Signature Espresso',
        1500.00,
        (select category_id from menu_categories where category_name = 'Soft Drinks')
    );

insert into recipe_items (weight, ingredient_id, item_id) values
    (
        0.350,
        (select ingredient_id from inventory where name = 'Wagyu Beef Ribeye'),
        (select item_id from menu_items where name = 'Grilled Wagyu Steak')
    ),
    (
        0.250,
        (select ingredient_id from inventory where name = 'Atlantic Salmon'),
        (select item_id from menu_items where name = 'Pan-Seared Salmon')
    ),
    (
        0.150,
        (select ingredient_id from inventory where name = 'Organic Avocados'),
        (select item_id from menu_items where name = 'Avocado Tartare')
    ),
    (
        0.080,
        (select ingredient_id from inventory where name = 'Dark Chocolate'),
        (select item_id from menu_items where name = 'Chocolate Fondant')
    ),
    (
        0.020,
        (select ingredient_id from inventory where name = 'Espresso Beans'),
        (select item_id from menu_items where name = 'Signature Espresso')
    );

insert into reservations (customer_id, table_id, reserv_time, guests_count) values
    (
        (select customer_id from customers where email_address = 'askar.s@example.kz'),
        (select table_id from dining_tables where table_num = 4),
        '2026-06-01 19:00:00',
        5
    ),
    (
        (select customer_id from customers where email_address = 'elena.kim@example.kz'),
        (select table_id from dining_tables where table_num = 1),
        '2026-06-01 20:00:00',
        2
    ),
    (
        (select customer_id from customers where email_address = 'rustam.a@example.kz'),
        (select table_id from dining_tables where table_num = 3),
        '2026-06-02 18:30:00',
        4
    ),
    (
        (select customer_id from customers where email_address = 'aisulu.o@example.kz'),
        (select table_id from dining_tables where table_num = 5),
        '2026-06-02 21:00:00',
        6
    ),
    (
        (select customer_id from customers where email_address = 'murat.m@example.kz'),
        (select table_id from dining_tables where table_num = 2),
        '2026-06-03 13:00:00',
        2
    );

insert into orders (open_time, status, table_id, employee_id) values
    (
        '2026-05-25 12:00:00',
        'Closed',
        (select table_id from dining_tables where table_num = 1),
        (select employee_id from employees where phone_number = '+77035555566')
    ),
    (
        '2026-05-25 13:30:00',
        'Closed',
        (select table_id from dining_tables where table_num = 2),
        (select employee_id from employees where phone_number = '+77035555566')
    ),
    (
        '2026-05-25 18:00:00',
        'Open',
        (select table_id from dining_tables where table_num = 4),
        (select employee_id from employees where phone_number = '+77035555566')
    ),
    (
        '2026-05-25 19:15:00',
        'Cancelled',
        (select table_id from dining_tables where table_num = 3),
        (select employee_id from employees where phone_number = '+77035555566')
    ),
    (
        '2026-05-25 20:00:00',
        'Open',
        (select table_id from dining_tables where table_num = 5),
        (select employee_id from employees where phone_number = '+77035555566')
    );

insert into order_details (quantity, price_at_sale, order_id, item_id) values
    (
        1,
        18500.00,
        (select order_id from orders where open_time = '2026-05-25 12:00:00'),
        (select item_id from menu_items where name = 'Grilled Wagyu Steak')
    ),
    (
        2,
        1500.00,
        (select order_id from orders where open_time = '2026-05-25 12:00:00'),
        (select item_id from menu_items where name = 'Signature Espresso')
    ),
    (
        1,
        12500.00,
        (select order_id from orders where open_time = '2026-05-25 13:30:00'),
        (select item_id from menu_items where name = 'Pan-Seared Salmon')
    ),
    (
        1,
        4500.00,
        (select order_id from orders where open_time = '2026-05-25 18:00:00'),
        (select item_id from menu_items where name = 'Avocado Tartare')
    ),
    (
        2,
        3500.00,
        (select order_id from orders where open_time = '2026-05-25 19:15:00'),
        (select item_id from menu_items where name = 'Chocolate Fondant')
    );

insert into payments (total_sum, method, pay_time, order_id) values
    (
        21500.00,
        'Card',
        '2026-05-25 13:10:00',
        (select order_id from orders where open_time = '2026-05-25 12:00:00')
    ),
    (
        12500.00,
        'Cash',
        '2026-05-25 14:45:00',
        (select order_id from orders where open_time = '2026-05-25 13:30:00')
    ),
    (
        4500.00,
        'Card',
        '2026-05-25 19:30:00',
        (select order_id from orders where open_time = '2026-05-25 18:00:00')
    ),
    (
        0.00,
        'Cash',
        '2026-05-25 19:20:00',
        (select order_id from orders where open_time = '2026-05-25 19:15:00')
    ),
    (
        7000.00,
        'Card',
        '2026-05-25 21:15:00',
        (select order_id from orders where open_time = '2026-05-25 20:00:00')
    );

-- Business event: a regular customer changed their contact email.
select customer_id, first_name, last_name, email_address
from customers
where email_address = 'askar.s@example.kz';
-- preview row count: 1

update customers
set email_address = 'askar.smailov.new@example.kz'
where email_address = 'askar.s@example.kz';
-- update row count: 1

-- Business event: supplier cost increased, so the steak menu price was adjusted.
select item_id, name, current_price
from menu_items
where name = 'Grilled Wagyu Steak';
-- preview row count: 1

update menu_items
set current_price = 19500.00
where name = 'Grilled Wagyu Steak';
-- update row count: 1

-- Business event: desserts receive a seasonal discount based on their category.
select mi.item_id, mi.name, mi.current_price, mc.category_name
from menu_items as mi
join menu_categories as mc
    on mc.category_id = mi.category_id
where mc.category_name = 'Desserts';
-- preview row count: 1

update menu_items as mi
set current_price = mi.current_price * 0.90
from menu_categories as mc
where mc.category_id = mi.category_id
  and mc.category_name = 'Desserts';
-- update row count: 1

-- Cancelled orders are removed from operational reports because they did not
-- produce active kitchen work or completed revenue.
select order_id, open_time, status
from orders
where status = 'Cancelled';
-- delete preview row count: 1

begin;

delete from orders
where status = 'Cancelled';
-- delete row count: 1

select count(*) as remaining_cancelled_orders
from orders
where status = 'Cancelled';
-- count result inside transaction: 0

rollback;

-- ====== check db_admin_user ======
-- This verification block is commented because pgAdmin runs plain SQL and
-- should not stop the whole file if role switching is unavailable.
--
-- set role db_admin_user;
--
-- select current_user;
-- should print: db_admin_user
--
-- select count(*)
-- from restaurant_service.orders;
-- should succeed
--
-- insert into restaurant_service.orders (open_time, status, table_id, employee_id)
-- values (
--     '2026-05-25 22:30:00',
--     'Open',
--     (
--         select table_id
--         from restaurant_service.dining_tables
--         where table_num = 1
--     ),
--     (
--         select employee_id
--         from restaurant_service.employees
--         where phone_number = '+77035555566'
--     )
-- )
-- returning *;
-- should succeed
--
-- update restaurant_service.orders
-- set status = status
-- where order_id = (
--     select max(order_id)
--     from restaurant_service.orders
-- );
-- should succeed
--
-- delete from restaurant_service.orders
-- where order_id = (
--     select max(order_id)
--     from restaurant_service.orders
-- );
-- should succeed
--
-- reset role;
--
-- ====== check db_reader_user ======
-- set role db_reader_user;
--
-- select current_user;
-- should print: db_reader_user
--
-- select count(*)
-- from restaurant_service.orders;
-- should succeed
--
-- begin;
-- insert into restaurant_service.orders (open_time, status, table_id, employee_id)
-- values (
--     '2026-05-25 22:30:00',
--     'Open',
--     (
--         select table_id
--         from restaurant_service.dining_tables
--         where table_num = 1
--     ),
--     (
--         select employee_id
--         from restaurant_service.employees
--         where phone_number = '+77035555566'
--     )
-- )
-- returning *;
-- expected error:
-- ERROR:  permission denied for table orders
-- rollback;
--
-- begin;
-- update restaurant_service.orders
-- set status = status
-- where order_id = (
--     select max(order_id)
--     from restaurant_service.orders
-- );
-- expected error:
-- ERROR:  permission denied for table orders
-- rollback;
--
-- begin;
-- delete from restaurant_service.orders
-- where order_id = (
--     select max(order_id)
--     from restaurant_service.orders
-- );
-- expected error:
-- ERROR:  permission denied for table orders
-- rollback;
--
-- reset role;
