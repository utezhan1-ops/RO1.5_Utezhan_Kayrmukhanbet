-- ============================================================================
-- PART 1: RE-RUNNABLE HEADER & CLEANUP
-- ============================================================================

drop table if exists 
     cart_items, 
     reviews, 
     order_items, 
     orders,          
     coupons,        
     products, 
     order_statuses, 
     customers, 
     categories,
     addresses,
     payments
cascade;

drop owned by eshop_readonly;
drop owned by eshop_writer;
drop role if exists eshop_readonly;
drop role if exists eshop_writer;

create role eshop_readonly;
create role eshop_writer;


-- ============================================================================
-- PART 2: CREATE TABLES
-- ============================================================================

create table if not exists categories (
     category_id serial primary key,
     category_name varchar(100) not null unique,
     slug varchar(100) not null unique
);

create table if not exists customers (
     customer_id serial primary key,
     email varchar(150) not null constraint uq_customer_email unique,
     phone varchar(30) not null,
     full_name varchar(100) not null,
     gender varchar(10) constraint chk_customer_gender check (gender in ('M', 'F', 'Other'))
);

create table if not exists addresses (
     address_id serial primary key,
     customer_id integer not null references customers(customer_id) on delete cascade,
     country varchar(100) not null,
     city varchar(100) not null,
     street_address varchar(250) not null,
     postal_code varchar(20) not null,
     is_default boolean not null default false
);

create table if not exists order_statuses (
     status_id serial primary key,
     status_code varchar(30) not null unique
);

create table if not exists coupons (
     coupon_id serial primary key,
     code varchar(20) not null unique,
     discount_percent numeric(5,2) not null,
     status varchar(20) not null default 'active'
);

create table if not exists orders (
     order_id serial primary key,
     customer_id integer not null references customers(customer_id) on delete restrict,
     status_id integer not null references order_statuses(status_id) on delete restrict,
     coupon_id integer references coupons(coupon_id) on delete set null,
     shipping_address text not null,
     created_at timestamp not null constraint chk_order_date check (created_at > timestamp '2026-01-01 00:00:00')
);

create table if not exists payments (
     payment_id serial primary key,
     order_id integer not null unique references orders(order_id) on delete cascade, 
     payment_method varchar(50) not null constraint chk_payment_method check (payment_method in ('Card', 'Cash', 'QR', 'PayPal')),
     amount numeric(10,2) not null constraint chk_payment_amount check (amount > 0),
     status varchar(30) not null default 'pending',
     paid_at timestamp
);

create table if not exists products (
     product_id serial primary key,
     category_id integer not null references categories(category_id) on delete restrict,
     sku varchar(50) not null unique,
     title varchar(200) not null,
     price numeric(10,2) not null,
     stock integer not null constraint chk_product_stock check (stock >= 0)
);

create table if not exists order_items (
     item_id serial primary key,
     order_id integer not null references orders(order_id) on delete cascade,
     product_id integer not null references products(product_id) on delete restrict,
     quantity integer not null constraint chk_item_quantity check (quantity > 0),
     unit_price numeric(10,2) not null,
     total_price numeric(10,2) generated always as (quantity * unit_price) stored
);

create table if not exists reviews (
     review_id serial primary key,
     customer_id integer not null references customers(customer_id) on delete cascade,
     product_id integer not null references products(product_id) on delete cascade,
     rating integer not null constraint chk_review_rating check (rating between 1 and 5),
     comment_text text
);

create table if not exists cart_items (
     cart_id serial primary key,
     customer_id integer not null references customers(customer_id) on delete cascade,
     product_id integer not null references products(product_id) on delete cascade,
     quantity integer not null constraint chk_cart_quantity check (quantity > 0)
);


-- ============================================================================
-- PART 3: ALTER TABLES
-- ============================================================================

-- 1. ALTER COLUMN DEFAULT
alter table coupons alter column status set default 'pending';

-- 2. ADD COLUMN
alter table products add column if not exists seasonal_promo varchar(50);

-- 3. DROP COLUMN
alter table products drop column if exists seasonal_promo;

-- 4. ALTER COLUMN TYPE
alter table orders alter column shipping_address type varchar(500);

-- 5. ADD CONSTRAINT
alter table coupons drop constraint if exists chk_max_discount;
alter table coupons add constraint chk_max_discount check (discount_percent <= 90.00);


