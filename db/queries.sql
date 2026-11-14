-- ============================================================================
-- queries.sql — SQL-запросы приложения «магазин обуви» (БД shoe_store)
-- Знак ? — параметр, который C#-код подставляет из формы (MySqlCommand.Parameters).
-- Перед запуском: USE shoe_store;
-- ============================================================================
USE shoe_store;

-- ---------------------------------------------------------------------------
-- 1. Вход в приложение (пункты чек-листа 2.5, 2.6, 3.17)
--    Одна строка — вход выполнен (ФИО и роль для окна после входа);
--    пустой результат — «неправильный логин/пароль».
-- ---------------------------------------------------------------------------
SELECT u.id, u.full_name, r.name AS role
FROM users u
JOIN roles r ON r.id = u.role_id
WHERE u.login = ? AND u.password = ?;

-- ---------------------------------------------------------------------------
-- 2. Каталог товаров (пункты 2.7–2.11): одни и те же карточки для Гостя и
--    Администратора; JOIN подтягивает названия вместо category_id и т. д.
-- ---------------------------------------------------------------------------
SELECT p.id, p.article, p.name, p.unit, p.price, p.discount, p.stock_qty,
       p.description, p.photo,
       c.name AS category, m.name AS manufacturer, s.name AS supplier
FROM products p
JOIN categories c ON c.id = p.category_id
JOIN manufacturers m ON m.id = p.manufacturer_id
JOIN suppliers s ON s.id = p.supplier_id;

-- ---------------------------------------------------------------------------
-- 3. Поиск + фильтр по поставщику + сортировка по остатку (пункты 3.2–3.6)
--    Один запрос с разным набором условий в WHERE. Необязательные условия:
--    передайте NULL, если поиск/фильтр не задан (поиск '' тоже работает —
--    LIKE '%%' находит всё).
--    Сортировка: остаток по возрастанию (3.2) — замените DESC на ASC (3.3).
-- ---------------------------------------------------------------------------
SELECT p.id, p.article, p.name, p.unit, p.price, p.discount, p.stock_qty,
       p.description, p.photo,
       c.name AS category, m.name AS manufacturer, s.name AS supplier
FROM products p
JOIN categories c ON c.id = p.category_id
JOIN manufacturers m ON m.id = p.manufacturer_id
JOIN suppliers s ON s.id = p.supplier_id
WHERE p.name LIKE CONCAT('%', ?, '%')          -- поиск по названию (3.4)
  AND (? IS NULL OR p.supplier_id = ?)         -- фильтр по поставщику (3.5); параметр передаётся дважды
ORDER BY p.stock_qty DESC;

-- Вариант: только поиск по названию, без фильтра и сортировки
-- SELECT ... FROM products p ... WHERE p.name LIKE CONCAT('%', ?, '%');
-- Вариант: только фильтр по поставщику
-- SELECT ... FROM products p ... WHERE p.supplier_id = ?;
-- Вариант: только сортировка по остатку
-- SELECT ... FROM products p ... ORDER BY p.stock_qty ASC;   -- или DESC

-- ---------------------------------------------------------------------------
-- 4. Добавление и редактирование товара (пункты 3.7, 3.10, 3.12, 3.19)
-- ---------------------------------------------------------------------------
-- справочники для выпадающих списков в форме
SELECT id, name FROM categories;
SELECT id, name FROM manufacturers;
SELECT id, name FROM suppliers;

-- добавление товара
INSERT INTO products
  (article, name, unit, price, discount, stock_qty, description, photo, category_id, manufacturer_id, supplier_id)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- открыть товар для редактирования — заполнить все поля формы сразу
SELECT * FROM products WHERE id = ?;

-- сохранить изменения
UPDATE products
SET article=?, name=?, unit=?, price=?, discount=?, stock_qty=?, description=?, photo=?,
    category_id=?, manufacturer_id=?, supplier_id=?
WHERE id = ?;

-- ---------------------------------------------------------------------------
-- 5. Удаление товара (пункт 3.16): нельзя удалить товар, который уже покупали
-- ---------------------------------------------------------------------------
-- сначала проверка: если результат > 0 — показать пользователю предупреждение
SELECT COUNT(*) AS used_in_orders FROM prodorders WHERE product_id = ?;

-- удаление; если товар есть в заказах, СУБД откажет (Error 1451: Cannot delete or
-- update a parent row: a foreign key constraint fails) — связь без CASCADE
DELETE FROM products WHERE id = ?;
