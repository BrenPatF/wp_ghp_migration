REM Author:	  Brendan Furey, 20 September 2014
REM Description:  View creation script for XML Publisher report: XX Example XML CP (Printed/Email),
REM               XX_ERPXMLCP, XX_ERPXMLCP_EM, as described in:
REM                        'Design Patterns for Database Reports with XML Publisher and Email Bursting'
REM                        http://aprogrammerwrites.eu/?p=1181 -->

DROP VIEW example_headers_v
/
CREATE VIEW example_headers_v (
	pk1_num,
	pk2_num,
	uk2_chr,
	uk3_chr,
	col1_chr,
	col2_chr,
	col3_chr,
	col4_chr,
	col5_chr,
	col4_dat,
	col6_chr,
	col7_chr
) AS
SELECT fcp.application_id,
       fcp.concurrent_program_id,
       fcp.concurrent_program_name,
       app.application_short_name,
       app.application_name,
       fcp.user_concurrent_program_name,
       fex.execution_file_name,
       CASE fex.execution_method_code
	      WHEN 'A' THEN 'Spawned'
	      WHEN 'E' THEN 'Perl Concurrent Program'
	      WHEN 'H' THEN 'Host'
	      WHEN 'I' THEN 'PL/SQL Stored Procedure'
	      WHEN 'J' THEN 'Java Stored Procedure'
	      WHEN 'K' THEN 'Java Concurrent Program'
	      WHEN 'L' THEN 'SQL*Loader'
	      WHEN 'P' THEN 'Oracle Reports'
	      WHEN 'Q' THEN 'SQL*Plus'
	      WHEN 'S' THEN 'Immediate'
	      ELSE fex.execution_method_code
       END,
       fcp.output_file_type,
       fcp.creation_date,
       xlb_d.file_name	data_template,
       xlb_b.file_name	bursting_file
  FROM fnd_concurrent_programs_vl		fcp
  JOIN fnd_application_vl			app
    ON app.application_id			= fcp.application_id
  JOIN fnd_executables				fex
    ON fex.executable_id			= fcp.executable_id
   AND fex.application_id			= fcp.executable_application_id
  LEFT JOIN xdo_ds_definitions_b		xdd
    ON xdd.application_short_name		= app.application_short_name
   AND xdd.data_source_code			= fcp.concurrent_program_name
  LEFT JOIN xdo_lobs				xlb_d
    ON xlb_d.application_short_name		= xdd.application_short_name
   AND xlb_d.lob_code				= xdd.data_source_code
   AND xlb_d.lob_type				= 'DATA_TEMPLATE'
  LEFT JOIN xdo_lobs				xlb_b
    ON xlb_b.application_short_name		= xdd.application_short_name
   AND xlb_b.lob_code				= xdd.data_source_code
   AND xlb_b.lob_type				= 'BURSTING_FILE'
/
DROP VIEW example_lines_one_v
/
CREATE VIEW example_lines_one_v (
	fk1_num,
	fk2_chr,
	col1_num,
	col2_chr,
	col3_chr,
	col4_chr
) AS
SELECT fcu.application_id,
       fcu.descriptive_flexfield_name,
       fcu.column_seq_num, 
       fcu.end_user_column_name, 
       fcu.default_value, 
       fvs.flex_value_set_name
  FROM fnd_descr_flex_column_usages		fcu
  JOIN fnd_flex_value_sets			fvs
    ON fvs.flex_value_set_id 			= fcu.flex_value_set_id
 WHERE fcu.descriptive_flex_context_code	= 'Global Data Elements'
/
DROP VIEW example_lines_two_v
/
CREATE VIEW example_lines_two_v (
	fk1_num,
	fk2_num,
	col1_chr,
	col2_chr
) AS
SELECT rgu.unit_application_id,
       rgu.request_unit_id,
       app.application_name,
       rgp.request_group_name
  FROM fnd_request_group_units			rgu
  JOIN fnd_request_groups			rgp
    ON rgp.application_id 			= rgu.application_id
   AND rgp.request_group_id			= rgu.request_group_id
  JOIN fnd_application_vl			app
    ON app.application_id			= rgu.application_id
/
DROP VIEW example_lines_three_v
/
CREATE VIEW example_lines_three_v (
	fk1_chr,
	fk2_chr,
	col1_chr,
	col2_chr,
	col3_chr,
	col4_chr
) AS
SELECT xtm.application_short_name,
       xtm.data_source_code,
       xtm.template_code,
       xlb.language,
       xlb.territory,
       xlb.file_name || 
               CASE
	       WHEN xlb.language = xtm.default_language AND
	            xlb.territory = xtm.default_territory
	       THEN '*' END file_name
  FROM xdo_templates_b				xtm
  LEFT JOIN xdo_lobs				xlb
    ON xlb.application_short_name		= xtm.application_short_name
   AND xlb.lob_code				= xtm.template_code
 WHERE xlb.lob_type				= 'TEMPLATE_SOURCE'
/

