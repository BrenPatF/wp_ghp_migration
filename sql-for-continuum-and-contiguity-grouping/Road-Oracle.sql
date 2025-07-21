SET TRIMSPOOL ON
SET LINES 300
SET PAGES 1000
SET VERIFY OFF
SET ECHO OFF
SPOOL ..\lst\Road
EXEC Utils.Clear_Log;

DEFINE LAST_DATE='01-JAN-2000'

DROP TABLE road_events
/
DROP TABLE roads
/
CREATE TABLE roads (
    id                  NUMBER NOT NULL,
    start_point         NUMBER NOT NULL,
    end_point           NUMBER NOT NULL,
    road_desc           VARCHAR2(100) NOT NULL,
    CONSTRAINT road_pk PRIMARY KEY (id)
)
/
CREATE TABLE road_events (
    id                  NUMBER NOT NULL,
    road_id             NUMBER NOT NULL,
    start_point         NUMBER NOT NULL,
    end_point           NUMBER NOT NULL,
    event_date          DATE NOT NULL,
    event_type          VARCHAR2(50) NOT NULL,
    CONSTRAINT road_event_pk PRIMARY KEY (id),
    CONSTRAINT rev_roa_fk FOREIGN KEY (road_id) REFERENCES roads (id),
    CONSTRAINT c_event_type CHECK (event_type IN ('BASE', 'OPEN', 'CLOSED', 'OTHER'))
)
/
CREATE INDEX road_event_N1 ON road_events (road_id, start_point)
/
CREATE INDEX road_event_N2 ON road_events (road_id, event_date)
/
CREATE INDEX road_event_N3 ON road_events (road_id, start_point, end_point)
/
INSERT INTO roads VALUES (1, 0, 200, 'The Strand')
/
INSERT INTO roads VALUES (2, 0, 100, 'Piccadilly')
/

COLUMN id                  FORMAT 990
COLUMN e_type              FORMAT A6
COLUMN road_id             FORMAT 990
COLUMN road_desc           FORMAT A15
COLUMN sp_grp              FORMAT 999990
COLUMN rnk_g               FORMAT 999990
COLUMN rnk_p               FORMAT 999990
COLUMN dns_grp             FORMAT 999990
SET PAGES 1000
INSERT INTO road_events VALUES (1,      1, 0,    10,     '01-JAN-2007', 'OPEN');
INSERT INTO road_events VALUES (2,      1, 20,   50,     '01-JAN-2008', 'OPEN');
INSERT INTO road_events VALUES (3,      1, 130,  160,    '01-FEB-2008', 'CLOSED');
INSERT INTO road_events VALUES (4,      1, 55,   85,     '05-JUN-2008', 'CLOSED');
INSERT INTO road_events VALUES (5,      1, 45,   115,    '01-JAN-2009', 'OTHER');
INSERT INTO road_events VALUES (6,      1, 60,   100,    '12-FEB-2011', 'OPEN');
INSERT INTO road_events VALUES (7,      1, 115,  145,    '12-FEB-2012', 'CLOSED');

INSERT INTO road_events VALUES (8,      2, 10,   30,    '01-JAN-2010', 'CLOSED');
INSERT INTO road_events VALUES (9,      2, 40,   50,    '01-JAN-2011', 'OPEN');
INSERT INTO road_events VALUES (10,     2, 50,   70,    '01-JAN-2012', 'OPEN');
/*
INSERT INTO road_events VALUES (8,      2, 0,    200,    '01-JAN-2000', 'BASE');
INSERT INTO road_events VALUES (9,      2, 0,    10,     '01-JAN-2007', 'OPEN');
INSERT INTO road_events VALUES (10,     2, 20,   50,     '01-JAN-2008', 'OPEN');
INSERT INTO road_events VALUES (11,     2, 130,  160,    '01-FEB-2008', 'CLOSED');
INSERT INTO road_events VALUES (12,     2, 55,   85,     '05-JUN-2008', 'CLOSED');
INSERT INTO road_events VALUES (13,     2, 45,   115,    '01-JAN-2009', 'OTHER');
INSERT INTO road_events VALUES (14,     2, 60,   100,    '12-FEB-2011', 'OPEN');
INSERT INTO road_events VALUES (15,     2, 115,  145,    '12-FEB-2012', 'CLOSED');
*/
BEGIN
    DBMS_Stats.Gather_Table_Stats (
                ownname                 => 'TEST',
                tabname                 => 'ROADS',
                estimate_percent        => 10);
    DBMS_Stats.Gather_Table_Stats (
                ownname                 => 'TEST',
                tabname                 => 'ROAD_EVENTS',
                estimate_percent        => 10);
END;
/
BREAK ON road_id ON road_desc
PROMPT Input data - Roads
SELECT  r.id road_id,
        r.road_desc,
        r.start_point,
        r.end_point
  FROM roads r
 ORDER BY 1, 3
