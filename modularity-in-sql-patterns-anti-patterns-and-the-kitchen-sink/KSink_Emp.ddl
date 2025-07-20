SET TRIMSPOOL ON
SET LINES 400
SET PAGES 1000
SET VERIFY OFF
SET ECHO OFF
SPOOL ..\lst\KSink_Emp_DDL
CREATE OR REPLACE VIEW emp_ks_v (
       employee_id,
       name,
       job_title,
       job_title_p,
       name_mgr,
       job_title_mgr,
       job_title_mgr_p,
       n_sub,
       department_id,
       department_name,
       name_d_mgr,
       street_address,
       country_name,
       region_name) AS
WITH jhs_f AS (
SELECT employee_id,
     Max (job_id) KEEP (DENSE_RANK LAST ORDER BY end_date) job_id
  FROM hr.job_history
 GROUP BY employee_id
), sub AS (
SELECT manager_id,
       Count(*)                  n_sub
  FROM hr.employees
 GROUP BY manager_id
)
SELECT emp.employee_id,
       emp.last_name || ', ' || emp.first_name,
       job.job_title,
       job_p.job_title,
       emp_m.last_name || ', ' || emp_m.first_name,
       job_m.job_title,
       job_mp.job_title,
       sub.n_sub,
       dep.department_id,
       dep.department_name,
       emp_dm.last_name || ', ' || emp_dm.first_name,
       loc.street_address,
       cou.country_name,
       reg.region_name
  FROM hr.employees              emp
  JOIN hr.jobs                   job
    ON job.job_id                = emp.job_id
  LEFT JOIN jhs_f                jhs
    ON jhs.employee_id           = emp.employee_id
  LEFT JOIN hr.jobs              job_p
    ON job_p.job_id              = jhs.job_id
  LEFT JOIN hr.employees         emp_m
    ON emp_m.employee_id         = emp.manager_id
  LEFT JOIN hr.jobs              job_m
    ON job_m.job_id              = emp_m.job_id
  LEFT JOIN jhs_f                jhs_m
    ON jhs_m.employee_id         = emp.employee_id
  LEFT JOIN hr.jobs              job_mp
    ON job_mp.job_id             = jhs_m.job_id
  LEFT JOIN sub
    ON sub.manager_id            = emp.employee_id
  LEFT JOIN hr.departments       dep
    ON dep.department_id         = emp.department_id
  LEFT JOIN hr.employees         emp_dm
    ON emp_dm.employee_id        = dep.manager_id
  LEFT JOIN hr.locations         loc
    ON loc.location_id           = dep.location_id
  LEFT JOIN hr.countries         cou
    ON cou.country_id            = loc.country_id
  LEFT JOIN hr.regions           reg
    ON reg.region_id             = cou.region_id;
/
DROP TYPE emp_info_list_type;
CREATE OR REPLACE TYPE emp_info_type IS OBJECT (
              employee_id          NUMBER,
              name                 VARCHAR2(50),
              job_title            VARCHAR2(35),
              job_title_p          VARCHAR2(35),
              name_mgr             VARCHAR2(50),
              job_title_mgr        VARCHAR2(35),
              job_title_mgr_p      VARCHAR2(35),
              n_sub                NUMBER,
              department_name      VARCHAR2(30),
              name_d_mgr           VARCHAR2(20),
              street_address       VARCHAR2(40),
              country_name         VARCHAR2(40),
              region_name          VARCHAR2(25)
)
/
SHO ERR
CREATE TYPE emp_info_list_type IS TABLE OF emp_info_type;
/
SPOOL OFF