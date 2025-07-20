SPOOL ..\lst\Pop_Town_312
DELETE distances
/
DELETE xy
/
DELETE towns
/
DROP SEQUENCE towns_s
/
CREATE SEQUENCE towns_s START WITH 1
/
INSERT INTO towns
SELECT towns_s.NEXTVAL, name, NULL, NULL FROM towns_ext
/
DROP SEQUENCE towns_s
/
CREATE SEQUENCE towns_s START WITH 1
/
INSERT INTO xy
SELECT towns_s.NEXTVAL, x, y FROM xy_ext
/
UPDATE towns t SET (t.x, t.y) = (SELECT xy.x, xy.y FROM xy WHERE xy.id = t.id)
/
INSERT INTO distances
WITH dist AS (
SELECT a.id a, b.id b, 
       SQRT ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)) dst
  FROM xy a
  JOIN xy b
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
SPOOL OFF