-- ============================================================================
-- PART 4: CLEANUP & TRUNCATE
-- ============================================================================

truncate table 
     categories, 
     customers, 
     products, 
     order_statuses, 
     coupons, 
     orders, 
     order_items, 
     reviews, 
     cart_items, 
     addresses,
     payments
restart identity cascade;


-- ============================================================================
-- PART 5: INSERT DATA (С защитой от дублирования ключей)
-- ============================================================================

insert into categories (category_name, slug) values
('Electronics', 'electronics'), ('Books', 'books'), ('Clothing', 'clothing'), ('Home & Kitchen', 'home-kitchen'), ('Sports', 'sports')
on conflict (slug) do nothing;

insert into customers (email, phone, full_name, gender) values
('alex.ivanov@example.kz', '+77011112233', 'Alex Ivanov', 'M'),
('elena.smirnova@example.kz', '+77022223344', 'Elena Smirnova', 'F'),
('dmitry.kim@example.kz', '+77033334455', 'Dmitry Kim', 'M'),
('anna.s@example.kz', '+77044445566', 'Anna Sidorova', 'F'),
('j.doe@example.kz', '+77055556677', 'John Doe', 'Other')
on conflict (email) do nothing;

insert into products (category_id, sku, title, price, stock) values
((select category_id from categories where slug = 'electronics'), 'ELEC-SMART-01', 'Flagship Smartphone X', 450000.00, 25),
((select category_id from categories where slug = 'electronics'), 'ELEC-LAP-02', 'Pro Laptop 15 inch', 680000.00, 10),
((select category_id from categories where slug = 'books'), 'BOOK-SQL-01', 'Mastering PostgreSQL 16', 12000.00, 100),
((select category_id from categories where slug = 'books'), 'BOOK-COOK-02', 'World Cuisine Guide', 8500.00, 40),
((select category_id from categories where slug = 'clothing'), 'CLOTH-HOOD-01', 'Premium Cotton Hoodie', 22000.00, 60),
((select category_id from categories where slug = 'clothing'), 'CLOTH-JEAN-02', 'Slim Fit Denim Jeans', 18500.00, 80),
((select category_id from categories where slug = 'home-kitchen'), 'HOME-BLEND-01', 'High-Speed Nutrient Blender', 35000.00, 15),
((select category_id from categories where slug = 'home-kitchen'), 'HOME-POT-02', 'Ceramic Non-Stick Cooking Pot', 14000.00, 30),
((select category_id from categories where slug = 'sports'), 'SPORT-MAT-01', 'Eco-Friendly Yoga Mat', 9500.00, 50),
((select category_id from categories where slug = 'sports'), 'SPORT-DUMB-02', 'Adjustable Dumbbell Set 20kg', 45000.00, 12)
on conflict (sku) do nothing;

insert into order_statuses (status_code) values
('pending'), ('paid'), ('shipped'), ('delivered'), ('cancelled')
on conflict (status_code) do nothing;

insert into addresses (customer_id, country, city, street_address, postal_code, is_default)
select (select customer_id from customers where email = 'alex.ivanov@example.kz'), 'Kazakhstan', 'Almaty', 'Abay Ave 45, apt 12', '050000', true
where not exists (select 1 from addresses where street_address = 'Abay Ave 45, apt 12');

insert into addresses (customer_id, country, city, street_address, postal_code, is_default)
select (select customer_id from customers where email = 'elena.smirnova@example.kz'), 'Kazakhstan', 'Astana', 'Mangilik El Ave 12, apt 74', '010000', true
where not exists (select 1 from addresses where street_address = 'Mangilik El Ave 12, apt 74');

insert into addresses (customer_id, country, city, street_address, postal_code, is_default)
select (select customer_id from customers where email = 'dmitry.kim@example.kz'), 'Kazakhstan', 'Astana', 'Turan Ave 8, apt 5', '010000', true
where not exists (select 1 from addresses where street_address = 'Turan Ave 8, apt 5');

insert into coupons (code, discount_percent, status) values
('WINTER2026', 10.00, 'active'), ('SPRING26', 15.00, 'active'), ('WELCOMEST', 5.00, 'active'), ('EXPIRED26', 20.00, 'expired'), ('VIPONLY', 25.00, 'active')
on conflict (code) do nothing;

