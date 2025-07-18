REM 19 July 2025, Note on migration to GitHub Pages:
REM               This script has dependencies on a Utils package and a logging table, so will not
REM               run without some extra work - included for reference only.
REM               The L_XML.LST file is the spool file from April 2012.

REM
REM Author:      Brendan Furey
REM Date:        21 April 2013
REM Description: SQL script to test loading of XML data from file to Oracle table, then selecting 
REM              the data relationally using SQL XML functionality described in
REM              'Design Patterns for Extracting Relational Data from XML', http://aprogrammerwrites.eu/?p=783.
REM
SET TRIMSPOOL ON
SET LINES 250
SET PAGES 1000
SPOOL L_XML

EXECUTE Utils.Clear_Log;
SET TIMING ON
DROP TABLE xml_design_pattern
/
CREATE TABLE xml_design_pattern (xml_field XMLTYPE) XMLTYPE COLUMN xml_field STORE AS BINARY XML
/
PROMPT Load test XML data...
DELETE xml_design_pattern;

INSERT INTO xml_design_pattern VALUES (XMLTYPE (BFilename ('BRENDAN_IN_DIR', 'DESIGN_PATTERN.xml'), NLS_Charset_id('AL32UTF8')))
/
BEGIN
    DBMS_Stats.Gather_Table_Stats (
                ownname                 => 'TEST',
                tabname                 => 'XML_DESIGN_PATTERN',
                estimate_percent        => 10);
END;
/
COLUMN xml_field FORMAT A60
COLUMN global_id FORMAT A15
COLUMN global_val FORMAT A15
COLUMN master FORMAT A15
COLUMN detail FORMAT A20
PROMPT XML data...
SET LONG 4000
SELECT * FROM xml_design_pattern
/
PROMPT Unfiltered, Inner Joins...
SELECT x1.global_id, x1.global_val, x2.master, x3.detail
  FROM xml_design_pattern t,
     XMLTable ('/elem-0-body'
                   PASSING t.xml_field
                   COLUMNS global_id           VARCHAR2(100) PATH 'elem-1-global/@attr-1-global',
                           global_val          VARCHAR2(100) PATH 'elem-1-global/field-1-global',
                           l2_xml              XMLTYPE       PATH 'list-1-master') x1,
     XMLTable ('/list-1-master/elem-1-master'
                   PASSING x1.l2_xml
                   COLUMNS master              VARCHAR2(100) PATH 'field-1-master',
                           l3_xml              XMLTYPE       PATH 'list-2-detail') x2,
     XMLTable ('/list-2-detail/elem-2-detail'
                   PASSING x2.l3_xml
                   COLUMNS detail              VARCHAR2(100) PATH 'field-2-detail') x3
ORDER BY 1, 2, 3, 4
/
PROMPT Unfiltered, Outer Joins on all...
SELECT x1.global_id, x1.global_val, x2.master, x3.detail
  FROM xml_design_pattern t,
     XMLTable ('/elem-0-body'
                   PASSING t.xml_field
                   COLUMNS global_id           VARCHAR2(100) PATH 'elem-1-global/@attr-1-global',
                           global_val          VARCHAR2(100) PATH 'elem-1-global/field-1-global',
                           l2_xml              XMLTYPE       PATH 'list-1-master') (+) x1,
     XMLTable ('/list-1-master/elem-1-master'
                   PASSING x1.l2_xml
                   COLUMNS master              VARCHAR2(100) PATH 'field-1-master',
                           l3_xml              XMLTYPE       PATH 'list-2-detail') (+) x2,
     XMLTable ('/list-2-detail/elem-2-detail'
                   PASSING x2.l3_xml
                   COLUMNS detail              VARCHAR2(100) PATH 'field-2-detail') (+) x3
ORDER BY 1, 2, 3, 4
/
PROMPT Filtered, Inner Joins...
SELECT /*+ GATHER_PLAN_STATISTICS XMLIJ */ 
       x1.global_id, x1.global_val, x2.master, x3.detail
  FROM xml_design_pattern t,
     XMLTable ('/elem-0-body'
                   PASSING t.xml_field
                   COLUMNS global_id           VARCHAR2(100) PATH 'elem-1-global/@attr-1-global',
                           global_val          VARCHAR2(100) PATH 'elem-1-global/field-1-global',
                           l2_xml              XMLTYPE       PATH 'list-1-master') x1,
     XMLTable ('/list-1-master/elem-1-master'
                   PASSING x1.l2_xml
                   COLUMNS master              VARCHAR2(100) PATH 'field-1-master',
                           l3_xml              XMLTYPE       PATH 'list-2-detail') x2,
     XMLTable ('/list-2-detail/elem-2-detail[field-2-detail != "val_detail_m2_d1"]'
                   PASSING x2.l3_xml
                   COLUMNS detail              VARCHAR2(100) PATH 'field-2-detail') x3
