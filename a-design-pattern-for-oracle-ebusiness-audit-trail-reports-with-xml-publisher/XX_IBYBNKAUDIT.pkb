REM Migrated from Wordpress July 2025
CREATE OR REPLACE PACKAGE BODY XX_IBYBNKAUDIT AS
/**************************************************************************************************

Author:		Brendan Furey, 1 September 2014
Description:	Package body for package for XML Publisher Bank Account Auditing report,
                XX_IBYBNKAUDIT, as described in:
                        'A Design Pattern for Oracle eBusiness Audit Trail Reports with XML Publisher'
                        http://aprogrammerwrites.eu/?p=1130

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

  Write_Log ('bpf debug, p_beg_dat = ' || p_beg_dat);
  Write_Log ('bpf debug, p_end_dat = ' || p_end_dat);

  IF p_beg_dat IS NOT NULL THEN
    lp_beg_dat := ' AND aup.audit_timestamp >= To_Date (''' || p_beg_dat || ''', ''DD-MON-YYYY'')';
  END IF;
  IF p_end_dat IS NOT NULL THEN
    lp_end_dat := ' AND aup.audit_timestamp <= To_Date (''' || p_end_dat || ''', ''DD-MON-YYYY'')';
  END IF;

  Write_Log ('bpf debug, lp_beg_dat = ' || lp_beg_dat);
  Write_Log ('bpf debug, lp_end_dat = ' || lp_end_dat);

  RETURN TRUE;

END BeforeReport;

FUNCTION AfterReport RETURN BOOLEAN IS
BEGIN

  Write_Log ('After Report for request id ' || FND_Global.Conc_Request_Id);
  Write_Log (' ', FALSE);
  Write_Log (RPad ('Supplier', 40) || ' ' || RPad ('Bank Sort Code', 40), FALSE);
  Write_Log (RPad ('=', 40, '=') || ' ' || RPad ('=', 40, '='), FALSE);
  RETURN TRUE;

END AfterReport;

FUNCTION HdrFilter (    p_vendor_name           VARCHAR2,
                        p_bank_num              VARCHAR2) RETURN BOOLEAN IS
BEGIN

  Write_Log (RPad (Nvl(p_vendor_name, '(none)'), 40) || ' ' || RPad (p_bank_num, 40), FALSE);

  RETURN TRUE;

END HdrFilter;

END XX_IBYBNKAUDIT;
/
SHO ERR
