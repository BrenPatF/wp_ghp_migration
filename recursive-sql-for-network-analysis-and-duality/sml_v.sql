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
  FROM links
/
SELECT COUNT(*)
  FROM links_v
/
DROP VIEW nodes_v 
/ 
CREATE VIEW nodes_v (
                node_id
) AS 
SELECT node_fr
  FROM links
UNION
SELECT node_to
  FROM links
/
SELECT COUNT(*)
  FROM nodes_v
/
