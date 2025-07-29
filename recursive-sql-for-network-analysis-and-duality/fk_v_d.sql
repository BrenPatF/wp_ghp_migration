PROMPT links_v based on fk_link
DROP VIEW links_v
/
CREATE VIEW links_v (
	link_id,
	node_id_fr,
	node_id_to
)
AS
SELECT 	con_fr,
	table_fr,
	table_to
  FROM fk_link_d
/
SELECT COUNT(*)
  FROM links_v
/
DROP VIEW nodes_v
/
CREATE VIEW nodes_v (
                node_id
) AS
SELECT node_id_fr
  FROM links_v
UNION
SELECT node_id_to
  FROM links_v
/
SELECT COUNT(*)
  FROM nodes_v
/
