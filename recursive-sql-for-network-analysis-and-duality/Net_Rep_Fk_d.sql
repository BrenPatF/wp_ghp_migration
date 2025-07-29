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

PROMPT One tree by RSF excluded as does not terminate
SET TIMING OFF
