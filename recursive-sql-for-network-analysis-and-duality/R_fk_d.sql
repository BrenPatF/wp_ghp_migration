SET TRIMSPOOL ON
SET SERVEROUTPUT ON
SPOOL ..\lst\R_fk_d

@..\sql\Fmt_Fk_d
@..\sql\fk_v_d
@..\sql\net_rep_fk_d

SET TIMING OFF
SPOOL OFF