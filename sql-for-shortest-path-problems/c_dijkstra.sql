DROP TABLE arcs
/
CREATE TABLE arcs (
        src              VARCHAR2(10) NOT NULL,
        dst              VARCHAR2(10) NOT NULL,
        distance         NUMBER(3,0) NOT NULL,
        CONSTRAINT arcs_pk PRIMARY KEY (src, dst)
)
/
REM INSERTING into ARCS

INSERT INTO arcs VALUES ('A','B',2);
INSERT INTO arcs VALUES ('A','C',4);
INSERT INTO arcs VALUES ('A','D',3);
INSERT INTO arcs VALUES ('B','E',7);
INSERT INTO arcs VALUES ('C','E',3);
INSERT INTO arcs VALUES ('D','E',4);
INSERT INTO arcs VALUES ('B','F',4);
INSERT INTO arcs VALUES ('C','F',2);
INSERT INTO arcs VALUES ('D','F',1);
INSERT INTO arcs VALUES ('B','G',6);
INSERT INTO arcs VALUES ('C','G',4);
INSERT INTO arcs VALUES ('D','G',5);
INSERT INTO arcs VALUES ('E','H',1);
INSERT INTO arcs VALUES ('F','H',6);
INSERT INTO arcs VALUES ('G','H',3);
INSERT INTO arcs VALUES ('E','I',4);
INSERT INTO arcs VALUES ('F','I',3);
INSERT INTO arcs VALUES ('G','I',3);
INSERT INTO arcs VALUES ('H','J',3);
INSERT INTO arcs VALUES ('I','J',4);
BEGIN
  DBMS_Stats.Gather_Table_Stats (
              ownname                 => 'DIJKSTRA',
              tabname                 => 'arcs');
END;
/

PROMPT Arcs
SELECT src, dst, distance
  FROM arcs
 ORDER BY 1, 2, 3
/
PROMPT Nodes
SELECT src node
  FROM arcs
 UNION
SELECT dst
  FROM arcs
 ORDER BY 1
/
