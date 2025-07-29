SET TRIMSPOOL ON
SPOOL ..\lst\R_sml_d

@..\sql\Fmt_Sml_d
@..\sql\sml_v_d
@..\sql\net_rep_sml_d

SET TIMING OFF
SPOOL OFF