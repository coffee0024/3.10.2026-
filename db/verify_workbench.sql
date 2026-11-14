-- Проверка учебной базы shoe_store в MySQL Workbench (MySQL 8.0+)
-- Сначала выполните db/create_v1.sql и db/data.sql в НОВОЙ пустой схеме.
-- Этот файл выполняется отдельно. Тестовые изменения откатываются ROLLBACK.
USE shoe_store;

-- 1. Список таблиц: ожидается 10.
SELECT TABLE_NAME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'shoe_store' AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

SELECT COUNT(*) AS tables_found, 10 AS tables_expected
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'shoe_store' AND TABLE_TYPE = 'BASE TABLE';

-- 2. Число строк по каждой таблице и общий итог: 121.
SELECT 'categories' AS table_name, COUNT(*) AS actual, 2 AS expected FROM categories
UNION ALL SELECT 'manufacturers', COUNT(*), 6 FROM manufacturers
UNION ALL SELECT 'suppliers', COUNT(*), 2 FROM suppliers
UNION ALL SELECT 'roles', COUNT(*), 3 FROM roles
UNION ALL SELECT 'orderstatus', COUNT(*), 2 FROM orderstatus
UNION ALL SELECT 'users', COUNT(*), 10 FROM users
UNION ALL SELECT 'pvz', COUNT(*), 36 FROM pvz
UNION ALL SELECT 'products', COUNT(*), 30 FROM products
UNION ALL SELECT 'orders', COUNT(*), 10 FROM orders
UNION ALL SELECT 'prodorders', COUNT(*), 20 FROM prodorders;

SELECT
 (SELECT COUNT(*) FROM categories) +
 (SELECT COUNT(*) FROM manufacturers) +
 (SELECT COUNT(*) FROM suppliers) +
 (SELECT COUNT(*) FROM roles) +
 (SELECT COUNT(*) FROM orderstatus) +
 (SELECT COUNT(*) FROM users) +
 (SELECT COUNT(*) FROM pvz) +
 (SELECT COUNT(*) FROM products) +
 (SELECT COUNT(*) FROM orders) +
 (SELECT COUNT(*) FROM prodorders) AS total_rows,
 121 AS expected_rows;

-- 3. Проверка количества внешних ключей: ожидается 9.
SELECT COUNT(*) AS foreign_keys_found, 9 AS foreign_keys_expected
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'shoe_store'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

-- 4. Каталог: ожидается 30 строк.
SELECT COUNT(*) AS catalog_rows
FROM products p
JOIN categories c ON c.id = p.category_id
JOIN manufacturers m ON m.id = p.manufacturer_id
JOIN suppliers s ON s.id = p.supplier_id;

-- 5. Проверка поиска и фильтра без параметров ?: пример по «Ботинки».
SELECT p.id, p.name, p.stock_qty, s.name AS supplier
FROM products p
JOIN suppliers s ON s.id = p.supplier_id
WHERE p.name LIKE CONCAT('%', 'Ботинки', '%')
  AND (1 IS NULL OR p.supplier_id = 1)
ORDER BY p.stock_qty DESC;

-- 6. Проверка авторизации: пример берётся из существующей тестовой строки.
-- Не выводим пароли в результат.
SELECT u.id, u.full_name, r.name AS role
FROM users u
JOIN roles r ON r.id = u.role_id
WHERE u.id = 1 AND u.login = (SELECT login FROM users WHERE id = 1)
  AND u.password = (SELECT password FROM users WHERE id = 1);

-- 7. Проверка запрета удаления товара, присутствующего в заказе.
-- Ожидается положительное значение для product_id=1.
SELECT COUNT(*) AS used_in_orders
FROM prodorders WHERE product_id = 1;

-- 8. Тест INSERT -> UPDATE -> DELETE в транзакции, без сохранения изменений.
START TRANSACTION;
INSERT INTO products
(article, name, unit, price, discount, stock_qty, description, photo,
 category_id, manufacturer_id, supplier_id)
VALUES
('TEST00001', 'Тестовый товар', 'шт.', 100.00, 0, 1, 'Тест', NULL, 1, 1, 1);

SET @test_product_id = LAST_INSERT_ID();
SELECT @test_product_id AS inserted_id;

UPDATE products SET price = 125.00, stock_qty = 2 WHERE id = @test_product_id;
SELECT id, article, price, stock_qty FROM products WHERE id = @test_product_id;

DELETE FROM products WHERE id = @test_product_id;
SELECT COUNT(*) AS test_product_remaining_expected_zero
FROM products WHERE id = @test_product_id;

ROLLBACK;
-- После теста в products по-прежнему должно быть 30 записей.
SELECT COUNT(*) AS products_after_test_expected_30 FROM products;
