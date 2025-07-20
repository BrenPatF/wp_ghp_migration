BEGIN
  :KEEP_NUM := &1;
END;
/
PROMPT Running for keep value of...
PRINT :KEEP_NUM

BREAK ON path_rnk ON tot_dist
PROMPT Top n solutions
WITH count_towns AS (
SELECT COUNT(*) num FROM towns
),  rsf (path_rnk, nxt_id, lev, tot_price, path, n_towns) AS (
SELECT 0, t.id, 0, 0, 
       CAST ('|' || LPad (t.id, 3, '0') AS VARCHAR2(4000)) path,
       c.num
  FROM towns t
  CROSS JOIN count_towns c
 WHERE t.id = 1
 UNION ALL
SELECT Row_Number() OVER (ORDER BY r.tot_price + d.dst),
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
), top_n_paths AS (
SELECT tot_price,
       path,
       path_rnk,
       town_index
  FROM rsf
  CROSS JOIN (SELECT LEVEL town_index FROM count_towns CONNECT BY LEVEL <= num)
 WHERE lev = n_towns - 1
   AND path_rnk <= :KEEP_NUM
), top_n_teams AS (
SELECT tot_price,
       path,
       path_rnk,
       town_index,
       To_Number (Substr (path, (town_index - 1) * 4 + 2, 3)) town_id,
       Lag (To_Number (Substr (path, (town_index - 1) * 4 + 2, 3))) OVER (PARTITION BY path_rnk ORDER BY town_index) town_id_prior
  FROM top_n_paths
)
SELECT top.path_rnk,
       Round (top.tot_price, 2) tot_dist,
       top.town_id,
       twn.name,
       Round (dst.dst, 2) leg_dist
  FROM top_n_teams top
  JOIN towns twn
    ON twn.id = top.town_id
  LEFT JOIN distances dst
    ON dst.a = top.town_id_prior
   AND dst.b = top.town_id
ORDER BY top.path_rnk, top.town_index
/
