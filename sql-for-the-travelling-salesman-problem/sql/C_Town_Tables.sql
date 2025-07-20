SPOOL ..\lst\C_Town_Tables
CREATE OR REPLACE DIRECTORY brendan_in_dir AS 'C:\Users\Brendan\Documents\Home - X300\SQL\Input';
DROP TABLE towns_ext
/
CREATE TABLE towns_ext (
        name           VARCHAR2(30)
)
ORGANIZATION EXTERNAL (
	TYPE			oracle_loader
	DEFAULT DIRECTORY	brendan_in_dir
	ACCESS PARAMETERS
	(
              RECORDS DELIMITED BY NEWLINE SKIP 1
		FIELDS TERMINATED BY '\t'
		MISSING FIELD VALUES ARE NULL
	)
	LOCATION ('usca312_name_data.txt')
)
/
DROP TABLE xy_ext
/
CREATE TABLE xy_ext (
        x           NUMBER,
        y           NUMBER
)
ORGANIZATION EXTERNAL (
	TYPE			oracle_loader
	DEFAULT DIRECTORY	brendan_in_dir
	ACCESS PARAMETERS
	(
              RECORDS DELIMITED BY NEWLINE SKIP 1
		FIELDS TERMINATED BY '\t'
		MISSING FIELD VALUES ARE NULL
	)
	LOCATION ('usca312_xy_data.txt')
)
/
DROP SEQUENCE towns_s
/
CREATE SEQUENCE towns_s START WITH 1
/
DROP TABLE distances 
/
DROP TABLE towns
/
CREATE TABLE towns (
       id            INTEGER PRIMARY KEY,
       name          VARCHAR2(30),
       x             NUMBER,
       y             NUMBER
)
/
DROP TABLE xy
/
CREATE TABLE xy (
       id            INTEGER PRIMARY KEY,
       x             NUMBER,
       y             NUMBER
)
/
CREATE TABLE distances (
       id     INTEGER PRIMARY KEY,
       a      INTEGER,
       b      INTEGER,
       dst    NUMBER,
       CONSTRAINT distance_pk UNIQUE (a, b),
       CONSTRAINT dst_twn_a_fk FOREIGN KEY (a) REFERENCES towns (id),
       CONSTRAINT dst_twn_b_fk FOREIGN KEY (b) REFERENCES towns (id)
)
/
DROP VIEW items
/
CREATE VIEW items (
	id,
	name,
	cat_id,
       profit,
       price
) AS 
SELECT id,
	a || '-' || b,
	To_Char (a),
       -dst,
       0
  FROM distances
/
DROP TABLE categories_town
/
CREATE TABLE categories_town (
	id		VARCHAR2(3) PRIMARY KEY,
	min_items	INTEGER,
	max_items	INTEGER
)
/
DROP VIEW categories
/
CREATE VIEW categories (
	id,
	min_items,
	max_items
) AS
SELECT id,
	min_items,
	max_items
  FROM categories_town
/
SPOOL OFF