ORDER BY 1, 2, 3, 4
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XMLIJ');
PROMPT Filtered, Outer Joins on all...
SELECT /*+ GATHER_PLAN_STATISTICS XMLOJ */ 
       x1.global_id, x1.global_val, x2.master, x3.detail
  FROM xml_design_pattern t,
     XMLTable ('/elem-0-body'
                   PASSING t.xml_field
                   COLUMNS global_id           VARCHAR2(100) PATH 'elem-1-global/@attr-1-global',
                           global_val          VARCHAR2(100) PATH 'elem-1-global/field-1-global',
                           l2_xml              XMLTYPE       PATH 'list-1-master') (+) x1,
     XMLTable ('/list-1-master/elem-1-master'
                   PASSING x1.l2_xml
                   COLUMNS master              VARCHAR2(100) PATH 'field-1-master',
                           l3_xml              XMLTYPE       PATH 'list-2-detail') (+) x2,
     XMLTable ('/list-2-detail/elem-2-detail[field-2-detail != "val_detail_m2_d1"]'
                   PASSING x2.l3_xml
                   COLUMNS detail              VARCHAR2(100) PATH 'field-2-detail') (+) x3
ORDER BY 1, 2, 3, 4
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XMLOJ');

PROMPT Filtered, ANSI Outer Joins on all...
SELECT /*+ GATHER_PLAN_STATISTICS XMLOJA */ 
       x1.global_id, x1.global_val, x2.master, x3.detail
  FROM xml_design_pattern t
    LEFT JOIN
     XMLTable ('/elem-0-body'
                   PASSING t.xml_field
                   COLUMNS global_id           VARCHAR2(100) PATH 'elem-1-global/@attr-1-global',
                           global_val          VARCHAR2(100) PATH 'elem-1-global/field-1-global',
                           l2_xml              XMLTYPE       PATH 'list-1-master') x1 ON 1=1
    LEFT JOIN
     XMLTable ('/list-1-master/elem-1-master'
                   PASSING x1.l2_xml
                   COLUMNS master              VARCHAR2(100) PATH 'field-1-master',
                           l3_xml              XMLTYPE       PATH 'list-2-detail') x2 ON 1=1
    LEFT JOIN
     XMLTable ('/list-2-detail/elem-2-detail[field-2-detail != "val_detail_m2_d1"]'
                   PASSING x2.l3_xml
                   COLUMNS detail              VARCHAR2(100) PATH 'field-2-detail') x3 ON 1=1
ORDER BY 1, 2, 3, 4
/
EXECUTE Utils.Write_Plan (p_sql_marker => 'XMLOJA');
PROMPT Unfiltered, Outer Joins on detail only...
SELECT x1.global_id, x1.global_val, x2.master, x3.detail
  FROM xml_design_pattern t,
     XMLTable ('/elem-0-body'
                   PASSING t.xml_field
                   COLUMNS global_id           VARCHAR2(100) PATH 'elem-1-global/@attr-1-global',
                           global_val          VARCHAR2(100) PATH 'elem-1-global/field-1-global',
                           l2_xml              XMLTYPE       PATH 'list-1-master') x1,
     XMLTable ('/list-1-master/elem-1-master'
                   PASSING x1.l2_xml
                   COLUMNS master              VARCHAR2(100) PATH 'field-1-master',
                           l3_xml              XMLTYPE       PATH 'list-2-detail') x2,
     XMLTable ('/list-2-detail/elem-2-detail'
                   PASSING x2.l3_xml
                   COLUMNS detail              VARCHAR2(100) PATH 'field-2-detail') (+) x3
ORDER BY 1, 2, 3, 4
/
PROMPT Filtered, Outer Joins on detail only...
SELECT x1.global_id, x1.global_val, x2.master, x3.detail
  FROM xml_design_pattern t,
     XMLTable ('/elem-0-body'
                   PASSING t.xml_field
                   COLUMNS global_id           VARCHAR2(100) PATH 'elem-1-global/@attr-1-global',
                           global_val          VARCHAR2(100) PATH 'elem-1-global/field-1-global',
                           l2_xml              XMLTYPE       PATH 'list-1-master') x1,
     XMLTable ('/list-1-master/elem-1-master'
                   PASSING x1.l2_xml
                   COLUMNS master              VARCHAR2(100) PATH 'field-1-master',
                           l3_xml              XMLTYPE       PATH 'list-2-detail') x2,
     XMLTable ('/list-2-detail/elem-2-detail[field-2-detail != "val_detail_m2_d1"]'
                   PASSING x2.l3_xml
                   COLUMNS detail              VARCHAR2(100) PATH 'field-2-detail') (+) x3
ORDER BY 1, 2, 3, 4
/
@..\..\Brendan\sql\L_Log_Default

SPOOL OFF
