SET TRIMSPOOL ON
SET PAGES 10000
SET lines 1000
SET SERVEROUTPUT ON
SPOOL ..\lst\T_Emp_Client
SELECT 'Start: ' || To_Char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') FROM DUAL;
SET TIMING ON
BEGIN
  Utils.Clear_Log;
END;
/
PROMPT Inline views: Employees with name, job, prior job; ditto for manager; # subordinates
SELECT emp.last_name || ', ' || emp.first_name name,
       job.job_title,
       job_p.job_title             job_title_prior,
       emp_m.last_name || ', ' || emp_m.first_name name_mgr,
       job_m.job_title             job_title_mgr,
       job_pm.job_title            job_title_mgr_prior,
       sub.n_sub
  FROM hr.employees                emp
  JOIN hr.jobs                     job
    ON job.job_id                  = emp.job_id
  LEFT JOIN (SELECT employee_id,
                    Max (job_id) KEEP (DENSE_RANK LAST ORDER BY end_date) job_id
               FROM hr.job_history
              GROUP BY employee_id
            )                      jhs
    ON jhs.employee_id             = emp.employee_id
  LEFT JOIN hr.jobs                job_p
    ON job_p.job_id                = jhs.job_id
  LEFT JOIN hr.employees           emp_m
    ON emp_m.employee_id           = emp.manager_id
  LEFT JOIN hr.jobs                job_m
    ON job_m.job_id                = emp_m.job_id
  LEFT JOIN (SELECT employee_id,
                    Max (job_id) KEEP (DENSE_RANK LAST ORDER BY end_date) job_id
               FROM hr.job_history
              GROUP BY employee_id
            )                      jhs_m
    ON jhs_m.employee_id           = emp.manager_id
  LEFT JOIN hr.jobs                job_pm
    ON job_pm.job_id               = jhs_m.job_id
  LEFT JOIN (SELECT manager_id,
                    Count(*)       n_sub
               FROM hr.employees
              GROUP BY manager_id
            )                      sub
    ON sub.manager_id              = emp.employee_id
 WHERE emp.department_id           = 30
 ORDER BY 1
/
L
PROMPT Subquery factors: Employees with name, job, prior job; ditto for manager; # subordinates
WITH jhs_f AS (
SELECT employee_id,
       Max (job_id) KEEP (DENSE_RANK LAST ORDER BY end_date) job_id
  FROM hr.job_history
 GROUP BY employee_id
), sub_f AS (
SELECT manager_id,
       Count(*)                    n_sub
  FROM hr.employees
 GROUP BY manager_id
)
SELECT emp.last_name || ', ' || emp.first_name name,
       job.job_title,
       job_p.job_title             job_title_prior,
       emp_m.last_name || ', ' || emp_m.first_name name_mgr,
       job_m.job_title             job_title_mgr,
       job_pm.job_title            job_title_mgr_prior,
       sub.n_sub
  FROM hr.employees                emp
  JOIN hr.jobs                     job
    ON job.job_id                  = emp.job_id
  LEFT JOIN jhs_f                  jhs
    ON jhs.employee_id             = emp.employee_id
  LEFT JOIN hr.jobs                job_p
    ON job_p.job_id                = jhs.job_id
  LEFT JOIN hr.employees           emp_m
    ON emp_m.employee_id           = emp.manager_id
  LEFT JOIN hr.jobs                job_m
    ON job_m.job_id                = emp_m.job_id
  LEFT JOIN jhs_f                  jhs_m
    ON jhs_m.employee_id           = emp.employee_id
  LEFT JOIN hr.jobs                job_pm
    ON job_pm.job_id               = jhs_m.job_id
  LEFT JOIN sub_f                  sub
    ON sub.manager_id              = emp.employee_id
 WHERE emp.department_id           = 30
 ORDER BY 1
/
L
DECLARE

  TYPE name_rec_type      IS RECORD (name VARCHAR2(50), name_mgr VARCHAR2(50), name_sub VARCHAR2(50));

  l_name_rec              name_rec_type;
  l_emp_mgr_sub_cur       SYS_REFCURSOR;
  l_dept_id               NUMBER := 30;
  l_count                 PLS_INTEGER := 0;

  PROCEDURE Write_Rec (p_name_rec name_rec_type) IS
  BEGIN

    DBMS_Output.Put_Line (
            RPad (p_name_rec.name, 40) ||
            RPad (p_name_rec.name_mgr, 40) ||
            RPad (LTrim (p_name_rec.name_sub, ','), 40)
    );

  END Write_Rec;

  PROCEDURE Write_Cursor (p_hdr VARCHAR2, p_emp_mgr_sub_cur SYS_REFCURSOR) IS
    l_count   PLS_INTEGER := 0;
  BEGIN

    DBMS_Output.Put_Line ('Output for ' || p_hdr || '...');
    LOOP

      FETCH p_emp_mgr_sub_cur
       INTO l_name_rec;
      EXIT WHEN p_emp_mgr_sub_cur%NOTFOUND;
      l_count := l_count + 1;
      Write_Rec (l_name_rec);

    END LOOP;
    CLOSE p_emp_mgr_sub_cur;
    DBMS_Output.Put_Line (l_count || ' rows written for ' || p_hdr);

  END Write_Cursor;

BEGIN

  Emp_Client.Get_Mgr_Subs_KS (l_dept_id, l_emp_mgr_sub_cur);
  Write_Cursor ('Employees for department id ' || l_dept_id || ' via Kitchen Sink', l_emp_mgr_sub_cur);

  Emp_Client.Get_Mgr_Subs_SQL (l_dept_id, l_emp_mgr_sub_cur);
  Write_Cursor ('Employees for department id ' || l_dept_id || ' via plain SQL', l_emp_mgr_sub_cur);

END;
/
PROMPT Employees for department id 30 via Kitchen Sink view
SELECT /*+ GATHER_PLAN_STATISTICS XCLIVW */
       t.name,
       t.name_mgr,
       CASE WHEN e.last_name IS NOT NULL THEN e.last_name || ', ' || e.first_name END name_sub
  FROM emp_ks_v t
  LEFT JOIN hr.employees e
    ON e.manager_id = t.employee_id
 WHERE t.department_id = 30
 ORDER BY 1, 2, 3
/
EXEC Utils.Write_Plan (p_sql_marker => 'XCLIVW');

START ..\..\Brendan\sql\L_Log_Default
SELECT 'End: ' || To_Char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') FROM DUAL;
SPOOL OFF
