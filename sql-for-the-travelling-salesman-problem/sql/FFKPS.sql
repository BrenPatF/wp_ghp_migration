SET TRIMSPOOL ON
SET PAGES 10000
SET lines 1000
SET SERVEROUTPUT ON
SPOOL ..\lst\FFKPS
SELECT 'Start: ' || To_Char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') FROM DUAL;

BREAK ON id
PROMPT Input categories
SELECT *
  FROM categories
 ORDER BY 1
/
COLUMN name FORMAT A10
COLUMN cat_id FORMAT A10

PROMPT Input cat counts
SELECT cat_id, COUNT(*)
  FROM items
GROUP BY cat_id
/
PROMPT Input items
SELECT id,
       name,
       cat_id,
       price,
       profit,
       Rank() OVER (ORDER BY profit DESC) prf_r,
       Rank() OVER (ORDER BY price / profit) vfp_r,
       Rank() OVER (ORDER BY price) prc_r
  FROM items
 ORDER BY Rank() OVER (ORDER BY profit DESC)
/
PROMPT 10 best value items by cat
BREAK ON cat_id
WITH cat_ranks AS (
SELECT id,
       name,
       cat_id,
       price,
       profit,
       Rank() OVER (PARTITION BY cat_id ORDER BY profit DESC) prf_r,
       Rank() OVER (PARTITION BY cat_id ORDER BY price / profit) vfp_r,
       Rank() OVER (PARTITION BY cat_id ORDER BY price) prc_r
  FROM items
)
SELECT cat_id,
       id,
       name,
       price,
       profit,
       prf_r,
       vfp_r,
       prc_r
  FROM cat_ranks
 WHERE vfp_r <= 10
 ORDER BY cat_id, vfp_r
/
CLEAR BREAK
PROMPT 10 best value items overall
WITH cat_ranks AS (
SELECT id,
       name,
       cat_id,
       price,
       profit,
       Rank() OVER (ORDER BY profit DESC) prf_r,
       Rank() OVER (ORDER BY price / profit) vfp_r,
       Rank() OVER (ORDER BY price) prc_r
  FROM items
)
SELECT id,
       name,
       cat_id,
       price,
       profit,
       prf_r,
       vfp_r,
       prc_r
  FROM cat_ranks
 WHERE vfp_r <= 10
 ORDER BY cat_id, vfp_r
/
SET TIMING ON
COLUMN path FORMAT A30
COLUMN node FORMAT A10
COLUMN p_id FORMAT A4
BREAK ON tot_profit ON tot_price ON rnk ON cat_id
VAR KEEP_NUM NUMBER
VAR MAX_PRICE NUMBER
BEGIN
  :KEEP_NUM := 20;
  :MAX_PRICE := 100000;
END;
/
PROMPT Top ten solutions
WITH  /* XPLF */ cat_counts AS (
SELECT Min (CASE WHEN id != 'ALL' THEN id END) min_id,
       Max (CASE id WHEN 'ALL' THEN min_items END) set_size
  FROM categories
), cat_runs AS (
SELECT id, Sum (CASE WHEN id != 'ALL' THEN min_items END) OVER (ORDER BY id DESC) num_remain, min_items, max_items
  FROM categories
), items_ranked AS (
SELECT id,
       cat_id,
       price,
       profit,
       Row_Number() OVER (ORDER BY cat_id, profit DESC) rnk,
       Min (price) OVER () min_price
  FROM items
), rsf (path_rnk, nxt_id, lev, tot_price, tot_profit, cat_id, n_cat, set_size, min_items, cat_path, path) AS (
SELECT 0, 0, 0, 0, 0,
       'ALL', 0, c.set_size, 0,
       CAST (NULL AS VARCHAR2(400)) cat_path,
       CAST (NULL AS VARCHAR2(400)) path
  FROM cat_counts c
 UNION ALL
SELECT Row_Number() OVER (PARTITION BY r.cat_path || p.cat_id ORDER BY r.tot_profit + p.profit DESC),
       p.rnk,
       r.lev + 1,
       r.tot_price + p.price,
       r.tot_profit + p.profit,
       p.cat_id,
       CASE p.cat_id WHEN r.cat_id THEN r.n_cat + 1 ELSE 1 END,
       r.set_size,
       m1.min_items,
       r.cat_path || p.cat_id,
       r.path || LPad (p.id, 3, '0')
  FROM rsf r
  JOIN items_ranked p
    ON p.rnk > r.nxt_id
  JOIN cat_runs m1
    ON m1.id = p.cat_id
   AND CASE p.cat_id WHEN r.cat_id THEN r.n_cat + 1 ELSE 1 END <= m1.max_items
   AND r.set_size - r.lev - 1 >= m1.num_remain - CASE p.cat_id WHEN r.cat_id THEN r.n_cat + 1 ELSE 1 END
   AND (r.lev = 0 OR p.cat_id = r.cat_id OR r.n_cat >= r.min_items)
 WHERE r.tot_price + p.price + (r.set_size - r.lev - 1) * p.min_price <= :MAX_PRICE
   AND r.path_rnk < :KEEP_NUM
   AND r.lev < r.set_size
)
, paths_ranked AS (
SELECT tot_price,
       tot_profit,
       set_size,
       Row_Number () OVER (ORDER BY tot_profit DESC) r_profit,
       path
  FROM rsf
 WHERE lev = set_size
), top_n_paths AS (
SELECT tot_price,
       tot_profit,
       r_profit,
       path,
       item_index
  FROM paths_ranked
  CROSS JOIN (SELECT LEVEL item_index FROM cat_counts CONNECT BY LEVEL <= set_size)
 WHERE r_profit <= 10
), top_n_sets AS (
SELECT tot_price,
       tot_profit,
       r_profit,
       path,
       item_index,
       Substr (path, (item_index - 1) * 3 + 1, 3) item_id
  FROM top_n_paths
)
SELECT  /*+ GATHER_PLAN_STATISTICS */  t.tot_profit,
       t.tot_price,
       t.r_profit rnk,
       p.cat_id,
       t.item_id p_id,
       p.name,
       p.price,
       p.profit
  FROM top_n_sets t
  JOIN items p
    ON p.id = t.item_id
ORDER BY t.r_profit, t.path, p.cat_id, t.item_index
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XPLF');
@..\..\Brendan\sql\L_Log_Default
COMMIT
/
SELECT 'End: ' || To_Char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') FROM DUAL;
SPOOL OFF
