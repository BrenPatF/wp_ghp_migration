SET TRIMSPOOL ON
SPOOL ..\lst\Dijkstra2Oa
alter session set nls_date_format='hh24:mi';
SET PAGES 30000
SET LINES 200
COLUMN path  FORMAT A25
COLUMN node  FORMAT A25
COLUMN lp    FORMAT A2
COLUMN lev   FORMAT 990
COLUMN rnk   FORMAT 990
COLUMN rnk_t FORMAT 99990
COLUMN cost  FORMAT 9990

@..\sql\c_dijkstra

PROMPT Add reverse arcs
INSERT INTO arcs
SELECT dst, src, distance
  FROM arcs
/
BEGIN
  DBMS_Stats.Gather_Table_Stats (
              ownname                 => 'DIJKSTRA',
              tabname                 => 'arcs');
END;
/

VAR SRC VARCHAR2(10)
EXEC :SRC := 'A'

PROMPT BPF Solution - two-way from A
WITH paths (node, path, cost, rnk, lev) AS (
SELECT :SRC, :SRC, 0, 1, 0
  FROM DUAL
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
SELECT LPad (node, 1 + 2 * lev, '.') node, lev, path, cost, lp
  FROM paths_ranked
  WHERE rnk_t = 1
  ORDER BY line_no
/
PROMPT BPF Solution - two-way, all intermediate
WITH paths (node, path, cost, rnk, lev) AS (
SELECT :SRC, :SRC, 0, 1, 0
  FROM DUAL
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
SELECT LPad (node, 1 + 2 * lev, '.') node, lev, path, cost, rnk_t, rnk, lp
  FROM paths_ranked
  ORDER BY line_no
/
PROMPT BPF Solution - two-way, all solutions
WITH paths (node, path, cost, rnk, lev) AS (
SELECT :SRC, :SRC, 0, 1, 0
  FROM DUAL
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
SELECT LPad (node, 1 + 2 * lev, '.') node, lev, path, cost, rnk_t, rnk, lp
  FROM paths_ranked
  ORDER BY line_no
/
SPOOL OFF