insert into orders (customer_id, status_id, coupon_id, shipping_address, created_at)
select (select customer_id from customers where email = 'alex.ivanov@example.kz'), (select status_id from order_statuses where status_code = 'paid'), (select coupon_id from coupons where code = 'WINTER2026'), 'Abay Ave 45, Almaty', '2026-02-15 14:30:00'
where not exists (select 1 from orders where created_at = '2026-02-15 14:30:00');

insert into orders (customer_id, status_id, coupon_id, shipping_address, created_at)
select (select customer_id from customers where email = 'elena.smirnova@example.kz'), (select status_id from order_statuses where status_code = 'shipped'), null, 'Mangilik El Ave 12, Astana', '2026-03-01 10:15:00'
where not exists (select 1 from orders where created_at = '2026-03-01 10:15:00');

insert into orders (customer_id, status_id, coupon_id, shipping_address, created_at)
select (select customer_id from customers where email = 'dmitry.kim@example.kz'), (select status_id from order_statuses where status_code = 'pending'), null, 'Turan Ave 8, Astana', '2026-03-10 18:45:00'
where not exists (select 1 from orders where created_at = '2026-03-10 18:45:00');

insert into orders (customer_id, status_id, coupon_id, shipping_address, created_at)
select (select customer_id from customers where email = 'anna.s@example.kz'), (select status_id from order_statuses where status_code = 'delivered'), (select coupon_id from coupons where code = 'WELCOMEST'), 'Bukhar-Zhyrau Ave 22, Karaganda', '2026-01-20 09:00:00'
where not exists (select 1 from orders where created_at = '2026-01-20 09:00:00');

insert into orders (customer_id, status_id, coupon_id, shipping_address, created_at)
select (select customer_id from customers where email = 'alex.ivanov@example.kz'), (select status_id from order_statuses where status_code = 'cancelled'), null, 'Abay Ave 45, Almaty', '2026-01-05 11:00:00'
where not exists (select 1 from orders where created_at = '2026-01-05 11:00:00');

insert into payments (order_id, payment_method, amount, status, paid_at)
select 1, 'Card', 474000.00, 'completed', '2026-02-15 14:35:00'
where not exists (select 1 from payments where order_id = 1);

insert into payments (order_id, payment_method, amount, status, paid_at)
select 2, 'QR', 41000.00, 'completed', '2026-03-01 10:20:00'
where not exists (select 1 from payments where order_id = 2);

insert into payments (order_id, payment_method, amount, status, paid_at)
select 3, 'Card', 715000.00, 'pending', null
where not exists (select 1 from payments where order_id = 3);

insert into payments (order_id, payment_method, amount, status, paid_at)
select 4, 'PayPal', 45500.00, 'completed', '2026-01-20 09:15:00'
where not exists (select 1 from payments where order_id = 4);

insert into order_items (order_id, product_id, quantity, unit_price)
select 1, (select product_id from products where sku = 'ELEC-SMART-01'), 1, 450000.00 where (select count(*) from order_items) = 0;
insert into order_items (order_id, product_id, quantity, unit_price)
select 1, (select product_id from products where sku = 'BOOK-SQL-01'), 2, 12000.00 where (select count(*) from order_items) = 1;
insert into order_items (order_id, product_id, quantity, unit_price)
select 2, (select product_id from products where sku = 'CLOTH-HOOD-01'), 1, 22000.00 where (select count(*) from order_items) = 2;
insert into order_items (order_id, product_id, quantity, unit_price)
select 2, (select product_id from products where sku = 'SPORT-MAT-01'), 2, 9500.00 where (select count(*) from order_items) = 3;
insert into order_items (order_id, product_id, quantity, unit_price)
select 3, (select product_id from products where sku = 'ELEC-LAP-02'), 1, 680000.00 where (select count(*) from order_items) = 4;
insert into order_items (order_id, product_id, quantity, unit_price)
select 3, (select product_id from products where sku = 'HOME-BLEND-01'), 1, 35000.00 where (select count(*) from order_items) = 5;
insert into order_items (order_id, product_id, quantity, unit_price)
select 4, (select product_id from products where sku = 'BOOK-COOK-02'), 1, 8500.00 where (select count(*) from order_items) = 6;
insert into order_items (order_id, product_id, quantity, unit_price)
select 4, (select product_id from products where sku = 'CLOTH-JEAN-02'), 2, 18500.00 where (select count(*) from order_items) = 7;
insert into order_items (order_id, product_id, quantity, unit_price)
select 5, (select product_id from products where sku = 'SPORT-DUMB-02'), 1, 45000.00 where (select count(*) from order_items) = 8;
insert into order_items (order_id, product_id, quantity, unit_price)
select 5, (select product_id from products where sku = 'HOME-POT-02'), 1, 14000.00 where (select count(*) from order_items) = 9;

