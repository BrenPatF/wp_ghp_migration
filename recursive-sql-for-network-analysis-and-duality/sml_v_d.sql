PROMPT links_v based on links
DROP VIEW links_v
/
CREATE VIEW links_v (
                link_id,
                node_id_fr,
                node_id_to
) AS
SELECT id,
       node_fr,
       node_to
  FROM links_d
/
SELECT COUNT(*)
  FROM links_v
/
PROMPT Links
SELECT link_id,
       node_id_fr,
       node_id_to
  FROM links_v
 ORDER BY 1
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
PROMPT Nodes
SELECT nod.node_id, COUNT(*) n_lin
  FROM nodes_v nod
  JOIN links_v lin
    ON (nod.node_id = lin.node_id_fr OR nod.node_id = lin.node_id_to)
 GROUP BY nod.node_id
 ORDER BY 1
/