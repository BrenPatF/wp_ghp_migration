SET TRIMSPOOL ON
SET PAGES 10000
SET lines 1000
SET SERVEROUTPUT ON
SPOOL ..\lst\Town_Round
SELECT 'Start: ' || To_Char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') FROM DUAL;
BEGIN
  Utils.Clear_Log;
END;
/
BREAK ON tot_dist
PROMPT Ordered solution
WITH legs AS (
SELECT twn.id town_id,
       Lag (twn.id) OVER (ORDER BY twn.id) town_id_prior
  FROM towns twn
)
SELECT Round (Sum (d.dst) OVER ()) tot_dist,
       t.id,
       t.name,
       Round (d.dst) leg_dist
  FROM towns t
  JOIN legs l
    ON l.town_id = t.id
  LEFT JOIN distances d
    ON d.a = l.town_id_prior
   AND d.b = l.town_id
ORDER BY t.id
/
SET TIMING ON
@..\sql\Town_Round_SQL 2 2 1

@..\..\Brendan\sql\L_Log_Default
COMMIT
/
SELECT 'End: ' || To_Char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') FROM DUAL;
SPOOL OFF
