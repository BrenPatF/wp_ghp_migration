VAR KEEP_NUM_ROOT NUMBER
VAR KEEP_NUM NUMBER
VAR SIGN NUMBER
BEGIN
  :KEEP_NUM_ROOT := &1;
  :KEEP_NUM := &2;
  :SIGN := &3;
END;
/
PROMPT Running for sign, root, keep root, keep values of...
PRINT :SIGN
PRINT :KEEP_NUM_ROOT
PRINT :KEEP_NUM
COLUMN root_leg FORMAT A12

BREAK ON root_leg ON path_rnk ON tot_dist
PROMPT Top n solutions
WITH count_towns AS (
SELECT Count(*) n_towns FROM towns
), dist_from_root AS (/* XTSP  */
SELECT a, b, dst, Row_Number () OVER (ORDER BY :SIGN * dst) rnk_by_dst, Count(DISTINCT a) OVER () + 1 n_towns
  FROM distances
 WHERE b > a
),  rsf (root, root_leg, path_rnk, nxt_id, lev, tot_price, path, n_towns) AS (
SELECT a, a || ' -> ' || b, 0, d.b, 2, d.dst, 
       CAST ('|' || LPad (d.a, 3, '0') || '|' || LPad (d.b, 3, '0') AS VARCHAR2(4000)) path,
       d.n_towns
  FROM dist_from_root d
 WHERE d.rnk_by_dst <= :KEEP_NUM_ROOT
 UNION ALL
SELECT r.root,
       r.root_leg,
       Row_Number() OVER (PARTITION BY r.root_leg ORDER BY :SIGN * (r.tot_price + d.dst)),
       d.b,
       r.lev + 1,
       r.tot_price + d.dst,
       r.path || '|' || LPad (d.b, 3, '0'),
       r.n_towns
  FROM rsf r
  JOIN distances d
    ON d.a = r.nxt_id
   AND r.path NOT LIKE '%' || '|' || LPad (d.b, 3, '0') || '%'
 WHERE r.path_rnk <= :KEEP_NUM
), circuits AS (
SELECT r.root_leg,
       Row_Number() OVER (PARTITION BY r.root_leg ORDER BY :SIGN * (r.tot_price + d.dst)) path_rnk,
       r.tot_price + d.dst tot_price,
       r.path || '|' || LPad (d.b, 3, '0') path
  FROM rsf r
  JOIN distances d
    ON d.a = r.nxt_id
   AND d.b = r.root
 WHERE r.lev = r.n_towns
   AND r.path_rnk <= :KEEP_NUM
), top_n_paths AS (
SELECT root_leg,
       tot_price,
       path,
       path_rnk,
       town_index
  FROM circuits
  CROSS JOIN (SELECT LEVEL town_index FROM count_towns c CONNECT BY LEVEL <= c.n_towns + 1)
 WHERE path_rnk <= :KEEP_NUM
), top_n_sets AS (
SELECT root_leg,
       tot_price,
       path,
       path_rnk,
       town_index,
       To_Number (Substr (path, (town_index - 1) * 4 + 2, 3)) town_id,
       Lag (To_Number (Substr (path, (town_index - 1) * 4 + 2, 3))) OVER (PARTITION BY root_leg, path_rnk ORDER BY town_index) town_id_prior
  FROM top_n_paths
)
SELECT /*+ GATHER_PLAN_STATISTICS */
       top.root_leg,
       top.path_rnk,
       Round (top.tot_price, 2) tot_dist,
       top.town_id,
       twn.name,
       Round (dst.dst, 2) leg_dist,
       Round (Sum (dst.dst) OVER (PARTITION BY root_leg, path_rnk ORDER BY town_index), 2) cum_dist
  FROM top_n_sets top
  JOIN towns twn
    ON twn.id = top.town_id
  LEFT JOIN distances dst
    ON dst.a = top.town_id_prior
   AND dst.b = top.town_id
ORDER BY top.root_leg, top.path_rnk, top.town_index
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XTSP');
