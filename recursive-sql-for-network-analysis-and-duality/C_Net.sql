SPOOL ..\lst\C_Net
DROP TABLE links
/
CREATE TABLE links (id            VARCHAR2(20),
                    node_fr       VARCHAR2(20),
                    node_to       VARCHAR2(20))
/
DECLARE

  g_net_suffix VARCHAR2(20);

  PROCEDURE Ins_Val (p_node_fr VARCHAR2, p_node_to VARCHAR2) IS
  BEGIN

    INSERT INTO links VALUES ('L' || p_node_fr || p_node_to || '-' || g_net_suffix, 'N' || p_node_fr || '-' || g_net_suffix, 'N' || p_node_to || '-' || g_net_suffix);

  END Ins_Val;

BEGIN

  g_net_suffix := '1';
  Ins_Val ('1', '2');
  Ins_Val ('2', '3');

  g_net_suffix := '2';
  Ins_Val ('1', '2');
  Ins_Val ('2', '3');
  Ins_Val ('2', '4');

  g_net_suffix := '3';
  Ins_Val ('1', '2');
  Ins_Val ('2', '1');

  g_net_suffix := '4';
  Ins_Val ('1', '2');
  Ins_Val ('2', '3');
  Ins_Val ('1', '3');

  g_net_suffix := '5';
  Ins_Val ('1', '2');
  Ins_Val ('2', '2');

  g_net_suffix := '6';
  Ins_Val ('1', '2');
  Ins_Val ('2', '2');
  Ins_Val ('2', '3');
  Ins_Val ('3', '4');
  Ins_Val ('3', '5');
  Ins_Val ('4', '6');
  Ins_Val ('6', '4');
  Ins_Val ('5', '7');
  Ins_Val ('5', '8');
  Ins_Val ('7', '8');

END;
/
SELECT COUNT(*) FROM links
/
DROP TABLE links_d
/
CREATE TABLE links_d (
	id		 PRIMARY KEY,
	node_fr,
	node_to
)
AS
WITH dist_links AS (
SELECT	DISTINCT CASE WHEN lin_2.node_fr IN (lin_1.node_fr, lin_1.node_to) THEN lin_2.node_fr ELSE lin_2.node_to END link_node,
        lin_1.id node_fr_d,
	lin_2.id node_to_d
  FROM links lin_1
  JOIN links lin_2
    ON lin_2.node_fr IN (lin_1.node_fr, lin_1.node_to)
    OR lin_2.node_to IN (lin_1.node_fr, lin_1.node_to)
 WHERE lin_2.id >= lin_1.id
   AND (lin_2.id != lin_1.id OR lin_2.node_fr = lin_1.node_to)
)
SELECT Substr (link_node, 1, Length (link_node)-1) || Row_Number () OVER (PARTITION BY link_node
                            ORDER BY node_fr_d, node_to_d) || '-' || Substr (link_node, -1),
       node_fr_d,
       node_to_d
  FROM dist_links
/
SELECT COUNT(*) FROM links_d
/
DROP TABLE fk_link
/
CREATE TABLE fk_link (
	con_fr		VARCHAR2(61) PRIMARY KEY,
	table_fr	VARCHAR2(61),
	table_to	VARCHAR2(61),
        owner           VARCHAR2(30)
)
/
PROMPT INSERT INTO fk_link
INSERT INTO fk_link (
	con_fr,
	table_fr,
	table_to,
        owner
)
SELECT Lower(con_f.constraint_name) || '|' || con_f.owner,
       con_f.table_name || '|' || con_f.owner,
       con_t.table_name || '|' || con_t.owner,
       con_f.owner
  FROM all_constraints                  con_f
  JOIN all_constraints                  con_t
    ON con_t.constraint_name            = con_f.r_constraint_name
   AND con_t.owner                      = con_f.r_owner
 WHERE Substr(con_f.constraint_type, 1, 1)            = 'R'
   AND Substr(con_t.constraint_type, 1, 1)            = 'P'
   AND con_f.constraint_name NOT LIKE '%|%'
   AND con_f.table_name NOT LIKE '%|%'
   AND con_t.table_name NOT LIKE '%|%'
   AND con_f.owner IN ('HR', 'OE', 'PM')
/
SELECT COUNT(*) FROM fk_link
/
DROP TABLE fk_link_d
/
CREATE TABLE fk_link_d (
	con_fr		 PRIMARY KEY,
	table_fr,
	table_to
)
AS
WITH dist_links AS (
SELECT	DISTINCT CASE WHEN lin_2.table_fr IN (lin_1.table_fr, lin_1.table_to) THEN lin_2.table_fr ELSE lin_2.table_to END link_node,
        lin_1.con_fr table_fr_d,
	lin_2.con_fr table_to_d
  FROM fk_link lin_1
  JOIN fk_link lin_2
    ON lin_2.table_fr IN (lin_1.table_fr, lin_1.table_to)
    OR lin_2.table_to IN (lin_1.table_fr, lin_1.table_to)
 WHERE lin_2.con_fr >= lin_1.con_fr
   AND (lin_2.con_fr != lin_1.con_fr OR lin_2.table_fr = lin_1.table_to)
)
SELECT link_node || '-' || Row_Number () OVER (PARTITION BY link_node
                            ORDER BY table_fr_d, table_to_d),
       table_fr_d,
       table_to_d
  FROM dist_links
/
SELECT COUNT(*) FROM fk_link_d
/
BEGIN
    DBMS_Stats.Gather_Table_Stats (
                ownname                 => 'NETWORK',
                tabname                 => 'LINKS');
END;
/
BEGIN
    DBMS_Stats.Gather_Table_Stats (
                ownname                 => 'NETWORK',
                tabname                 => 'FK_LINK');
END;
/
BEGIN
    DBMS_Stats.Gather_Table_Stats (
                ownname                 => 'NETWORK',
                tabname                 => 'FK_LINK_D');
END;
/
SPOOL OFF
