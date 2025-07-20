SET TRIMSPOOL ON
SET PAGES 10000
SET lines 1000
SET SERVEROUTPUT ON
SPOOL ..\lst\T_Cache_SA
SELECT 'Start: ' || To_Char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') FROM DUAL;
SET TIMING ON
BEGIN
  Utils.Clear_Log;
END;
/
DROP TABLE code_test
/
CREATE TABLE code_test (
        id                  INTEGER,
        code                VARCHAR2(60),
        num_same_type       INTEGER
)
/
VAR timer_Test_By_Code NUMBER;
BEGIN
  :timer_Test_By_Code := Timer_Set.Construct ('Test_By_Code');
END;
/
PROMPT Insert with non-cached funtion
TRUNCATE TABLE code_test
/
INSERT INTO code_test (
        id,
        code,
        num_same_type
)
SELECT	/*+ GATHER_PLAN_STATISTICS FNOC */
        id,
        code,
        Test_By_Code (code, :timer_Test_By_Code)
  FROM test_fvl
/
 
VAR timer_Test_By_Code_Cached NUMBER;
BEGIN
  :timer_Test_By_Code_Cached := Timer_Set.Construct ('Test_By_Code_Cached');
END;
/
PROMPT Insert with cached funtion
TRUNCATE TABLE code_test
/
INSERT INTO code_test (
        id,
        code,
        num_same_type
)
SELECT	/*+ GATHER_PLAN_STATISTICS FCAC */
        id,
        code,
        Test_By_Code_Cached (code, :timer_Test_By_Code_Cached)
  FROM test_fvl
/
 
BEGIN

  Timer_Set.Summary_Times;
  Utils.Write_Plan (p_sql_marker => 'FNOC');
  Utils.Write_Plan (p_sql_marker => 'FCAC');

END;
/
START ..\..\sql\L_Log_Default
SELECT 'End: ' || To_Char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') FROM DUAL;
SPOOL OFF
