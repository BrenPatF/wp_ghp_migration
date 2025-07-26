SET TRIMSPOOL ON
SPOOL ..\lst\Dijkstra1O
alter session set nls_date_format='hh24:mi';
SET PAGES 1000
SET LINES 200
COLUMN path  FORMAT A20
COLUMN node  FORMAT A20
COLUMN lp    FORMAT A2
COLUMN lev   FORMAT 990
COLUMN rnk   FORMAT 990
COLUMN rnk_t FORMAT 99990
COLUMN cost  FORMAT 9990
EXEC Utils.Clear_Log;

@..\sql\c_dijkstra
VAR SRC VARCHAR2(10)
EXEC :SRC := 'A'

PROMPT BPF Solution - one-way from A
WITH paths (node, path, cost, rnk, lev) AS (
SELECT a.dst, a.src || ',' || a.dst, a.distance, 1, 1
  FROM arcs a
WHERE a.src = :SRC
 UNION ALL
SELECT a.dst, 
        p.path || ',' || a.dst, 
        p.cost + a.distance, 
        Rank () OVER (PARTITION BY a.dst ORDER BY p.cost + a.distance),
        p.lev + 1
  FROM paths p
  JOIN arcs a
    ON a.src = p.node
   AND p.rnk = 1
)  SEARCH DEPTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
, paths_ranked AS (
SELECT lev, node, path, cost, Rank () OVER (PARTITION BY node ORDER BY cost) rnk_t, lp, line_no
  FROM paths
  WHERE rnk = 1
)
SELECT /*+ GATHER_PLAN_STATISTICS ONEWAY */ LPad (node, 1 + 2* (lev - 1), '.') node, lev, path, cost, lp
  FROM paths_ranked
  WHERE rnk_t = 1
  ORDER BY line_no
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'ONEWAY');
PROMPT BPF Solution - one-way, all intermediate
WITH paths (node, path, cost, rnk, lev) AS (
SELECT a.dst, a.src || ',' || a.dst, a.distance, 1, 1
  FROM arcs a
WHERE a.src = :SRC
 UNION ALL
SELECT a.dst, 
        p.path || ',' || a.dst, 
        p.cost + a.distance, 
        Rank () OVER (PARTITION BY a.dst ORDER BY p.cost + a.distance),
        p.lev + 1
  FROM paths p
  JOIN arcs a
    ON a.src = p.node
   AND p.rnk = 1
)  SEARCH DEPTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
, paths_ranked AS (
SELECT lev, node, path, cost, Rank () OVER (PARTITION BY node ORDER BY cost) rnk_t, rnk, lp, line_no
  FROM paths
)
SELECT LPad (node, 1 + 2* (lev - 1), '.') node, lev, path, cost, rnk_t, rnk, lp
  FROM paths_ranked
  ORDER BY line_no
/
PROMPT BPF Solution - one-way, all intermediate, breadth first
WITH paths (node, path, cost, rnk, lev) AS (
SELECT a.dst, a.src || ',' || a.dst, a.distance, 1, 1
  FROM arcs a
WHERE a.src = :SRC
 UNION ALL
SELECT a.dst, 
        p.path || ',' || a.dst, 
        p.cost + a.distance, 
        Rank () OVER (PARTITION BY a.dst ORDER BY p.cost + a.distance),
        p.lev + 1
  FROM paths p
  JOIN arcs a
    ON a.src = p.node
   AND p.rnk = 1
)  SEARCH BREADTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
, paths_ranked AS (
SELECT lev, node, path, cost, Rank () OVER (PARTITION BY node ORDER BY cost) rnk_t, rnk, lp, line_no
  FROM paths
)
SELECT LPad (node, 1 + 2* (lev - 1), '.') node, lev, path, cost, rnk_t, rnk, lp
  FROM paths_ranked
  ORDER BY line_no
/
PROMPT BPF Solution - one-way, all solutions
WITH paths (node, path, cost, rnk, lev) AS (
SELECT a.dst, a.src || ',' || a.dst, a.distance, 1, 1
  FROM arcs a
WHERE a.src = :SRC
 UNION ALL
SELECT a.dst, 
        p.path || ',' || a.dst, 
        p.cost + a.distance, 
        Rank () OVER (PARTITION BY a.dst ORDER BY p.cost + a.distance),
        p.lev + 1
  FROM paths p
  JOIN arcs a
    ON a.src = p.node
)  SEARCH DEPTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
, paths_ranked AS (
SELECT lev, node, path, cost, Rank () OVER (PARTITION BY node ORDER BY cost) rnk_t, rnk, lp, line_no
  FROM paths
)
SELECT LPad (node, 1 + 2* (lev - 1), '.') node, lev, path, cost, rnk_t, rnk, lp
  FROM paths_ranked
  ORDER BY line_no
/
EXEC :SRC := 'J'

PROMPT BPF Solution - one-way fom J
WITH paths (node, path, cost, rnk, lev) AS (
SELECT a.dst, a.src || ',' || a.dst, a.distance, 1, 1
  FROM arcs a
WHERE a.src = :SRC
 UNION ALL
SELECT a.dst, 
        p.path || ',' || a.dst, 
        p.cost + a.distance, 
        Rank () OVER (PARTITION BY a.dst ORDER BY p.cost + a.distance),
        p.lev + 1
  FROM paths p
  JOIN arcs a
    ON a.src = p.node
   AND p.rnk = 1
)  SEARCH DEPTH FIRST BY node SET line_no
CYCLE node SET lp TO '*' DEFAULT ' '
, paths_ranked AS (
SELECT lev, node, path, cost, Rank () OVER (PARTITION BY node ORDER BY cost) rnk_t, lp, line_no
  FROM paths
  WHERE rnk = 1
)
SELECT LPad (node, 1 + 2* (lev - 1), '.') node, lev, path, cost, lp
  FROM paths_ranked
  WHERE rnk_t = 1
  ORDER BY line_no
/
@..\..\Brendan\sql\L_Log_Default
SPOOL OFF
