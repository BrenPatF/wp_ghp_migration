CREATE OR REPLACE PACKAGE XX_ERPXMLCP_EM AS
/**************************************************************************************************

Author:		Brendan Furey, 20 September 2014
Description:	Package spec for package for XML Publisher report: XX Example XML CP (Email),
                XX_ERPXMLCP_EM, as described in:
                        'Design Patterns for Database Reports with XML Publisher and Email Bursting'
                        http://aprogrammerwrites.eu/?p=1181

Functions
=========
BeforeReport    Called from Before Report trigger to set lexical parameters based on inputs
AfterReport     Called from After Report trigger to write headings to log file
HdrFilter       Called from main Group trigger to write record level values to log file

***************************************************************************************************/

lp_app_id                       VARCHAR2(200) := ' AND 1=1';
lp_beg_chr                      VARCHAR2(200) := ' AND 1=1';
lp_end_chr                      VARCHAR2(200) := ' AND 1=1';
lp_beg_dat                      VARCHAR2(200) := ' AND 1=1';
lp_end_dat                      VARCHAR2(200) := ' AND 1=1';
lp_beg_num                      VARCHAR2(200) := ' AND 1=1';
lp_end_num                      VARCHAR2(200) := ' AND 1=1';

p_app_id                        NUMBER;
p_beg_chr                       VARCHAR2(200);
p_end_chr                       VARCHAR2(200);
p_beg_dat                       VARCHAR2(11);
p_end_dat                       VARCHAR2(11);
p_beg_num                       NUMBER;
p_end_num                       NUMBER;
p_over_email                    VARCHAR2(200);
p_from_email                    VARCHAR2(200);
p_cc_email                      VARCHAR2(200);

p_conc_request_id               PLS_INTEGER;

FUNCTION BeforeReport RETURN BOOLEAN;
FUNCTION HdrFilter (    p_email_address         VARCHAR2,
                        p_col_hdr_1             VARCHAR2,
                        p_col_hdr_2             VARCHAR2,
                        p_lin_count             PLS_INTEGER,
                        p_lin_2_count           PLS_INTEGER) RETURN BOOLEAN;
FUNCTION AfterReport RETURN BOOLEAN;

END XX_ERPXMLCP_EM;
/
SHO ERR
