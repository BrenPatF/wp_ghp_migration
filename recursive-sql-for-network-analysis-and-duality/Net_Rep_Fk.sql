PROMPT Network detail
SELECT root_node_id             "Network",
       Count (DISTINCT link_id) OVER (PARTITION BY root_node_id) - 1 "#Links",
       Count (DISTINCT node_id) OVER (PARTITION BY root_node_id) "#Nodes",
       LPad (dirn || ' ', 2*node_level, ' ') || node_id || loop_flag "Node",
       link_id                  "Link",
       node_level               "Lev"
  FROM TABLE (Net_Pipe.All_Nets)
 ORDER BY line_no -- Analytic screwed ordering
/
PROMPT Network summary
SELECT root_node_id             "Network",
       Count (DISTINCT link_id) "#Links",
       Count (DISTINCT node_id) "#Nodes",
       Max (node_level) "Max Lev"
  FROM TABLE (Net_Pipe.All_Nets)
  GROUP BY root_node_id
 ORDER BY 2
/
BREAK ON "Network"
COLUMN line_no NOPRINT

PROMPT One tree by RSF
WITH rsf (node_id, prefix, id, lev) AS (
SELECT node_id, '', NULL, 0
  FROM nodes_v
 WHERE node_id = 'COUNTRIES|HR'
 UNION ALL
SELECT CASE WHEN l.node_id_to = r.node_id THEN l.node_id_fr ELSE l.node_id_to END,
       CASE WHEN l.node_id_fr = l.node_id_to THEN '=' WHEN l.node_id_fr = r.node_id THEN '>' ELSE '<' END,
       l.link_id id, lev + 1
  FROM rsf r
  JOIN links_v l
    ON (l.node_id_fr = r.node_id OR l.node_id_to = r.node_id)
   AND l.link_id != Nvl (r.id, '0')
) SEARCH DEPTH FIRST BY node_id SET line_no
CYCLE node_id SET is_cycle TO '*' DEFAULT ' '
SELECT LPad (r.prefix || ' ', 2*r.lev) || r.node_id || is_cycle "Node",
        r.id "Link",
        line_no
  FROM rsf r
 ORDER BY line_no
/
PROMPT One tree by RSF filtered
WITH rsf (node_id, prefix, link_id, lev) AS (
SELECT node_id, '', NULL, 0
  FROM nodes_v
 WHERE node_id = 'COUNTRIES|HR'
 UNION ALL
SELECT CASE WHEN l.node_id_to = r.node_id THEN l.node_id_fr ELSE l.node_id_to END,
       CASE WHEN l.node_id_fr = l.node_id_to THEN '=' WHEN l.node_id_fr = r.node_id THEN '>' ELSE '<' END,
       l.link_id, lev + 1
  FROM rsf r
  JOIN links_v l
    ON (l.node_id_fr = r.node_id OR l.node_id_to = r.node_id)
   AND l.link_id != Nvl (r.link_id, '0')
) SEARCH DEPTH FIRST BY node_id SET line_no
CYCLE node_id SET is_cycle TO '*' DEFAULT ' '
, ranked AS (
SELECT node_id, link_id, lev, prefix, line_no, is_cycle,
        Row_Number() OVER (PARTITION BY link_id ORDER BY line_no) link_index,
        COUNT(*) OVER (PARTITION BY link_id) link_count
  FROM rsf
)
SELECT LPad (prefix || ' ', 2*lev) || node_id || is_cycle "Node",
        link_id "Link",
        link_count,
        line_no
  FROM ranked
 WHERE link_index = 1
 ORDER BY line_no
/
PROMPT One tree by Connect By
SELECT node_id_fr || ' > ' || node_id_to  "Nodes",
       LPad (' ', 2 * (LEVEL-1)) || link_id || CASE WHEN CONNECT_BY_ISCYCLE = 1 THEN '*' ELSE ' ' END "Link Path"
  FROM links_v
CONNECT BY NOCYCLE ((node_id_fr = PRIOR node_id_to OR node_id_to = PRIOR node_id_fr OR
                     node_id_fr = PRIOR node_id_fr OR node_id_to = PRIOR node_id_to) /*AND link_id != PRIOR link_id*/)
 START WITH node_id_fr = 'COUNTRIES|HR'
 ORDER SIBLINGS BY node_id_to
/
PROMPT One tree by Connect By filtered
WITH tree AS (
SELECT node_id_fr, node_id_to, CONNECT_BY_ISCYCLE cbi, link_id, LEVEL lev, ROWNUM rn
  FROM links_v
CONNECT BY NOCYCLE ((node_id_fr = PRIOR node_id_to OR node_id_to = PRIOR node_id_fr OR
                     node_id_fr = PRIOR node_id_fr OR node_id_to = PRIOR node_id_to) /*AND link_id != PRIOR link_id*/)
 START WITH node_id_fr = 'COUNTRIES|HR'
 ORDER SIBLINGS BY node_id_to
), ranked AS (
SELECT node_id_fr, node_id_to, cbi, link_id, lev, rn,
        Row_Number() OVER (PARTITION BY link_id ORDER BY ROWNUM) link_index,
        COUNT(*) OVER (PARTITION BY link_id) link_count
  FROM tree
)
SELECT node_id_fr || ' > ' || node_id_to  "Nodes",
       LPad (' ', 2 * (lev-1)) || link_id || CASE WHEN cbi = 1 THEN '*' ELSE ' ' END "Link Path",
       link_count
  FROM ranked
 WHERE link_index = 1
 ORDER BY rn
/
SET TIMING OFF