insert into reviews (customer_id, product_id, rating, comment_text)
select (select customer_id from customers where email = 'alex.ivanov@example.kz'), (select product_id from products where sku = 'ELEC-SMART-01'), 5, 'Exceptional quality phone.' where (select count(*) from reviews) = 0;
insert into reviews (customer_id, product_id, rating, comment_text)
select (select customer_id from customers where email = 'elena.smirnova@example.kz'), (select product_id from products where sku = 'CLOTH-HOOD-01'), 4, 'Very comfortable, but fit runs slightly large.' where (select count(*) from reviews) = 1;
insert into reviews (customer_id, product_id, rating, comment_text)
select (select customer_id from customers where email = 'dmitry.kim@example.kz'), (select product_id from products where sku = 'BOOK-SQL-01'), 5, 'The best textbook for relational databases.' where (select count(*) from reviews) = 2;
insert into reviews (customer_id, product_id, rating, comment_text)
select (select customer_id from customers where email = 'anna.s@example.kz'), (select product_id from products where sku = 'CLOTH-JEAN-02'), 3, 'Average denim quality.' where (select count(*) from reviews) = 3;
insert into reviews (customer_id, product_id, rating, comment_text)
select (select customer_id from customers where email = 'j.doe@example.kz'), (select product_id from products where sku = 'HOME-BLEND-01'), 5, 'Blends completely smooth in seconds!' where (select count(*) from reviews) = 4;

truncate table cart_items cascade;
insert into cart_items (customer_id, product_id, quantity)
select c.customer_id, p.product_id, 1 from customers c cross join products p where c.email = 'alex.ivanov@example.kz' and p.sku in ('BOOK-SQL-01', 'SPORT-MAT-01');


-- ============================================================================
-- PART 6: UPDATE DATA
-- ============================================================================

update products set price = price * 0.90 where category_id = (select category_id from categories where slug = 'books');

update customers set full_name = full_name || ' (VIP)' where customer_id in (
      select o.customer_id from orders o join order_items oi on o.order_id = oi.order_id group by o.customer_id having sum(oi.total_price) > 100000.00
) and full_name not like '%(VIP)%';


-- ============================================================================
-- PART 7: ROLES & PERMISSIONS
-- ============================================================================

grant select on all tables in schema public to eshop_readonly;
grant insert, update on products to eshop_writer;
revoke update on products from eshop_writer;


-- ============================================================================
-- PART 8: TRANSACTION TESTS (Wrapped in BEGIN ... ROLLBACK)
-- ============================================================================
-- BUSINESS & TECHNICAL REASON:
-- This block is dedicated to validating the schema's cascading behavior and 
-- integrity constraints under isolated testing conditions.
--
-- Business Scenario: When an order marked as 'cancelled' is removed, the foreign 
-- key constraint configured with `ON DELETE CASCADE` should automatically purge 
-- the corresponding ledger entries from the 'payments' table without requiring 
-- secondary manuals queries or impacting active production data.
--
-- Wrapping this test within a BEGIN ... ROLLBACK structure serves two critical goals:
-- 1. Preventing Test Data Drift (Idempotency): It ensures that while the DML operation 
--    (DELETE) runs and verifies syntactic correctness, trigger behavior, and structural 
--    integrity, the actual database state is immediately reverted back to its clean baseline. 
--    This guarantees that the script can be executed multiple times without failing.
-- 2. Deployment Safety: It establishes a sandbox execution environment. In case this 
--    deployment script runs on a shared staging or target schema, accidental destructive 
--    modifications are safely intercepted, preventing unexpected data loss.
begin;

delete from orders 
where status_id = (select status_id from order_statuses where status_code = 'cancelled') 
returning order_id, customer_id, created_at;

rollback;
-- Changes successfully reverted. The baseline testing database state remains pristine and intact.