/
BREAK ON road_id
PROMPT Input data - road_events
SELECT  r.id                    road_id,    
        e.id                    rev_id,
        e.event_type            e_type,
        e.start_point,   
        e.end_point,
        e.event_date            e_date
  FROM road_events e
  JOIN roads r
    ON r.id = e.road_id
 ORDER BY 2
/
PROMPT Zero-Dimensional Solution
SELECT r.road_desc, r.start_point r_start, r.end_point r_end,
       Max (e.start_point) KEEP (DENSE_RANK LAST ORDER BY e.event_date) e_start, 
       Max (e.end_point) KEEP (DENSE_RANK LAST ORDER BY e.event_date) e_end,
       Max (e.event_date) KEEP (DENSE_RANK LAST ORDER BY e.event_date) e_date,
       Max (e.event_type) KEEP (DENSE_RANK LAST ORDER BY e.event_date) e_type
  FROM road_events e
  JOIN roads r
    ON r.id = e.road_id
 GROUP BY r.road_desc, r.start_point, r.end_point
 ORDER BY 1, 2, 3
/
L
BREAK ON road_id ON road_desc
PROMPT Grouping by differences
WITH /* DR_TOP_1 */ breaks AS  (
        SELECT road_id, start_point bp FROM road_events
         UNION
        SELECT road_id, end_point FROM road_events
         UNION
        SELECT id, start_point FROM roads
         UNION
        SELECT id, end_point FROM roads
), legs AS (
        SELECT road_id, bp leg_start, Lead (bp) OVER (PARTITION BY road_id ORDER BY bp) leg_end
          FROM breaks
), latest_events AS ( 
        SELECT l.road_id, l.leg_start, l.leg_end,
               Max (e.id) KEEP (DENSE_RANK LAST ORDER BY e.event_date) event_id,
               Nvl (Max (e.event_type) KEEP (DENSE_RANK LAST ORDER BY e.event_date), '(none)') event_type
          FROM legs l
          LEFT JOIN road_events e
            ON e.road_id = l.road_id
           AND e.start_point <= l.leg_start
           AND e.end_point >= l.leg_end
         WHERE l.leg_end IS NOT NULL
         GROUP BY l.road_id, l.leg_start, l.leg_end
), latest_events_group AS ( 
        SELECT road_id,
               leg_start,
               leg_end,
               event_id,
               event_type,
               Dense_Rank () OVER (PARTITION BY road_id ORDER BY leg_start, leg_end) -
               Dense_Rank () OVER (PARTITION BY road_id, event_type ORDER BY leg_start, leg_end) group_no
          FROM latest_events
)
SELECT /*+ GATHER_PLAN_STATISTICS */
       l.road_id, r.road_desc,
       Min (l.leg_start)        sec_start,
       Max (l.leg_end)          sec_end,
       l.event_type             e_type,
       l.group_no
  FROM latest_events_group l
  JOIN roads r
    ON r.id = l.road_id
 GROUP BY l.road_id,
        r.road_desc, 
        l.event_type,
        l.group_no
ORDER BY 1, 2, 3
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'DR_TOP_1');
PROMPT M-R
WITH /* MR_TOP_1 */ breaks AS  (
        SELECT road_id, start_point bp FROM road_events
         UNION
        SELECT road_id, end_point FROM road_events
         UNION
        SELECT id, start_point FROM roads
         UNION
        SELECT id, end_point FROM roads
), legs AS (
        SELECT road_id, bp leg_start, Lead (bp) OVER (PARTITION BY road_id ORDER BY bp) leg_end
          FROM breaks
), latest_events AS ( 
        SELECT l.road_id, r.road_desc, l.leg_start, l.leg_end,
               Max (e.id) KEEP (DENSE_RANK LAST ORDER BY e.event_date) event_id,
               Nvl (Max (e.event_type) KEEP (DENSE_RANK LAST ORDER BY e.event_date), '(none)') event_type
          FROM legs l
          JOIN roads r
            ON r.id = l.road_id
          LEFT JOIN road_events e
            ON e.road_id = l.road_id
           AND e.start_point <= l.leg_start
           AND e.end_point >= l.leg_end
         WHERE l.leg_end IS NOT NULL
         GROUP BY l.road_id, r.road_desc, l.leg_start, l.leg_end
)
SELECT /*+ GATHER_PLAN_STATISTICS */
       m.road_id, m.road_desc, m.sec_start, m.sec_end, m.event_type e_type
  FROM latest_events
 MATCH_RECOGNIZE (
   PARTITION BY road_id, road_desc
   ORDER BY leg_start, leg_end
   MEASURES FIRST (leg_start) sec_start,
            LAST (leg_end) sec_end,
            LAST (event_type) event_type
   PATTERN (strt sm*)
   DEFINE sm AS PREV(sm.event_type) = sm.event_type
 ) m
ORDER BY 1, 2, 3
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'MR_TOP_1');
SET TIMING OFF
@..\..\Brendan\sql\L_Log_Default
SPOOL OFF

