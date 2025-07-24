REM Migrated from Wordpress July 2025
CREATE OR REPLACE PACKAGE XX_IBYBNKAUDIT AS
/**************************************************************************************************

Author:		Brendan Furey, 1 September 2014
Description:	Package spec for package for XML Publisher Bank Account Auditing report,
                XX_IBYBNKAUDIT, as described in:
                        'A Design Pattern for Oracle eBusiness Audit Trail Reports with XML Publisher'
                        http://aprogrammerwrites.eu/?p=1130

Functions
=========
BeforeReport    Called from Before Report trigger to set lexical parameters based on inputs
AfterReport     Called from After Report trigger to write headings to log file
HdrFilter       Called from main Group trigger to write record level values to log file

***************************************************************************************************/

lp_beg_dat                      VARCHAR2(200) := ' AND 1=1';
lp_end_dat                      VARCHAR2(200) := ' AND 1=1';

p_beg_dat                       VARCHAR2(20);
p_end_dat                       VARCHAR2(20);

p_conc_request_id               PLS_INTEGER;

FUNCTION BeforeReport RETURN BOOLEAN;
FUNCTION AfterReport RETURN BOOLEAN;
FUNCTION HdrFilter (    p_vendor_name           VARCHAR2,
                        p_bank_num              VARCHAR2) RETURN BOOLEAN;

END XX_IBYBNKAUDIT;
/
SHO ERR
