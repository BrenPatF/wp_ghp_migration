#!/bin/ksh
# Author:	Brendan Furey, 28 September 2014
# Description:	A generic concurrent program uploader script, as described here:
#                        'A Generic Unix Script for Uploading Oracle eBusiness Concurrent Programs'
#                        http://aprogrammerwrites.eu/?p=1282
#
mv_files() {
        cp *ldt ../../import
        cp *xml ../../import
        cp *xsl ../../import
        cp *rtf ../../import
        cp *sql ../../install/sql
        cp *pks ../../install/sql
        cp *pkb ../../install/sql
}
process_params() {
#
# Assign input parameters and system values to variables
#
        pw=$1
        cp_name=$2
        app=$3
        jdbc=$4

        admin_dir=../../import
        sysdate=`date "+%Y/%m/%d"`
        rg_down_ldt=rg_down.ldt
        rg_up_ldt=rg_up.ldt
	rg_lis=${cp_name}_RG.lis
        echo $0 $sysdate
}
check_file() {
        if [ ! -s "$1"  ] ; then
                echo The $2 configuration file $1 does not exist !
                exit 1
        fi
}
make_rg_file() {
        echo FNDLOAD apps/pw 0 Y DOWNLOAD $lct_file $rg_down_ldt REQUEST_GROUP REQUEST_GROUP_NAME="$1" APPLICATION_SHORT_NAME=$2
        FNDLOAD apps/$pw 0 Y DOWNLOAD $lct_rg $rg_down_ldt REQUEST_GROUP REQUEST_GROUP_NAME="$1" APPLICATION_SHORT_NAME=$2
        rgu_line1=36
        (head -$rgu_line1 $rg_down_ldt ; echo '
  BEGIN REQUEST_GROUP_UNIT "P" "APPNAME" "REPNAME"
    OWNER = "ORACLE"
    LAST_UPDATE_DATE = "ph_sysdate"
  END REQUEST_GROUP_UNIT


END REQUEST_GROUP
') | sed "s:ph_sysdate:$sysdate:" | sed 's/REPNAME/'$3'/' | sed 's/APPNAME/'$4'/' > $rg_up_ldt

         echo Processing Request Group assignments for group "$1"

         echo FNDLOAD apps/pw 0 Y UPLOAD $lct_rg $rg_up_ldt
         FNDLOAD apps/$pw 0 Y UPLOAD $lct_rg $rg_up_ldt

}
validate() {
#
# ldt files...
#
        ldt_prog=$admin_dir/${cp_name}_CP.ldt
        ldt_dd=$admin_dir/${cp_name}_DD.ldt
        ldt_vs=$admin_dir/${cp_name}_VS.ldt # optional so do not check existence here
        ldt_ms=$admin_dir/${cp_name}_MS.ldt # optional so do not check existence here
        ldt_ag=$admin_dir/${cp_name}_AG.ldt # optional so do not check existence here

        check_file $ldt_prog "Program"
        check_file $ldt_dd "Data Definition"

        ldt_temp=${cp_name}_TP.ldt
#
# lct files...
#
        lct_prog=$FND_TOP/patch/115/import/afcpprog.lct
        lct_rg=$FND_TOP/patch/115/import/afcpreqg.lct
        lct_dd=$XDO_TOP/patch/115/import/xdotmpl.lct
	lct_vs=$FND_TOP/patch/115/import/afffload.lct
	lct_ms=$FND_TOP/patch/115/import/afmdmsg.lct
	lct_ag=$FND_TOP/patch/115/import/affaudit.lct

        check_file $lct_rg "Request Group"
        check_file $lct_prog "Program"
        check_file $lct_dd "Data Definition"
        check_file $lct_vs "Value Set"
        check_file $lct_ms "Message"
        check_file $lct_ag "Audit Group"
#
# Template files...
#
        xml_file=$admin_dir/${cp_name}.xml
        bur_file=$admin_dir/${cp_name}_BUR.xml # optional so do not check existence here

        check_file $xml_file "XML"

#
# Check the apps password
#
        ret=`sqlplus -s apps/$pw <<!!
!!`

        if [ -n "$ret" ] ; then
                echo Incorrect password for oracle user apps \(first parameter\)
                exit 1
        fi
#
# Check whether the definition file contains any Value Sets
#
        n_vs=`grep -c "BEGIN VALUE_SET" $ldt_prog`
        if [ ! $n_vs = 0 ] ; then
                echo Warning: File $ldt_prog contains $n_vs Value Set definitions. Is this wise...?
        fi
}
upload_ag() {
#
# Upload the audit groups...
#
        if test -f $ldt_ag; then
		sed "s:ph_sysdate:$sysdate:" $ldt_ag > $ldt_temp

		echo Uploading the Audit Groups from file $ldt_temp...
		FNDLOAD apps/$pw 0 Y UPLOAD $lct_ag $ldt_temp CUSTOM_MODE=FORCE -
#
# Report results from database
#
		sqlplus -s apps/$pw <<!!
		SET LINES 200
		COLUMN	"App G"	      	FORMAT A6
		COLUMN	"Group"		FORMAT A30
		COLUMN	"Description"	FORMAT A40
		COLUMN	"App T"	      	FORMAT A6
		COLUMN	"Table"		FORMAT A30
		COLUMN	"Column"	FORMAT A30
		BREAK ON "App G" ON "Group" ON "Description" ON "App T" ON "Table"
		SELECT app_g.application_short_name "App G", fag.group_name "Group", fag.description "Description",
		      app_t.application_short_name "App T", ftb.table_name "Table",
		      fcl.column_name "Column"
		  FROM fnd_audit_groups fag
		  JOIN fnd_application app_g
		    ON app_g.application_id = fag.application_id
		  JOIN fnd_audit_tables fat
		    ON fat.audit_group_app_id = fag.application_id
		   AND fat.audit_group_id = fag.audit_group_id
		  JOIN fnd_application app_t
		    ON app_t.application_id = fat.table_app_id
		  JOIN fnd_tables ftb
		    ON ftb.application_id = fat.table_app_id
		   AND ftb.table_id = fat.table_id
		  JOIN fnd_audit_columns fac
		    ON fac.table_app_id = fat.table_app_id
		   AND fac.table_id = fat.table_id
		  JOIN fnd_columns fcl
		    ON fcl.application_id = fac.table_app_id
		   AND fcl.table_id = fac.table_id
		   AND fcl.column_id = fac.column_id
		 WHERE fag.last_update_date	= To_Date ('$sysdate', 'YYYY/MM/DD')
		   AND fac.schema_id		= 900
		ORDER BY app_g.application_short_name, fag.group_name, 
			 app_t.application_short_name, ftb.table_name,
			 fcl.column_name;
		EXIT;
!!

		rm $ldt_temp
	else
		echo No Audit Groups to upload
        fi
}
upload_ms() {
#
# Upload the messages...
#
        if test -f $ldt_ms; then
		sed "s:ph_sysdate:$sysdate:" $ldt_ms > $ldt_temp

		echo Uploading the Messages from file $ldt_temp...
		FNDLOAD apps/$pw 0 Y UPLOAD $lct_ms $ldt_temp CUSTOM_MODE=FORCE -
#
# Report results from database
#
		sqlplus -s apps/$pw <<!!
		SET LINES 180
		COLUMN "Name"           FORMAT A20
		COLUMN "Text"           FORMAT A150
		BREAK ON "Code" ON "Lang" ON "Terr"

		PROMPT Messages...
		SELECT mes.message_name "Name", mes.message_text "Text"
		  FROM fnd_new_messages mes
		 WHERE mes.last_update_date	= To_Date ('$sysdate', 'YYYY/MM/DD')
		 ORDER BY 1;
		EXIT;
!!

		rm $ldt_temp
	else
		echo No messages to upload
        fi
}
upload_vs() {
#
# Upload the value sets...
#
        if test -f $ldt_vs; then
		sed "s:ph_sysdate:$sysdate:" $ldt_vs > $ldt_temp
		chmod +w $ldt_temp

		echo Uploading Value Set from file $ldt_temp...
		FNDLOAD apps/$pw 0 Y UPLOAD $lct_vs $ldt_temp CUSTOM_MODE=FORCE -
#
# Report results from database
#
		sqlplus -s apps/$pw <<!!
		COLUMN	"Value Set"	      	FORMAT A40
		COLUMN	"Values"		FORMAT 990
		SELECT fvs.flex_value_set_name "Value Set", Count(fvl.flex_value_set_id) "Values"
		  FROM fnd_flex_value_sets fvs, fnd_flex_values fvl
		 WHERE fvs.last_update_date	= To_Date ('$sysdate', 'YYYY/MM/DD')
		   AND fvl.flex_value_set_id(+)	= fvs.flex_value_set_id
		 GROUP BY fvs.flex_value_set_name;
		EXIT;
!!
	else
		echo No value sets to upload
        fi
}
upload_cp() {
#
# Upload the prog...
#
        sed "s:ph_sysdate:$sysdate:" $ldt_prog > $ldt_temp
        chmod +w $ldt_temp

        echo Processing Load file $ldt_temp...
        echo FNDLOAD apps/$pw 0 Y UPLOAD $lct_prog $ldt_temp -
        FNDLOAD apps/$pw 0 Y UPLOAD $lct_prog $ldt_temp CUSTOM_MODE=FORCE -
#
# Report results from database
#
        sqlplus -s apps/$pw <<!!
        SET LINES 120
        COLUMN  "Program"               FORMAT A80
        COLUMN  "Parameter"             FORMAT A30
        BREAK ON "Program"

        SELECT prg.user_concurrent_program_name || ': ' || prg.concurrent_program_name "Program", fcu.column_seq_num || ': ' || fcu.end_user_column_name "Parameter"
          FROM fnd_concurrent_programs_vl               prg
            LEFT JOIN fnd_descr_flex_column_usages      fcu
              ON fcu.descriptive_flexfield_name         = '\$SRS\$.' || prg.concurrent_program_name
             AND fcu.descriptive_flex_context_code      = 'Global Data Elements'
         WHERE prg.concurrent_program_name              = '$cp_name'
         ORDER BY 1, 2;
        EXIT;
!!
}
upload_rga() {
#
# Upload the Request Group assignments, creating the temporary RG configuration file from the relevant generic one
# substituting the prog name for the placeholder
#
        if ! test -f $rg_lis ; then
		return 0
	fi

echo reading $rg_lis
	while IFS=\| read rg_name rg_app
	do
		echo "Request group '$rg_name' in app $rg_app"
		make_rg_file "$rg_name" $rg_app $cp_name $app

                if [ -s "$bur_file"  ] ; then
                        echo $bur_file exists, so add bursting program to request group
                        make_rg_file "$rg_name" $rg_app XDOBURSTREP XDO
                fi

	done <$rg_lis
	rm $rg_up_ldt
	rm $rg_down_ldt
#
# Report results from database
#
        sqlplus -s apps/$pw <<!!
        SET LINES 120
        COLUMN  "Request Group"         FORMAT A30
        COLUMN  "App"			FORMAT A10

        SELECT rgp.request_group_name "Request Group",
               app.application_short_name "App"
          FROM fnd_concurrent_programs          cpr
          JOIN fnd_request_group_units          rgu
            ON rgu.unit_application_id          = cpr.application_id
           AND rgu.request_unit_id              = cpr.concurrent_program_id
          JOIN fnd_request_groups               rgp
            ON rgp.application_id               = rgu.application_id
           AND rgp.request_group_id             = rgu.request_group_id
          JOIN fnd_application                  app
            ON app.application_id               = rgp.application_id
         WHERE cpr.concurrent_program_name      = '$cp_name'
         ORDER BY 1;
	EXIT;
!!
}
upload_dd() {
#
# Upload the data definition...
#
        sed "s:ph_sysdate:$sysdate:" $ldt_dd > $ldt_temp

        echo Uploading the Data Definition "$2" from file $ldt_temp...
        FNDLOAD apps/$pw 0 Y UPLOAD $lct_dd $ldt_temp CUSTOM_MODE=FORCE -
#
# Report results from database
#
        sqlplus -s apps/$pw <<!!
        SET LINES 180
        COLUMN "Code"           FORMAT A20
        COLUMN "Lang"           FORMAT A4
        COLUMN "Terr"           FORMAT A4
        COLUMN "File"           FORMAT A35
        BREAK ON "Code" ON "Lang" ON "Terr"

        PROMPT Data Definitions...
        SELECT xdd.data_source_code "Code", xtm.default_language "Lang", xtm.default_territory "Terr"
          FROM xdo_ds_definitions_b xdd
          LEFT JOIN xdo_templates_b xtm
            ON xtm.application_short_name       = xdd.application_short_name
           AND xtm.data_source_code             = xdd.data_source_code
         WHERE xdd.data_source_code             = '$cp_name'
         ORDER BY 1, 2, 3;
        EXIT;
!!

        rm $ldt_temp
}
upload_template () {
#
# Upload an xml or xsl or rtf template
#
        java oracle.apps.xdo.oa.util.XDOLoader \
                UPLOAD \
                -DB_USERNAME apps \
                -DB_PASSWORD $pw \
                -JDBC_CONNECTION $jdbc \
                -LOB_TYPE $1 \
                -APPS_SHORT_NAME $app \
                -LOB_CODE $4 \
                -LANGUAGE en \
                -TERRITORY US \
                -NLS_LANG American_America.WE8ISO8859P1 \
                -XDO_FILE_TYPE $2 \
                -FILE_NAME $3 \
                -CUSTOM_MODE FORCE
}
upload_all_temps() {
#
# Upload the xml and rtf templates...
#
        upload_template DATA_TEMPLATE XML $xml_file $cp_name
	for rtf in `ls -1 *rtf`; do
		echo Uploading layout $rtf
		stem=`echo $rtf|cut -d. -f1`
		upload_template TEMPLATE RTF $rtf $stem
	done
        for xsl in `ls -1 *xsl`; do
                echo Uploading layout $xsl
                stem=`echo $xsl|cut -d. -f1`
                upload_template TEMPLATE XSL-XML $xsl $stem
        done
        if test -f $bur_file; then
		echo Bursting file name is $bur_file
                upload_template BURSTING_FILE XML $bur_file $cp_name
	else
		echo No bursting file to upload
        fi
#
# Report results from database
#
        sqlplus -s apps/$pw <<!!
        SET LINES 180
        COLUMN "Code"           FORMAT A20
        COLUMN "Data Template"  FORMAT A20
        COLUMN "Bursting File"  FORMAT A25
        COLUMN "Template"       FORMAT A20
        COLUMN "Lang"           FORMAT A4
        COLUMN "Terr"           FORMAT A4
        COLUMN "File"           FORMAT A25
        BREAK ON "Code" ON "Data Template" ON "Bursting File" ON "Template" ON "Lang" ON "Terr"

        PROMPT Templates and Files...
        SELECT xdd.data_source_code "Code", 
		xlb_d.file_name "Data Template",
		xlb_b.file_name "Bursting File",
		xtm.template_code "Template",
		xlb.language "Lang", 
		xlb.territory "Terr",
		xlb.file_name || 
		       CASE
		       WHEN xlb.language = xtm.default_language AND
			    xlb.territory = xtm.default_territory
		       THEN '*' END "File"
          FROM xdo_ds_definitions_b		xdd
	  LEFT JOIN xdo_lobs			xlb_d
	    ON xlb_d.application_short_name	= xdd.application_short_name
	   AND xlb_d.lob_code			= xdd.data_source_code
	   AND xlb_d.lob_type			= 'DATA_TEMPLATE'
	  LEFT JOIN xdo_lobs			xlb_b
	    ON xlb_b.application_short_name	= xdd.application_short_name
	   AND xlb_b.lob_code			= xdd.data_source_code
	   AND xlb_b.lob_type			= 'BURSTING_FILE'
	  LEFT JOIN xdo_templates_b		xtm
	    ON xtm.application_short_name	= xdd.application_short_name
	   AND xtm.data_source_code		= xdd.data_source_code
	  LEFT JOIN xdo_lobs			xlb
	    ON xlb.application_short_name	= xtm.application_short_name
	   AND xlb.lob_code			= xtm.template_code
	   AND xlb.lob_type			LIKE 'TEMPLATE%'
         WHERE xdd.data_source_code             = '$cp_name'
	   AND xdd.application_short_name	= '$app'
         ORDER BY 1, 2, 3, 4;
        EXIT;
!!
}
run_sql() {
        if test -f $1; then
                echo SQL install file is $1
                sqlplus -s apps/$pw <<!!
                @$1
                EXIT;
!!
        else
                echo No $1 to install
        fi
}
install_pkg() {
#
# Run the .pks and .pkb for ${cp_name}...
#
        sql="../../install/sql/${cp_name}.sql"
        pks="../../install/sql/${cp_name}.pks"
        pkb="../../install/sql/${cp_name}.pkb"

        run_sql $sql
        run_sql $pks
        run_sql $pkb
}
#
# Main program starts here, checking input parameters first, then calling subroutines
#	This is run from $XX_TOP/rel
#
if [ $# != 4 ] ; then
        echo Usage: $0 [apps password] [program short name] [app short name] [JDBC connection string \(HOST:PORT:SID - HOST can be name or IP address\)]
        exit 1
fi
#
# Redirect standard and error output to log file, and process input parameters
#
echo Log is being written to $2.log ...
exec 1>$2.log
exec 2>$2.err
process_params $1 $2 $3 $4
#
# Untar the source file and move the files to the main application installation directories
#
tar -xvf ${cp_name}.tar
cd ${cp_name}
mv_files
#
# Validate the files and parameters passed, then upload the apps metadata, templates, package
#
validate
upload_ag
upload_ms
upload_vs
upload_cp
upload_rga
upload_dd
upload_all_temps
install_pkg
#
# Installation done, now write the standard logs into the main log
#
echo "The Oracle Loader logs (in directory $2) contain..."
#for file in `grep Log ../$2.err|cut -d" " -f4`; do
for file in `ls -1 L*.log`; do
	echo "***"
	echo $file
	echo "***"
	cat $file
done
