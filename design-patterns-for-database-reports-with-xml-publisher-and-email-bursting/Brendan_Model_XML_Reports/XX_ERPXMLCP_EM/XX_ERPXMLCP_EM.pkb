CREATE OR REPLACE PACKAGE BODY XX_ERPXMLCP_EM AS
/**************************************************************************************************

Author:		Brendan Furey, 20 September 2014
Description:	Package body for package for XML Publisher report: XX Example XML CP (Email),
                XX_ERPXMLCP_EM, as described in:
                        'Design Patterns for Database Reports with XML Publisher and Email Bursting'
                        http://aprogrammerwrites.eu/?p=1181

Functions
=========
BeforeReport    Called from Before Report trigger to set lexical parameters based on inputs
AfterReport     Called from After Report trigger to write headings to log file
HdrFilter       Called from main Group trigger to write record level values to log file

***************************************************************************************************/

FUNCTION Get_Timestamp RETURN VARCHAR2 AS
BEGIN
    RETURN To_Char (SYSDATE, 'DD-MON-YYYY HH24:MI:SS');
END Get_Timestamp;

PROCEDURE Write_Log (p_message VARCHAR2, p_add_time BOOLEAN DEFAULT TRUE) AS
  l_time_str VARCHAR2(100);
BEGIN

  IF p_add_time THEN
    l_time_str := Get_Timestamp || ' ';
  END IF;

  IF FND_Global.Conc_Request_Id > 0 THEN
      FND_File.Put_Line (FND_File.LOG, l_time_str || p_message);
  ELSE
      DBMS_Output.Put_Line (l_time_str || p_message);
  END IF;

END Write_Log;

FUNCTION BeforeReport RETURN BOOLEAN IS
BEGIN

  Write_Log ('bpf debug, p_beg_chr = ' || p_app_id);
  Write_Log ('bpf debug, p_beg_chr = ' || p_beg_chr);
  Write_Log ('bpf debug, p_end_chr = ' || p_end_chr);
  Write_Log ('bpf debug, p_beg_dat = ' || p_beg_dat);
  Write_Log ('bpf debug, p_end_dat = ' || p_end_dat);
  Write_Log ('bpf debug, p_beg_num = ' || p_beg_num);
  Write_Log ('bpf debug, p_end_num = ' || p_end_num);

  IF p_app_id IS NOT NULL THEN
    lp_app_id := ' AND prg.pk1_num = ' || p_app_id;
  END IF;

  IF p_beg_chr IS NOT NULL THEN
    lp_beg_chr := ' AND prg.col2_chr >= ''' || p_beg_chr || '''';
  END IF;
  IF p_end_chr IS NOT NULL THEN
    lp_end_chr := ' AND prg.col2_chr <= ''' || p_end_chr || '''';
  END IF;

  IF p_beg_dat IS NOT NULL THEN
    lp_beg_dat := ' AND prg.col4_dat >= To_Date (''' || p_beg_dat || ''', ''DD-MON-YYYY'')';
  END IF;
  IF p_end_dat IS NOT NULL THEN
    lp_end_dat := ' AND prg.col4_dat <=  To_Date (''' || p_end_dat || ' 23:59:59'', ''DD-MON-YYYY hh24:mi:ss'')';
  END IF;

  IF p_beg_num IS NOT NULL THEN
    lp_beg_num := ' AND prm.n_lin >= ' || p_beg_num;
  END IF;
  IF p_end_num IS NOT NULL THEN
    lp_end_num := ' AND prm.n_lin <= ' || p_end_num;
  END IF;

  Write_Log ('bpf debug, lp_app_id = ' || lp_app_id);
  Write_Log ('bpf debug, lp_beg_chr = ' || lp_beg_chr);
  Write_Log ('bpf debug, lp_end_chr = ' || lp_end_chr);
  Write_Log ('bpf debug, lp_beg_dat = ' || lp_beg_dat);
  Write_Log ('bpf debug, lp_end_dat = ' || lp_end_dat);
  Write_Log ('bpf debug, lp_beg_num = ' || lp_beg_num);
  Write_Log ('bpf debug, lp_end_num = ' || lp_end_num);

  RETURN TRUE;

END BeforeReport;

FUNCTION HdrFilter (    p_email_address         VARCHAR2,
                        p_col_hdr_1             VARCHAR2,
                        p_col_hdr_2             VARCHAR2,
                        p_lin_count             PLS_INTEGER,
                        p_lin_2_count           PLS_INTEGER) RETURN BOOLEAN IS
BEGIN

  Write_Log (RPad (p_email_address, 30) || ' ' || RPad (p_col_hdr_1, 20) || ' ' || RPad (p_col_hdr_2, 20) || ' ' || LPad (p_lin_count, 10) || ' ' || LPad (p_lin_2_count, 10), FALSE);

  RETURN TRUE;

END HdrFilter;

FUNCTION AfterReport RETURN BOOLEAN IS
BEGIN

  Write_Log ('After Report for request id ' || FND_Global.Conc_Request_Id);
  Write_Log (' ', FALSE);
  IF p_over_email IS NOT NULL THEN

    Write_Log ('*** Email addresses below will be replaced by the override address ' || p_over_email || ' ***', FALSE);
    Write_Log (' ', FALSE);

  END IF;
  Write_Log (RPad ('Email', 30) || ' ' || RPad ('App', 20) || ' ' || RPad ('Program', 20) || ' ' || LPad ('# params', 10) || ' ' || LPad ('# groups', 10), FALSE);
  Write_Log (RPad ('=', 30, '=') || ' ' || RPad ('=', 20, '=') || ' ' || RPad ('=', 20, '=') || ' ' || LPad ('=', 10, '=') || ' ' || LPad ('=', 10, '='), FALSE);
  RETURN TRUE;

END AfterReport;

END XX_ERPXMLCP_EM;
/
SHO ERR
