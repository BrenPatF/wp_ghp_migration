SET TRIMSPOOL ON
SET PAGES 10000
SET lines 1000
SET SERVEROUTPUT ON
SPOOL ..\lst\Pop_Town_5
DELETE distances
/
DELETE xy
/
DELETE towns
/
DELETE categories_town
/
DECLARE
  g_i INTEGER := 0;
  PROCEDURE Ins_Town (p_name VARCHAR2, p_x NUMBER, p_y NUMBER) IS
  BEGIN

    g_i := g_i + 1;
    INSERT INTO towns VALUES (g_i, p_name, p_x, p_y);

  END Ins_Town;
BEGIN

  Ins_Town ('Left Floor', 0, 0);
  Ins_Town ('Left Peak', 1, 2);
  Ins_Town ('Midfield', 2, 1);
  Ins_Town ('Right Peak', 3, 2);
  Ins_Town ('Right Floor', 4, 0);

END;
/
INSERT INTO distances
WITH dist AS (
SELECT a.id a, b.id b, 
       SQRT ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)) dst
  FROM towns a
  JOIN towns b
    ON b.id > a.id
), uni AS (
SELECT a, b, dst
  FROM dist
 UNION ALL
SELECT b, a, dst
  FROM dist
), pks AS (
SELECT a, b, dst, Row_Number() OVER (ORDER BY a, b) id
  FROM uni
)
SELECT id, a, b, dst
  FROM pks
/
INSERT INTO categories_town
SELECT To_Char (id), 1, 1
  FROM towns
 UNION
SELECT 'ALL', COUNT(*), COUNT(*)
  FROM towns
/
COLUMN name FORMAT A10
COLUMN cat_id FORMAT A10
COLUMN a FORMAT 990
COLUMN b FORMAT 990
PROMPT Towns
SELECT id, name, x, y
  FROM towns
   ORDER BY 1
/
PROMPT Distances
BREAK ON a ON name_a
SELECT d.a, t_a.name name_a, d.b, t_b.name name_b, d.dst
  FROM distances d
  JOIN towns t_a
    ON t_a.id = d.a
  JOIN towns t_b
    ON t_b.id = d.b
 ORDER BY 1, 3
/
PROMPT Items
SELECT id,
	name,
	cat_id
  FROM items
 ORDER BY 1
/
PROMPT Categories
SELECT id,
	min_items,
	max_items
  FROM categories
 ORDER BY 1
/
SPOOL OFF
