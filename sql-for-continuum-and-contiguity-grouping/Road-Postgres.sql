REM Migrated from Wordpress July 2025
DROP TABLE road_events;
DROP TABLE roads;
CREATE TABLE roads (
    id                  INT NOT NULL,
    start_point         INT NOT NULL,
    end_point           INT NOT NULL,
    road_desc           VARCHAR(100) NOT NULL,
    CONSTRAINT road_pk PRIMARY KEY (id)
);
CREATE TABLE road_events (
    id                  INT NOT NULL,
    road_id             INT NOT NULL,
    start_point         INT NOT NULL,
    end_point           INT NOT NULL,
    event_date          DATE NOT NULL,
    event_type          VARCHAR(50) NOT NULL,
    CONSTRAINT road_event_pk PRIMARY KEY (id),
    CONSTRAINT rev_roa_fk FOREIGN KEY (road_id) REFERENCES roads (id),
    CONSTRAINT c_event_type CHECK (event_type IN ('BASE', 'OPEN', 'CLOSED', 'OTHER'))
);
CREATE INDEX road_event_N1 ON road_events (road_id, start_point);

CREATE INDEX road_event_N2 ON road_events (road_id, event_date);

CREATE INDEX road_event_N3 ON road_events (road_id, start_point, end_point);

INSERT INTO roads VALUES (1, 0, 200, 'The Strand');

INSERT INTO roads VALUES (2, 0, 100, 'Piccadilly');

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
\qecho Input data - Roads
SELECT  r.id road_id,
        r.road_desc,
        r.start_point,
        r.end_point
  FROM roads r
 ORDER BY 1, 3;
\qecho Input data - road_events
SELECT  r.id                    road_id,    
        e.id                    rev_id,
        e.event_type            e_type,
        e.start_point,   
        e.end_point,
        e.event_date            e_date
  FROM road_events e
  JOIN roads r
    ON r.id = e.road_id
 ORDER BY 2;
\qecho Zero-Dimensional Solution with Rank
WITH ranked_events AS (
SELECT road_id, start_point, end_point, event_date, event_type,
       Rank() OVER (PARTITION BY road_id ORDER BY event_date DESC) rnk
  FROM road_events
)
SELECT r.road_desc, r.start_point r_start, r.end_point r_end,
        e.start_point e_start, e.end_point e_end, e.event_date e_date, e.event_type e_type
  FROM ranked_events e
  JOIN roads r
    ON r.id = e.road_id
   AND e.rnk = 1
 ORDER BY 1, 2, 3
;
\qecho Explaining Zero-Dimensional Solution with Rank...
EXPLAIN ANALYZE WITH ranked_events AS (
SELECT road_id, start_point, end_point, event_date, event_type,
       Rank() OVER (PARTITION BY road_id ORDER BY event_date DESC) rnk
  FROM road_events
)
SELECT r.road_desc, r.start_point r_start, r.end_point r_end,
        e.start_point e_start, e.end_point e_end, e.event_date e_date, e.event_type e_type
  FROM ranked_events e
  JOIN roads r
    ON r.id = e.road_id
   AND e.rnk = 1
 ORDER BY 1, 2, 3
;
\qecho Continuum/contiguity Solution with Row_Number...
WITH breaks AS  (
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
), ranked_events AS ( 
        SELECT l.road_id, l.leg_start, l.leg_end,
               e.id event_id, Coalesce (e.event_type, '(none)') event_type,
               Row_Number() OVER (PARTITION BY l.road_id, l.leg_start ORDER BY e.event_date DESC) rnk
          FROM legs l
          LEFT JOIN road_events e
            ON e.road_id = l.road_id
           AND e.start_point <= l.leg_start
           AND e.end_point >= l.leg_end
         WHERE l.leg_end IS NOT NULL
), latest_events_group AS ( 
        SELECT road_id,
               leg_start,
               leg_end,
               event_id,
               event_type,
               Dense_Rank () OVER (PARTITION BY road_id ORDER BY leg_start, leg_end) -
               Dense_Rank () OVER (PARTITION BY road_id, event_type ORDER BY leg_start, leg_end) group_no
          FROM ranked_events
         WHERE rnk = 1
)
SELECT l.road_id, r.road_desc,
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
ORDER BY 1, 2, 3;
\qecho Postgres version...
SELECT Version();
\qecho Explaining  Continuum/contiguity Solution with Row_Number...
EXPLAIN ANALYZE WITH breaks AS  (
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
), ranked_events AS ( 
        SELECT l.road_id, l.leg_start, l.leg_end,
               e.id event_id, Coalesce (e.event_type, '(none)') event_type,
               Row_Number() OVER (PARTITION BY l.road_id, l.leg_start ORDER BY e.event_date DESC) rnk
          FROM legs l
          LEFT JOIN road_events e
            ON e.road_id = l.road_id
           AND e.start_point <= l.leg_start
           AND e.end_point >= l.leg_end
         WHERE l.leg_end IS NOT NULL
), latest_events_group AS ( 
        SELECT road_id,
               leg_start,
               leg_end,
               event_id,
               event_type,
               Dense_Rank () OVER (PARTITION BY road_id ORDER BY leg_start, leg_end) -
               Dense_Rank () OVER (PARTITION BY road_id, event_type ORDER BY leg_start, leg_end) group_no
          FROM ranked_events
         WHERE rnk = 1
)
SELECT l.road_id, r.road_desc,
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
ORDER BY 1, 2, 3;
