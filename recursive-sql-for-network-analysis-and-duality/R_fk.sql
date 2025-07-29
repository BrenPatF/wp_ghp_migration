SET TRIMSPOOL ON
SET SERVEROUTPUT ON
SPOOL ..\lst\R_fk

@..\sql\Fmt_Fk
@..\sql\fk_v
@..\sql\net_rep_fk

SET TIMING OFF
SPOOL OFF