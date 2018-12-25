#/bin/bash
#############################################################
# Author :                                                 ##
# Company : xxxxxxxxxxxxxxxxxxx                            ##
# Description :                                            ##
#############################################################

##
## Set Global Variables
##
OS_TYPE=""
OS_TYPE_STATUS=""
DBNAME=""
DBMODE=""
DBROLE=""
DATE_TIME=`date +%d_%m_%Y`
DDATE_TIME=`date +%d-%m-%Y`
DBSRV_TIME=`date +%a_%H_%M_%S`
#DBHC_DIR=`echo $HOME`"/DBHC/DBHC-"`hostname``echo $DDATE_TIME`
RAC_LOG_FILE=""
#LOG_DEST_DIR=`echo $DBHC_DIR`
OS_LOG_FILE=""
DB_ALERT_LOG=""
SCRIPT_RUN=""
ORA_INSTANCE=""
OS_CHOICE=""
OS_PLATFORM=""
RAC_CHOICE=""
DBHC_BASE=`echo $HOME`"/DBHC"
DBHC_DIR=`echo $HOME`"/DBHC/DBHC-"`hostname`"-"`echo $DDATE_TIME`
LOG_DEST_DIR=`echo $DBHC_DIR`
CLIENT_NAME=""
CLIENT_DBTYPE=""
ADDM_TNAME="DBHC_$DATE_TIME"
ADDM_TDESC="ADDM for DBHC $DATE_TIME"



_banner(){
             if [ -z "$1" -a "$1" == " " ]
                then
                       echo "########################################################"
                       echo "########################################################"
                else
                       echo "########################################################"
                       echo " $1 "
                       echo "########################################################"
        fi
}

_printNewline(){
        echo -e "\n"
}

_dashBanner(){
        if [ -z "$1" -a "$1" == " " ]
           then
                echo "-----------------------------------------------------------"
        else
                echo "-----------------[ $1 ]------------------"
        fi
}


_errorReport(){
       echo "########################################################"
       echo "Error during Running Scripts"
       echo "Error: $1 "
       echo "########################################################"
       exit 1
}


##
## Function to dispaly Informative message.
##

infoReport(){
       echo "########################################################"
       echo "INFO : $1"
       echo "INFO : $2" 
       echo "########################################################"
}

##
## Function to dispaly Key Value
##

keyValueReport(){
       echo "----------"
       echo -e "INFO : $1 :: $2"
       echo "----------"
}



##
## Function to check if any specific value exists in array
##

checkSidValid(){
	param1=("${!1}")
	check=${2}  
	statusSID=0
	for i in ${param1[@]}
		do
			if [ ${i} == $2 ];
				then
				statusSID=1
				break
			esle
                echo $i; 
			fi 
        done
    return $statusSID;
}

##
## Function to verify the correct O/S selection
##
checkValidOS(){
        inputOS=${1} 
	actualOS=`uname`
		case "$inputOS" in
		        'AIX')
				if [ "$actualOS" = "AIX" ];
				then
				OS_TYPE_STATUS=VALID
				else
				OS_TYPE_STATUS=1
				fi
		        ;;
		        'HP')
				if [ "$actualOS" = "HP" ];
				then
				OS_TYPE_STATUS=VALID
				else
				OS_TYPE_STATUS=1
				fi
		        ;;
		        'LX')
				if [ "$actualOS" = "Linux" ];
				then
				OS_TYPE_STATUS=VALID
				else
				OS_TYPE_STATUS=1
				fi
		        ;;
		        'SL')
				if [ "$actualOS" = "SunOS" ];
				then
				OS_TYPE_STATUS=VALID
				else
				OS_TYPE_STATUS=1
				fi
		        ;;
		esac
}

##
## Get the cluster name and generate cluster logfilename
##
setClusterLogfile(){
RAC_LOG_FILE=`$1/bin/cemutlo -n`
RAC_LOG_FILE=`echo $RAC_LOG_FILE`_racinfo_$DATE_TIME.log
}

##
## Get the Database name, Open Mode and Database Role
##
getDBname(){
DBNAME=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select name from v\$database;
END
)
}

getDBmode(){
DBMODE=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select open_mode from v\$database;
END
)
}

getDBrole(){
DBROLE=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select database_role from v\$database;
END
)
}

##
## Get the database alert log destination
##
getDBalertLog(){
DB_ALERT_LOG=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select value from v\$parameter where name like'background_dump_dest';
END
)
}


##
## For Warning and Text manupulation
##
bold=$(tput bold)
reset=$(tput sgr0)
bell=$(tput bel)
underline=$(tput smul)


##
## Create necessary directories for storing DBHC logs
##
#mkdir -p $DBHC_DIR
#if [ $? -ne 0 ] ; then
#    _errorReport "DBHC directory cannot be created. Aborting...."
#fi


##
## Creating Variables and storing Queries
##


##
## Prepare Fomatting cmds
##
read -d '' formatCmd << EOF
set linesize 200
set pages 100
column name format a50
column comp_name format a50
column member format a60
COLUMN FILE_NAME FORMAT A60
COLUMN TABLESPACE_NAME FORMAT A30
column platform_name format a30
EOF


##
## Prepare Document end info
## 
read -d '' styleEndCmd << EOF
prompt </body></html>
EOF


##
## Prepare Heading Info for Report
##
read -d '' dbhcHeadingCmd << EOF
prompt <h2>Database Health Checkup Report</h2>
prompt <table border="1" style=" margin: auto; width: 50%;">
prompt <tbody>
prompt <tr><th style="padding: 5px;">Author:</th><th style="background-color: aliceblue; padding: 5px;"> Nepasoft Solutions Pvt. Ltd.</th></tr>
prompt <tr><th style="padding: 5px;">Date Perofrmed:</th><th style="background-color: aliceblue; padding: 5px;">`date +%d-%m-%Y`</th></tr>
prompt </tbody>
prompt </table>
EOF


##
## Prepare Copyright info
##
read -d '' copyRightCmd << EOF
set define off
prompt <h3 style="text-align:center;margin:auto;color: cornflowerblue;text-decoration: underline; margin-top:20px;"> Copyright &copy; `date +%Y` Nepasoft Solutions Pvt. Ltd.</h3>
prompt <p style="width: 53%;margin:auto; margin-bottom:30px; text-align:center;color:black;">
prompt All rights reserved. This report is generated by Nepasoft for Oracle Database health checkup 
prompt with proper consent with the Database owner thereof the report may not be 
prompt reproduced or used in any manner whatsoever without the
prompt permission of the Nepasoft and Database Owner.
prompt </p>
set define on
EOF


##
## Collect Basic Database info
## 
read -d '' basicDBinfoCmd << EOF
----************************************
---- Basic Database Info
----************************************

prompt <h4>Basic Database Info:</h4>

select dbid,name, FLASHBACK_ON, PLATFORM_NAME,DATABASE_ROLE from v\$database;

----************************************
---- List the version of the database 
----************************************

prompt <h4>List the version of the database:</h4>
select * from v\$version;
EOF


##
## Collect Online and Standby Redo log info
##
read -d '' onlineRedoCmd << EOF
----********************************************************
---- List the log groups along with their members and size
----********************************************************
prompt <h4>Database Online Redo log groups:</h4>
select a.group#, a.thread#,bytes/(1024*1024) SIZE_MB, b.member from v\$log a, v\$logfile b where a.group#=b.group# order by a.group#;

----********************************************************
---- List the standby log groups with their members and size
----********************************************************

prompt <h4>Database Standby Redo log groups:</h4>
select a.group#, a.thread#,bytes/(1024*1024) SIZE_MB, b.member from v\$standby_log a, v\$logfile b where a.group#=b.group# order by a.group#;
set serveroutput on
DECLARE 
    rowCnt number(2);
BEGIN
    select count(*) into rowCnt from v\$standby_log;
    IF rowCnt <= 0 THEN
    dbms_output.put_line('<p style="margin-left: 5%; margin-top: 10px;">Information about standby redolog was not found.<p>'); 
    END IF;
END;
/
EOF


##
## Collect Controlfile info
##
read -d '' controlFileCmd << EOF

----********************************************************
---- Control file information
----********************************************************
prompt <h4>Control file information:</h4>
select name, STATUS,IS_RECOVERY_DEST_FILE , BLOCK_SIZE, FILE_SIZE_BLKS  from v\$controlfile order by name;
EOF


##
## Collect Wallet Info
##
read -d '' walletInfoCmd << EOF
----********************************************************
---- Wallet Information
----********************************************************
prompt <h4>Wallet Information:</h4>
select * from v\$encryption_wallet;
EOF


##
## Collect archive related info
##
read -d '' archiveInfoCmd << EOF
----********************************************************
---- Archive Information
----********************************************************
prompt <h4>Archive Information:</h4><p style="margin: auto; margin-left: 5%; width: 90%; margin-bottom: 20px;">
archive log list;
prompt </p>

----********************************************************
---- last 1 days archive status
----********************************************************
prompt <h4>Last 1 days archive status:</h4>

col "Archived Date" format a30
select to_char(COMPLETION_TIME,'DD/MM/YYYY HH24:MI:SS') "Archived Date",thread#, sequence#, archived, applied,inst_id, round((BLOCKS * BLOCK_SIZE)/(1024*1024),3) "Archive Size" from gv\$archived_log where COMPLETION_TIME >= sysdate - 1 and thread#=1 and inst_id=1 order by sequence#; 
select to_char(COMPLETION_TIME,'DD/MM/YYYY HH24:MI:SS') "Archived Date",thread#, sequence#, archived, applied,inst_id, round((BLOCKS * BLOCK_SIZE)/(1024*1024),3) "Archive Size" from gv\$archived_log where COMPLETION_TIME >= sysdate - 1 and thread#=2 and inst_id=2 order by sequence#;
EOF


##
## Collect Datagurad Information 
##
read -d '' dataguardInfoCmd << EOF
----********************************************************
---- Dataguard Information 
----********************************************************
prompt <h4>Dataguard Information:</h4>
select name, value,inst_id from gv\$parameter where name in 
(
'remote_login',
'db_name',
'memory_target',
'memory_max_target',
'db_unique_name',
'archive_lag_target',
'compatible',
'control_files',
'db_create_file_dest',
'DB_CREATE_ONLINE_LOG_DEST',
'db_recovery_file_dest',
'log_archive_config',
'log_archive_max_processes',
'log_archive_dest_1',
'log_archive_dest_state_1',
'log_archive_dest_2',
'log_archive_dest_state_2',
'fal_server',
'fal_client',
'standby_file_management',
'db_file_name_convert',
'log_file_name_convert',
'log_archive_format');

prompt <h4>Database Force logging Status:</h4>
select force_logging from v\$database;

----********************************************************
---- Check for the redo transport
----********************************************************

prompt <h4>Check for the redo transport:</h4>
select status , error from v\$archive_dest where dest_id=2;

----********************************************************
---- Data guard archive log status  
----********************************************************

prompt <h4>DataGuard Sync Status:</h4>
COL DB_NAME FORMAT A8
COL HOSTNAME FORMAT A12
COL LOG_ARCHIVED FORMAT 999999
COL LOG_APPLIED FORMAT 999999
COL LOG_GAP FORMAT 9999
COL APPLIED_TIME FORMAT A12

SELECT DB_NAME, HOSTNAME, LOG_ARCHIVED_TH1,LOG_ARCHIVED_TH2,LOG_APPLIED_TH1,LOG_APPLIED_TH2,LOG_ARCHIVED_TH1-LOG_APPLIED_TH1 LOG_GAP_TH1,LOG_ARCHIVED_TH2-LOG_APPLIED_TH2 LOG_GAP_TH2
FROM
(
SELECT NAME DB_NAME
FROM V\$DATABASE
),
(
SELECT UPPER(SUBSTR(HOST_NAME,1,(DECODE(INSTR(HOST_NAME,'.'),0,LENGTH(HOST_NAME),
(INSTR(HOST_NAME,'.')-1))))) HOSTNAME
FROM V\$INSTANCE
),
(
SELECT MAX(SEQUENCE#) LOG_ARCHIVED_TH1
FROM V\$ARCHIVED_LOG WHERE DEST_ID=1 AND ARCHIVED='YES' and Thread#=1
and 
resetlogs_id in 
( select max(resetlogs_id) from v\$archived_log where Thread#=1)
),
(
SELECT MAX(SEQUENCE#) LOG_ARCHIVED_TH2
FROM V\$ARCHIVED_LOG WHERE DEST_ID=1 AND ARCHIVED='YES' and Thread#=2
and 
resetlogs_id in 
( select max(resetlogs_id) from v\$archived_log where Thread#=2)
),
(
SELECT MAX(SEQUENCE#) LOG_APPLIED_TH1
FROM V\$ARCHIVED_LOG WHERE DEST_ID=2 AND APPLIED='YES' and Thread#=1
and 
resetlogs_id in 
( select max(resetlogs_id) from v\$archived_log where Thread#=1)
),
(
SELECT MAX(SEQUENCE#) LOG_APPLIED_TH2
FROM V\$ARCHIVED_LOG WHERE DEST_ID=2 AND APPLIED='YES' and Thread#=2
and 
resetlogs_id in 
( select max(resetlogs_id) from v\$archived_log where Thread#=2)
);
EOF


##
## Collect Backup information for database
##
read -d '' backupInfoCmd << EOF
----********************************************************
---- Rman Backup of Information
----********************************************************

set linesize 222
col "Start Time" format a18
col "End Time" format a18
col "BK Input Size: MB" format 999,999,999.99
col "BK Output Size: MB" format 999,999,999.99
col "Backup To" format a12
col "Status" format a35
col "Backup Type" format a20
col "Total Time" format a10
prompt <h4>Rman Backup of Information:</h4>
select to_char(START_TIME,'DD/MM/YYYY HH24:MI') "Start Time", to_char(END_TIME,'DD/MM/YYYY HH24:MI') "End Time",
round(INPUT_BYTES/1024/1024,2) "BK Input Size: MB",round(OUTPUT_BYTES/1024/1024,2) "BK Output Size: MB",
OUTPUT_DEVICE_TYPE "Backup To",STATUS "Status",INPUT_TYPE "Backup Type",TIME_TAKEN_DISPLAY "Total Time"
from V\$RMAN_BACKUP_JOB_DETAILS
where sysdate - START_TIME < 30 order by 1 desc; 

set serveroutput on
DECLARE 
    rowCnt number(2);
BEGIN
    select count(*) into rowCnt from V\$RMAN_BACKUP_JOB_DETAILS;
    IF rowCnt <= 0 THEN
    dbms_output.put_line('<p style="margin-left: 5%; margin-top: 10px;">No Bakcup details about RMAN was found in backup repository.<p>'); 
    END IF;
END;
/
EOF


##
## Collect archive log switch information
##
read -d '' logSwitchCmd << EOF
---- ***************************************************
---- log switch information
----********************************************************
prompt <h4>Log Switch Information for the instance:</h4>
set pages 999;
select to_char(first_time,'DD-MON-RR') "Date",
to_char(sum(decode(to_char(first_time,'HH24'),'00',2,0)),'999') " 00",
to_char(sum(decode(to_char(first_time,'HH24'),'01',2,0)),'999') " 01",
to_char(sum(decode(to_char(first_time,'HH24'),'02',2,0)),'999') " 02",
to_char(sum(decode(to_char(first_time,'HH24'),'03',2,0)),'999') " 03",
to_char(sum(decode(to_char(first_time,'HH24'),'04',2,0)),'999') " 04",
to_char(sum(decode(to_char(first_time,'HH24'),'05',2,0)),'999') " 05",
to_char(sum(decode(to_char(first_time,'HH24'),'06',2,0)),'999') " 06",
to_char(sum(decode(to_char(first_time,'HH24'),'07',2,0)),'999') " 07",
to_char(sum(decode(to_char(first_time,'HH24'),'08',2,0)),'999') " 08",
to_char(sum(decode(to_char(first_time,'HH24'),'09',2,0)),'999') " 09",
to_char(sum(decode(to_char(first_time,'HH24'),'10',2,0)),'999') " 10",
to_char(sum(decode(to_char(first_time,'HH24'),'11',2,0)),'999') " 11",
to_char(sum(decode(to_char(first_time,'HH24'),'12',2,0)),'999') " 12",
to_char(sum(decode(to_char(first_time,'HH24'),'13',2,0)),'999') " 13",
to_char(sum(decode(to_char(first_time,'HH24'),'14',2,0)),'999') " 14",
to_char(sum(decode(to_char(first_time,'HH24'),'15',2,0)),'999') " 15",
to_char(sum(decode(to_char(first_time,'HH24'),'16',2,0)),'999') " 16",
to_char(sum(decode(to_char(first_time,'HH24'),'17',2,0)),'999') " 17",
to_char(sum(decode(to_char(first_time,'HH24'),'18',2,0)),'999') " 18",
to_char(sum(decode(to_char(first_time,'HH24'),'19',2,0)),'999') " 19",
to_char(sum(decode(to_char(first_time,'HH24'),'20',2,0)),'999') " 20",
to_char(sum(decode(to_char(first_time,'HH24'),'21',2,0)),'999') " 21",
to_char(sum(decode(to_char(first_time,'HH24'),'22',2,0)),'999') " 22",
to_char(sum(decode(to_char(first_time,'HH24'),'23',2,0)),'999') " 23"
from v\$log_history
where sysdate - first_time < 30
group by to_char(first_time,'DD-MON-RR')
order by 1;
EOF


##
## Collect Asm Disk information
##
read -d '' asmDiskInfoCmd << EOF
----********************************************************
---- ASM Disk Information
----********************************************************

set linesize 500
column name format a30
column COMPATIBILITY format a20
column DATABASE_COMPATIBILITY format a20
column FREE_MB format a20
column type format a20
prompt <h4>ASM Disk Information:</h4>
select GROUP_NUMBER GROUP_NO ,NAME,STATE, TYPE,(TOTAL_MB/(1024)) total_GB  , (FREE_MB/1024) free_GB  from  v\$asm_diskgroup order by group_number, name;
select GROUP_NUMBER GROUP_NO ,NAME,REQUIRED_MIRROR_FREE_MB ,USABLE_FILE_MB,OFFLINE_DISKS,COMPATIBILITY ,DATABASE_COMPATIBILITY  from v\$asm_diskgroup order by group_number, name;

set serveroutput on
DECLARE 
    rowCnt number(2);
BEGIN
    select count(*) into rowCnt from V\$asm_diskgroup;
    IF rowCnt <= 0 THEN
    dbms_output.put_line('<p style="margin-left: 5%; margin-top: 10px;">ASM Disk group are not configured or No Diskgroup found..<p>'); 
    END IF;
END;
/

EOF


##
## Collect Memory and Memory advisory information for instance
##
read -d '' memoryInfoCmd << EOF
----********************************************************
---- Begin spooling for Memory Advisor
----********************************************************
prompt <h4>Dispaly Memory Parameters:</h4>
show parameter memory;

show parameter sga;

show parameter pga;

prompt <h4>Dispaly Memory Traget Advice:</h4>
select * from v\$memory_target_advice;

prompt <h4>Display SGA target advice:</h4>
select * from v\$sga_target_advice;

-- ************************************************
-- Display pga target advice
-- ************************************************
prompt <h4>Display pga target advice:</h4>
select pga_target_for_estimate, pga_target_factor, ESTD_PGA_CACHE_HIT_PERCENTAGE from v\$pga_target_advice;

prompt <h4>Display pga target advice:</h4>
SELECT
   ROUND(pga_target_for_estimate /(1024*1024)) c1,
   estd_pga_cache_hit_percentage         c2,
   estd_overalloc_count                  c3
FROM
   v\$pga_target_advice;

-- ************************************************
-- Display pga target advice histogram
-- ************************************************
prompt <h4>Display pga target advice histogram:</h4>
SELECT
   low_optimal_size/1024 "Low(K)",
   (high_optimal_size+1)/1024 "High(K)",
   estd_optimal_executions "Optimal",
   estd_onepass_executions "One Pass",
   estd_multipasses_executions "Multi-Pass"
FROM
   v\$pga_target_advice_histogram
WHERE
   pga_target_factor = 2
AND
   estd_total_executions != 0
ORDER BY
   1;
EOF

##
## List and collect profile and its properties
##
read -d '' dbProfileInfoCmd << EOF
prompt <h4>List and collect profile and its properties :</h4>
select * from dba_profiles;
EOF


##
## Collect DBA registery info for database
##
read -d '' dbRegistryInfoCmd << EOF
----************************************
---- List the components of dba registry
----************************************
prompt <h4>List the components of dba registry:</h4>
select comp_name, version, status from dba_registry order by comp_name;
EOF


##
## Collect Tablespace and its associated datafile info
##
read -d '' tsDatafileInfoCmd << EOF
----********************************************************
---- List the tablespace info and its usage
----********************************************************
prompt <h4>List the tablespace info and its usage:</h4>

column "Tablespace" format a25
column "Total Size in MB" format 999,999,999.99
column "Total Used in MB" format 999,999,999.99
column "Total free in MB" format 999,999,999.99
column "Used %" format a6
column "Free %" format a6

select tablespace_name "Tablespace",
round("Total in MB",2) "Total Size in MB",
round("Free in MB",2) "Total Free in MB",
round("Total in MB" - "Free in MB", 2) as "Total Used in MB",
round((("Total in MB" - "Free in MB")/"Total in MB")*100,2)||'%' as "Used %",
(round(100-(("Total in MB" - "Free in MB")/"Total in MB")*100,2))||'%' as "Free %"
from (select tablespace_name ,
sum( bytes /(1024*1024)) "Free in MB"  from dba_free_space
group by tablespace_name) ts join (select tablespace_name , sum( bytes/(1024*1024)) "Total in MB"
from dba_data_files group by tablespace_name) using ( tablespace_name) order by 4 desc;

----********************************************************
---- List the data files its size and other properties
----********************************************************
prompt <h4>List the data files its size and other properties:</h4>

column TABLESPACE_NAME format a20
column file_name format a50
column "Size: GB" format  999,999.99
column "Extend By" format  999,999.99
column "Max Size: GB" format  999,999.99
column "Free Space: GB" format  999,999.99

select ddf.tablespace_name,file_name,autoextensible,ONLINE_STATUS,"Extend By", "Size: GB", "Max Size: GB", "Free Space: GB" from 
(select tablespace_name,file_id , (bytes/1024/1024/1024) "Size: GB",file_name,INCREMENT_BY/1024/1024*1024*8 "Extend By",
ONLINE_STATUS, status,autoextensible, (MAXBYTES/1024/1024/1024) "Max Size: GB"
from dba_data_files) ddf
join
(select file_id, round(sum(BYTES/1024/1024/1024),2) "Free Space: GB" from DBA_FREE_SPACE group by file_id) dfs using (file_id)
order by 1;
EOF


##
## Collect Overall Database size info
##
read -d '' dbSizeInfoCmd << EOF
----************************************
---- View the database size and its usage
----************************************
prompt <h4>Database size and its usage:</h4>
col "Used Percentage" format a15
col "Free Percentage" format a15

select "Size in GB O/S level", ("Size in GB O/S level"- "Total Free in GB") "Size in GB Database Level",("Total Free in GB") "Total Free in GB DB Level",
trunc((("Size in GB O/S level"- "Total Free in GB")/ "Size in GB O/S level")*100,2)||'%' "Used Percentage",trunc(("Total Free in GB"/ "Size in GB O/S level")*100,2)||'%' "Free Percentage"
from 
(select 
round(( select sum(bytes)/1024/1024/1024 data_size from dba_data_files ) +
( select nvl(sum(bytes),0)/1024/1024/1024 temp_size from dba_temp_files ) +
( select sum(bytes)/1024/1024/1024 redo_size from sys.v_\$log ) +
( select sum(BLOCK_SIZE*FILE_SIZE_BLKS)/1024/1024/1024 controlfile_size from v\$controlfile),2) "Size in GB O/S level",
(select sum(round("Free in MB",2)) from (select tablespace_name ,
sum( bytes /(1024*1024*1024)) "Free in MB"  from dba_free_space
group by tablespace_name) ts join (select tablespace_name , sum( bytes/(1024*1024)) "Total in MB"
from dba_data_files group by tablespace_name) using ( tablespace_name))  "Total Free in GB"
from
dual);
EOF


##
## Collect Status of System and Sysaux Tablespaces
##
read -d '' systemTsInfoCmd << EOF
----********************************************************
---- Health of system and sysaux tablespaces
----********************************************************
prompt <h4>Total size of system and sysaux tablespaces used by non System users:</h4>
select sum(bytes/1024/1024) "Size System tablespaces used" from dba_segments
where tablespace_name = 'SYSTEM'
and owner not in ('SYS','SYSTEM');

----********************************************************
---- Select the space of system tablespace consumed by users other then sys and system
----********************************************************
prompt <h4>System tablespace consumed by users other then sys and system:</h4>
select owner, segment_name, segment_type
from dba_segments
where tablespace_name = 'SYSTEM'
and owner not in ('SYS','SYSTEM');
EOF


##
## Collect Tempory Tablespace Info for Database
##
read -d '' tempTsInfoCmd << EOF
----********************************************************
------ Temporary Tablespace in Database
----********************************************************
prompt <h4>Temporary Tablespace in Database:</h4>
select tablespace_name, sum(bytes)/1024/1024 "Size in MB"
from dba_temp_files
group by tablespace_name;
EOF


##
## Collect Database Users Information
##
read -d '' usersInfoCmd << EOF
----********************************************************
---- Users Information
----********************************************************
prompt <h4>Users Information:</h4>
select username, default_tablespace, temporary_tablespace, account_status,EXPIRY_DATE from dba_users order by username;
EOF


##
## Create DBHCGROWTHRATE table to track database growth rate if not exists
##
read -d '' dbGthCreTblCmd << EOF
DECLARE 
                tableStmt varchar2(4000);
                tblOut number(2);
BEGIN
        select count(*) into tblOut from dba_tables where table_name='DBHCGROWTHRATE';
        IF tblOut <= 0 THEN
                tableStmt:='CREATE TABLE DBHCGROWTHRATE (
                DBHCDATE DATE DEFAULT SYSDATE,
                SIZEINOS_GB varchar2(10),
                SIZEINDB_GB varchar2(10),
                FREEINDB_GB varchar2(10),
                USED_PERCENT VARCHAR2(10),
                FREE_PERCENT VARCHAR2(10)
                )';
                EXECUTE IMMEDIATE tableStmt;
        END IF;
END;
/
EOF


##
## Insert Into the TABLE DBHCGROWTHRATE
##
read -d '' dbGthInsrCmd << EOF
BEGIN
                FOR DBHCROW IN (select "Size in GB O/S level" OS, ("Size in GB O/S level"- "Total Free in GB") "DB_SIZE",("Total Free in GB") "DB_FREE",
                trunc((("Size in GB O/S level"- "Total Free in GB")/ "Size in GB O/S level")*100,2)||'%' "USED_PERCENT",
                trunc(("Total Free in GB"/ "Size in GB O/S level")*100,2)||'%' "FREE_PERCENT"
                from
                (select
                round(( select sum(bytes)/1024/1024/1024 data_size from dba_data_files ) +
                ( select nvl(sum(bytes),0)/1024/1024/1024 temp_size from dba_temp_files ) +
                ( select sum(bytes)/1024/1024/1024 redo_size from sys.v_\$log ) +
                ( select sum(BLOCK_SIZE*FILE_SIZE_BLKS)/1024/1024/1024 controlfile_size from v\$controlfile),2) "Size in GB O/S level",
                (select sum(round("Free in MB",2)) from (select tablespace_name ,
                sum( bytes /(1024*1024*1024)) "Free in MB"  from dba_free_space
                group by tablespace_name) ts join (select tablespace_name , sum( bytes/(1024*1024)) "Total in MB"
                from dba_data_files group by tablespace_name) using ( tablespace_name))  "Total Free in GB"
                from
                dual))
                        LOOP
                                INSERT INTO DBHCGROWTHRATE VALUES (sysdate, DBHCROW.OS, DBHCROW.DB_SIZE, DBHCROW.DB_FREE,DBHCROW.USED_PERCENT, DBHCROW.FREE_PERCENT);
                        COMMIT;
                        END LOOP;
END;
/
EOF


##
## Collect Database Growthrate Sofar
##
read -d '' dbGthAllCmd << EOF
prompt <h4>Database Growthrate Sofar:</h4>
select * from DBHCGROWTHRATE;
EOF


##
## Collect Oracle Basic Audit Info.
##
read -d '' dbAuditCmd << EOF
prompt <h4>Database Audit Info:</h4>
show parameter audit;
EOF


##
## Prepare necessary css for whole document
##
read -d '' styleCmd1 << EOF
prompt <html><head><style type="text/css"> p{margin:auto;} h2{color: #336699; text-align: center; margin-bottom: 10px; font-size:40px; text-decoration: underline;} th{color: #000; background: #cccc99; padding:10px;} h4{font-size: 18px; color:#6697ef; text-decoration: underline; margin: auto; margin-left:5%; margin-top:15px; margin-bottom:5px;} th,td{font-family: monospace; font-size:12px;} hr{border-width:4px; border-bottom-color: #000;} br{ display:none; } table{border-spacing: inherit;border-color: #eee;} table tr:nth-child(odd) td{background:#fcf8e3 } table tr:nth-child(even) td{ background:#f5f5f5 }</style></head><body style=" width:90%; margin: auto;">
EOF


##
## Collect Oracle Instance and Database Info for AWR/ADDM.
##
read -d '' dbInstAwAdCmd << EOF
col dbid new_value V_DBID noprint
select  dbid from v\$database;

col instance_number new_value V_INST noprint
select  instance_number from v\$instance;
EOF


##
## Collect Snapshot Info for AWR/ADDM.
##
read -d '' dbAwrSnapCmd << EOF
-- Begining Snapshot 
col snap_id new_value V_BID
select  min(snap_id) snap_id
from    dba_hist_snapshot
where   end_interval_time >= (sysdate-1)
and     startup_time <= begin_interval_time
and     dbid = &&V_DBID
and     instance_number = &&V_INST;

-- END Snapshot 
col snap_id new_value V_EID
select  max(snap_id) snap_id
from    dba_hist_snapshot
where   dbid = &&V_DBID
and     instance_number = &&V_INST;
EOF


##
## Generate AWR REPORT.
##
read -d '' dbAwrRptCmd << EOF
select  'BEGIN='||trim(to_char(begin_interval_time, 'HH24:MI')) snap_time
from    dba_hist_snapshot
where   dbid = &&V_DBID
and     instance_number = &&V_INST
and     snap_id = &&V_BID ;
select  'END='||trim(to_char(end_interval_time, 'HH24:MI')) snap_time
from    dba_hist_snapshot
where   dbid = &&V_DBID
and     instance_number = &&V_INST
and     snap_id = &&V_EID ;
EOF


##
## Functions to spool database metrics based on its status
##

spoolDBFULL(){

${1}/bin/sqlplus -s /nolog << __EOF__ > /dev/null 2>&1

connect / as sysdba
set pagesize 0 feedback off verify off echo off;
--SET MARKUP HTML ON SPOOL ON ENTMAP OFF
--SET MARKUP HTML ON SPOOL OFF ENTMAP OFF
SET MARKUP HTML ON SPOOL OFF PREFORMAT OFF ENTMAP OFF
SPOOL ${2}
$formatCmd
$styleCmd1
$dbhcHeadingCmd
$basicDBinfoCmd
$dbRegistryInfoCmd
$dbSizeInfoCmd
$onlineRedoCmd
$tsDatafileInfoCmd
$controlFileCmd
$systemTsInfoCmd
$tempTsInfoCmd
$usersInfoCmd
$walletInfoCmd
$archiveInfoCmd
$dbProfileInfoCmd
$dataguardInfoCmd
$backupInfoCmd
$logSwitchCmd
$asmDiskInfoCmd
$memoryInfoCmd
$dbGthCreTblCmd
$dbGthInsrCmd
$dbAuditCmd
$dbGthAllCmd
$copyRightCmd
$styleEndCmd
spool off;
__EOF__

}


spoolDBPARTIAL(){
echo "-----------> Database found on Mounted mode only partial statistics are accumulated."
${1}/bin/sqlplus -s /nolog << __EOF__ > /dev/null 2>&1
connect / as sysdba
set pagesize 0 feedback off verify off echo off;
SET MARKUP HTML ON SPOOL OFF PREFORMAT OFF ENTMAP OFF
SPOOL ${2}
$formatCmd
$styleCmd1
$dbhcHeadingCmd
$basicDBinfoCmd
$onlineRedoCmd
$controlFileCmd
$walletInfoCmd
$archiveInfoCmd
$dataguardInfoCmd
$logSwitchCmd
$asmDiskInfoCmd
$memoryInfoCmd
$copyRightCmd
$styleEndCmd
spool off;
__EOF__

}

#spoolDBBASIC(){
#
#}

#spoolAWRADDM(){
#
#}


spoolAWR(){
${1}/bin/sqlplus -s /nolog << __EOF__ > /dev/null 2>&1

connect / as sysdba
set pagesize 0
set lines 300
set verify off heading off

---SPOOL ${2}
$dbInstAwAdCmd
$dbAwrSnapCmd
$dbAwrRptCmd

spool ${2}
select output from table(dbms_workload_repository.awr_report_html(&&V_DBID,&&V_INST, &&V_BID, &&V_EID, 0));
spool off

__EOF__
}


spoolADDM(){
${1}/bin/sqlplus -s /nolog << __EOF__ > /dev/null 2>&1

connect / as sysdba
set pagesize 0
set lines 300
set verify off heading off
$dbInstAwAdCmd
$dbAwrSnapCmd

BEGIN
-- Create Task to Generate ADDM reports
  DBMS_ADVISOR.create_task (
    advisor_name      => 'ADDM',
    task_name         => '${ADDM_TNAME}',
    task_desc         => '${ADDM_TDESC}');

  -- Set the start and end snapshots.
  DBMS_ADVISOR.set_task_parameter (
    task_name => '${ADDM_TNAME}',
    parameter => 'START_SNAPSHOT',
    value     => &&V_BID);

  DBMS_ADVISOR.set_task_parameter (
    task_name => '${ADDM_TNAME}',
    parameter => 'END_SNAPSHOT',
    value     => &&V_EID);

  -- Execute the task.
  DBMS_ADVISOR.execute_task(task_name => '${ADDM_TNAME}');
END;
/

-- Display the report.
SET LONG 1000000 LONGCHUNKSIZE 1000000
SET LINESIZE 1000 PAGESIZE 0
SET TRIM ON TRIMSPOOL ON
SET ECHO OFF FEEDBACK OFF

spool ${2}
SELECT DBMS_ADVISOR.get_task_report('${ADDM_TNAME}') AS report FROM   dual;
spool off;

exit success

__EOF__

}

## 
## Set the directory to store the logs to be collected .
##
clear
destdir=`echo $DBHC_DIR`

echo "###########################################################################################"
echo "###########################################################################################"
echo "#  _   _                             __ _      _____       _       _   _                  #"
echo "#                                                                                         #"
echo "#                                                                                         #"
echo "#                                                                                         #"
echo "#                                                                                         #"
echo "#                                                                                         #"
echo "#            |_|                                                                          #"
echo "#            |_|                                                                          #"
echo "#-----------------------------------------------------------------------------------------#"
echo "###########################################################################################"
echo "#-----------------------------------------------------------------------------------------#"
echo "#  _____  ____  _    _  _____    _____  _____ _____  _____ _____ _______                  #"
echo "# |  __ \|  _ \| |  | |/ ____|  / ____|/ ____|  __ \|_   _|  __ \__   __|                 #"
echo "# | |  | | |_) | |__| | |      | (___ | |    | |__) | | | | |__) | | |                    #"
echo "# | |  | |  _ <|  __  | |       \___ \| |    |  _  /  | | |  ___/  | |                    #"
echo "# | |__| | |_) | |  | | |____   ____) | |____| | \ \ _| |_| |      | |                    #"
echo "# |_____/|____/|_|  |_|\_____| |_____/ \_____|_|  \_\_____|_|      |_|                    #"
echo "#                                                                                         #"
echo "#        ${bold}${underline}Nepasoft DBHC SCRIPT For Oracle DATABASE${reset}. Developer: ${bold}${underline}Suman Adhikari${reset}.             #"
echo "#                                                                                         #"
echo "###########################################################################################"
echo "###########################################################################################"

echo "--------> Deaflut DBHC BASE Directory for saving logs and metrics: ${bold}${underline}$DBHC_BASE${reset}"

##
## List the running databases in Server 
## Enter the database to run the health check up :
##
myarr=($(ps -ef | grep ora_smon | awk -F' ' '{print $NF}' | cut -c 10-))
#myarr=($(ps -ef |grep smon | awk -F'_' '{print $3}'))
echo "--------> List of Oracle Database Instance running on box: ${bold}${underline}`hostname`${reset}"

for i in "${myarr[@]}"
	do :
	echo "-----------> Oracle Database Instance: "${bold}${underline}$i${reset} 
	done

if [[ "${ORA_INSTANCE}" = "" ]]
then
printf  'Enter the database instance for which Health Check should be Performed : '
read -r ORA_INSTANCE
export ORACLE_SID=`echo $ORA_INSTANCE`
fi

##
## Get the environment variables for the respective instance
## Get the ORACLE sid
export ORACLE_SID=`echo $ORA_INSTANCE`


##
## Get the date and time for name of the folders
##
export DATE_TIME=`date +%d_%m_%Y`
#export FILE_NAME=$destdir"/DBarchitecture_"$ORA_INSTANCE"_DBHC_"$DATE_TIME".log"
export FILE_NAME=$destdir"/DBarchitecture_"$ORA_INSTANCE"_DBHC_"$DATE_TIME".html"


## 
## Handling the exceptions
## Test if the respective environmental variables are set or not.
## 

if [[ "${ORACLE_HOME}" = "" ]]
then
 _errorReport "ORACLE_HOME Environmental variable not Set. Aborting...."
fi

if [ ! -d ${ORACLE_HOME} ]
then
 _errorReport "Directory \"${ORACLE_HOME}\" not Valid. Aborting...."
fi

if [ ! -x ${ORACLE_HOME}/bin/sqlplus ]
then
 echo "Executable \"${ORACLE_HOME}/bin/sqlplus\" not found; aborting..."
fi

if [[ "${ORACLE_SID}" = "" ]]
then
 _errorReport "ORACLE_SID Environmental variable not Set. Aborting...."
fi


##
## Check if the user provided instance name is valid or not
##
checkSidValid myarr[@] $ORA_INSTANCE

if [ $? -eq 0 ]
then
  _errorReport "ORACLE_SID: ${bell}${bold}${underline}${ORA_INSTANCE}${reset} is Invalid. Aborting...."
else
   dummy=0
fi


##
## Get the type of instance and retrun the database type
##
getDBname $ORACLE_HOME
getDBmode $ORACLE_HOME
getDBrole $ORACLE_HOME
getDBalertLog $ORACLE_HOME

echo "-----------> Selected Database/Instance: "${bold}${underline}$DBNAME${reset}" / "${bold}${underline}$ORA_INSTANCE${reset}
echo "-----------> Selected Database Open Mode: "${bold}${underline}$DBMODE${reset}
echo "-----------> Selected Database Role: "${bold}${underline}$DBROLE${reset}

##
## Create necessary directories for storing DBHC logs
##
##DBHC_HOME=`echo $DBHC_BASE`_`echo $ORA_INSTANCE`_
mkdir -p ${DBHC_DIR}
if [ $? -ne 0 ] ; then
    _errorReport "DBHC directory cannot be created. Aborting...."
fi


##
## Collect the database stats based on its status
##
if [ "$DBMODE" = "READ WRITE" ] && [ "$DBROLE" = "PRIMARY" ];
	then
	spoolDBFULL $ORACLE_HOME $FILE_NAME

elif [ "$DBMODE" = "MOUNTED" ] && [ "$DBROLE" = "PRIMARY" ];
	then
	spoolDBPARTIAL $ORACLE_HOME $FILE_NAME

elif [ "$DBMODE" = "MOUNTED" ] && [ "$DBROLE" = "PHYSICAL STANDBY" ];
	then
	spoolDBPARTIAL $ORACLE_HOME $FILE_NAME

elif [ "$DBMODE" = "READ WRITE" ] && [ "$DBROLE" = "PHYSICAL STANDBY" ];
	then
	spoolDBFULL $ORACLE_HOME $FILE_NAME
else 
	echo "Database status and open mode cannot be detected."
fi

##
## Collectiong alert log in DBHC
## 
tail -500000 $DB_ALERT_LOG/alert_$ORA_INSTANCE.log > $DBHC_DIR/alert_$ORA_INSTANCE.log


# Clear the screen
clear

echo "#############################################################################";
echo "#############################################################################";
echo "#    _____                           _   _                                  #";
echo "#   / ____|                         | | (_)                                 #";
echo "#  | |  __  ___ _ __   ___ _ __ __ _| |_ _ _ __   __ _                      #";
echo "#  | | |_ |/ _ \ '_ \ / _ \ '__/ _' | __| | '_ \ / _' |                     #";
echo "#  | |__| |  __/ | | |  __/ | | (_| | |_| | | | | (_| |                     #";
echo "#   \_____|\___|_| |_|\___|_|  \__,_|\__|_|_| |_|\__, |                     #";
echo "#                                                 __/ |                     #";
echo "#                                                |___/                      #";
echo "#############################################################################";
echo "#        ${bold}${underline}Generating AWR/ADDM Report for Database instance:${reset} ${ORA_INSTANCE}.         #";
echo "#############################################################################";
echo "#       __          _______        __           _____  _____  __  __        #";
echo "#      /\ \        / /  __ \      / /     /\   |  __ \|  __ \|  \/  |       #";
echo "#     /  \ \  /\  / /| |__) |    / /     /  \  | |  | | |  | | \  / |       #";
echo "#    / /\ \ \/  \/ / |  _  /    / /     / /\ \ | |  | | |  | | |\/| |       #";
echo "#   / ____ \  /\  /  | | \ \   / /     / ____ \| |__| | |__| | |  | |       #";
echo "#  /_/    \_\/  \/   |_|  \_\ /_/     /_/    \_\_____/|_____/|_|  |_|       #";
echo "#############################################################################";  
echo "#############################################################################"; 
echo "-----------> Wait !!!! Do not press Enter Key Reports are being generated.";

##
## Test if the respective environmental variables are set or not.
## 

if [[ "${ORACLE_HOME}" = "" ]]
then
 _errorReport "ORACLE_HOME Environmental variable not Set. Aborting...."
 exit 1
fi
if [ ! -d ${ORACLE_HOME} ]
then
 _errorReport "Directory \"${ORACLE_HOME}\" not Valid. Aborting...."
 exit 1
fi

if [ ! -x ${ORACLE_HOME}/bin/sqlplus ]
then
 echo "Executable \"${ORACLE_HOME}/bin/sqlplus\" not found; aborting..."
 exit 1
fi

##
## Generate the file name for awr and addm reports
##

AWR_FILE=$destdir"/Awr_report_"$ORA_INSTANCE"_DBHC_"$DATE_TIME".html"
ADDM_FILE=$destdir"/Addm_report_"$ORA_INSTANCE"_DBHC_"$DATE_TIME".txt"
ADDM_TNAME="DBHC_$DATE_TIME"
ADDM_TDESC="ADDM for DBHC $DATE_TIME"


##
## Generate AWR and ADDM reports on basis of DBMODE
##
if [ "$DBMODE" = "READ WRITE" ] && [ "$DBROLE" = "PRIMARY" ];
        then
        spoolAWR $ORACLE_HOME $AWR_FILE
	spoolADDM $ORACLE_HOME $ADDM_FILE
else
        echo "Database status and open mode not compatible to generate AWR and ADDM reports."
fi
sleep 3

_errorReport(){
       echo "########################################################"
           echo "DBHC-Error During Running Scripts"
       echo "Error: $1 "
       echo "########################################################"
}


##
## Clear the screen
##
clear;
echo "######################################################################################";
echo "######################################################################################";
echo "#   ____        _  _              _    _                 _                           #";
echo "#  / ___| ___  | || |  ___   ___ | |_ (_) _ __    __ _  | |     ___    __ _  ___     #";
echo "# | |    / _ \ | || | / _ \ / __|| __|| || '_ \  / _' | | |    / _ \  / _' |/ __|    #";
echo "# | |___| (_) || || ||  __/| (__ | |_ | || | | || (_| | | |___| (_) || (_| |\__ \    #";
echo "#  \____|\___/ |_||_| \___| \___| \__||_||_| |_| \__, | |_____|\___/  \__, ||___/    #";
echo "#                                                |___/                |___/          #";
echo "######################################################################################";
echo "#                    _   __  __        _          _              _____               #";
echo "#   __ _  _ __    __| | |  \/  |  ___ | |_  _ __ (_)  ___  ___  |  ___|___   _ __    #";
echo "#  / _' || '_ \  / _' | | |\/| | / _ \| __|| '__|| | / __|/ __| | |_  / _ \ | '__|   #";
echo "# | (_| || | | || (_| | | |  | ||  __/| |_ | |   | || (__ \__ \ |  _|| (_) || |      #";
echo "#  \__,_||_| |_| \__,_| |_|  |_| \___| \__||_|   |_| \___||___/ |_|   \___/ |_|      #";
echo "######################################################################################";
echo "#   ___     __ ____                                                                  #";
echo "#  / _ \   / // ___|                                                                 #";
echo "# | | | | / / \___ \  : ${bold}${underline}Collecting logs and metrics For Operating System ${reset}            #";
echo "#  \___//_/   |____/                                                                 #";
echo "######################################################################################";
echo "######################################################################################";

#echo "-----------> ${bold}${underline}Collecting logs and metrics For Operating System ${reset}"
if [[ "${OS_CHOICE}" = "" ]]
then
printf  ' ----------> Do you Prefer to collect O/S info [Y | N] : '
read -r OS_CHOICE
fi

#echo $oschoice
OS_LOG_FILE=osinfo_${DATE_TIME}.log

if [ "$OS_CHOICE" == "Y" ]
  then
	  infoReport "Collecting and Spooling logs and metrics" "For Operating System" > $LOG_DEST_DIR/$OS_LOG_FILE
	  
	  ## Get the current date and time
	  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  keyValueReport "Current Date and time of Server" "`date`" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  
	  ## Gathering the host file info
	  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  keyValueReport "Gathering the host file info" "\n`cat /etc/hosts`" >> $LOG_DEST_DIR/$OS_LOG_FILE
	
	  ## Gathering the user info
	  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  keyValueReport "Gathering the user info" "\n`cat /etc/passwd`" >> $LOG_DEST_DIR/$OS_LOG_FILE

	  ## Gathering the group info
	  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  keyValueReport "Gathering the group info" "\n`cat /etc/group`" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  
	  ## Gathering the group info
	  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  keyValueReport "Gathering the group info" "\n`vmstat`" >> $LOG_DEST_DIR/$OS_LOG_FILE

	  ## Gathering Input/output statistics
	  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  keyValueReport "Gathering Input/output statistics" "\n`iostat`" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  
	  ## Track System files modification date
	  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  keyValueReport "Track System files modification date" "\n`ls -ltr /etc/hosts /etc/passwd /etc/group /etc/hosts /etc/resolv.conf`" >> $LOG_DEST_DIR/$OS_LOG_FILE

	  ## COLLECTING INFORMATION SPECIFIC TO PLATFORM
	  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  keyValueReport "COLLECTING INFORMATION SPECIFIC TO PLATFORM" " " >> $LOG_DEST_DIR/$OS_LOG_FILE
          echo "  ---------> ${bold}${underline}AIX${reset}: For AIX"
          echo "  ---------> ${bold}${underline}HP${reset}: For HP-UX"
          echo "  ---------> ${bold}${underline}LX${reset}: For Linux"
          echo "  ---------> ${bold}${underline}SL${reset}: For Solaris"
          
	  if [[ "${OS_PLATFORM}" = "" ]]
	  then
	  printf " ----------> Please Enter the Platform in which \n ----------> You are executing Script from above list : "
          read -r OS_PLATFORM
	  fi
      ##
      ## Check if the O/S choice is Valid if not terminate the execution of script.
      ##
      checkValidOS $OS_PLATFORM
      if [ ! ${OS_TYPE_STATUS} = "VALID" ]
              then
              _errorReport "Invalid O/S Selection : ${bell}${bold}${underline}${OS_PLATFORM}${reset} . Aborting...."
              exit;
      else
              echo ""
      fi


      ##
      ## Collect logs specific to the O/S
      ##
      case "$OS_PLATFORM" in
              'AIX')
              #####################################################
              # Your Platform is IBM-AIX and Collecting Data      #
              #####################################################
			      ## Notifify Platform
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Your Platform is AIX" "Collecting Data" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  
			      ## File system Info and Mountpoint Status
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "File system Info and Mountpoint Status" "\n`df -g`" >> $LOG_DEST_DIR/$OS_LOG_FILE
				  
			      ## View default profile contents
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Default Profile" "\n`cat ~/.profile`" >> $LOG_DEST_DIR/$OS_LOG_FILE

			      ## Memory and Swap information
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Memory : `/usr/sbin/lsattr -E -l sys0 -a realmem`" "\n Swap: `/usr/sbin/lsps -a`" >> $LOG_DEST_DIR/$OS_LOG_FILE
              ;;
              'HP')
              #####################################################
              # Your Platform is HP-UX and Collecting Data        #
              #####################################################
			      ## Notifify Platform
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Your Platform is HP-UX" "Collecting Data" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  
			      ## File system Info and Mountpoint Status
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "File system Info and Mountpoint Status" "\n`bdf`" >> $LOG_DEST_DIR/$OS_LOG_FILE
				  
			      ## View default profile contents
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Default Profile" "\n`cat ~/.profile`" >> $LOG_DEST_DIR/$OS_LOG_FILE

			      ## Memory and Swap information
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Memory : `/usr/contrib/bin/machinfo | grep -i Memory`" "\n Swap: `/usr/sbin/swapinfo -a`" >> $LOG_DEST_DIR/$OS_LOG_FILE
              ;;
              'LX')
              #####################################################
              # Your Platform is linux and Collecting Data        #
              #####################################################
			      ## Notifify Platform
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Your Platform is Linux" "Collecting Data" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  
			      ## File system Info and Mountpoint Status
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "File system Info and Mountpoint Status" "\n--------\n`df -h`" >> $LOG_DEST_DIR/$OS_LOG_FILE
				  
			      ## View default profile contents
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Default Profile" "\n--------\n`cat ~/.bash_profile`" >> $LOG_DEST_DIR/$OS_LOG_FILE

			      ## Memory and Swap information
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Memory : `cat /proc/meminfo | grep "Mem"`" "\n Swap:\n--------`cat /proc/meminfo | grep "Swap"`" >> $LOG_DEST_DIR/$OS_LOG_FILE
                              
                              ## Capture the top output for two iterations and save it
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
                                  keyValueReport "Capturing the Top process:" "\n------------------------\n`top -d 2 -n 2 -b`" >> $LOG_DEST_DIR/$OS_LOG_FILE
  
	      ;;
              'SL')
              #####################################################
              # Your Platform is Solaris and Collecting Data      #
              #####################################################
			      ## Notifify Platform
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Your Platform is Solaris" "Collecting Data" >> $LOG_DEST_DIR/$OS_LOG_FILE
	  
			      ## File system Info and Mountpoint Status
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "File system Info and Mountpoint Status" "\n`df -h`" >> $LOG_DEST_DIR/$OS_LOG_FILE
				  
			      ## View default profile contents
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Default Profile" "\n`cat ~/.profile`" >> $LOG_DEST_DIR/$OS_LOG_FILE

			      ## Memory and Swap information
				  echo -e "\n" >> $LOG_DEST_DIR/$OS_LOG_FILE
			  	  keyValueReport "Memory : `/usr/sbin/prtconf | grep "Memory size"`" "\n Swap: `/usr/sbin/swap -s`" >> $LOG_DEST_DIR/$OS_LOG_FILE
              ;;
      esac
else
echo "---------> Collecting logs and metrics For Operating System Skipped"
fi
sleep 2


##
## Clear Screen
##
clear



##
## Collect RAC Specific Information                                   
##                                                           

##
## Get The GRID HOME to run GRID Specific commands.
## By checking if Oracle Grid Infra is running or not.
##

RAC_HOME=`ps -ef | grep d.bin | grep orarootagent |tail -1 | awk '{print $NF}'`
if [[ -z "$RAC_HOME" ]]; then
    infoReport "No Oraacle Clusterware Detected" "Oracle Clusterware info collection skipped."
    exit 0;  
else
    RAC_HOME=`dirname $RAC_HOME`
    RAC_HOME=`echo $RAC_HOME|sed 's/bin//'`
    PATH=$PATH:$RAC_HOME/bin
fi


##
## Set the log name for Oracle Clusterware logs.
##

setClusterLogfile $RAC_HOME


echo "#############################################################################";
echo "#############################################################################";
echo "#    _____      _ _           _   _               _                         #";
echo "#   / ____|    | | |         | | (_)             | |                        #";
echo "#  | |     ___ | | | ___  ___| |_ _ _ __   __ _  | |     ___   __ _ ___     #";
echo "#  | |    / _ \| | |/ _ \/ __| __| | '_ \ / _' | | |    / _ \ / _' / __|    #";
echo "#  | |___| (_) | | |  __/ (__| |_| | | | | (_| | | |___| (_) | (_| \__ \    #";
echo "#   \_____\___/|_|_|\___|\___|\__|_|_| |_|\__, | |______\___/ \__, |___/    #";
echo "#                                          __/ |               __/ |        #";
echo "#                                         |___/               |___/         #";
echo "#############################################################################";
echo "#               ${bold}${underline}Collecting Logs and metrics for Oracle RAC${reset}.                 #";
echo "#############################################################################";
echo "#   ______           _____            _____                                 #";
echo "#  |  ____|         |  __ \     /\   / ____|                                #";
echo "#  | |__ ___  _ __  | |__) |   /  \ | |                                     #";
echo "#  |  __/ _ \| '__| |  _  /   / /\ \| |                                     #";
echo "#  | | | (_) | |    | | \ \  / ____ \ |____                                 #";
echo "#  |_|  \___/|_|    |_|  \_\/_/    \_\_____|                                #";
echo "#############################################################################";
echo "#############################################################################";

#echo -e "\n"
echo "----------> Collecting logs and metrics For Oracle Clusterware"

if [[ "${RAC_CHOICE}" = "" ]]
then
printf " ---------> Do you wish to collect information \n ---------> related to Oracle Clusterware [Y | N] : "
read -r RAC_CHOICE
fi

if [ "$RAC_CHOICE" == "Y" ]
then
	infoReport "Collecting and Spooling logs and metrics" "For Oracle crs information" > $LOG_DEST_DIR/$RAC_LOG_FILE
	
	## Get the name of the cluster
	echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	keyValueReport "Cluseter name" `cemutlo -n` >> $LOG_DEST_DIR/$RAC_LOG_FILE
	
	## Get the clusterware active version running on the box
	echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	keyValueReport "Clusterware Active Version" "\n`crsctl query crs activeversion`" >> $LOG_DEST_DIR/$RAC_LOG_FILE        
        
	##  Get the crs information
	echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	keyValueReport "Get the crs information" "\n`crsctl check crs`" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	
	## Get the information of overall cluster
	echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	keyValueReport "Get the information of overall cluster" "\n`crsctl check cluster -all`" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	
	## Get the status of overall services running on the box
	echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	keyValueReport "Get the status of overall services running on the box" "\n`crsctl stat res -t`" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	
	## Get the OCR information
	echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	keyValueReport "OCR metrics and status" "\n`ocrcheck`" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	
	## Get the Voting Disk information
	echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	keyValueReport "Voting Disk metrics and status" "\n`crsctl query css votedisk`" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	
	
	## Check the Cluster Time Synchronization status
	echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
	keyValueReport "Cluster Time Synchronization status" "\n`crsctl check ctss`" >> $LOG_DEST_DIR/$RAC_LOG_FILE

	##
	## Get the databases registered with Oracle Clusterware and display its properties
	##
	RACDBS=($(srvctl config))
	
	for i in "${RACDBS[@]}"
   	do :
	echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
   		keyValueReport "Oracle Database Registered with Clusterware" "$i" >> $LOG_DEST_DIR/$RAC_LOG_FILE
   		keyValueReport "Oracle Database $i status" "\n`srvctl status database -d $i -v`" >> $LOG_DEST_DIR/$RAC_LOG_FILE
		echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
   		keyValueReport "Oracle Database $i configuration" "\n`srvctl config database -d $i`" >> $LOG_DEST_DIR/$RAC_LOG_FILE
   	done
	
	echo -e "\n" >> $LOG_DEST_DIR/$RAC_LOG_FILE
       
	 ##
	 ## Get the list 1000 lines of cluster logfile
	 ##
	 infoReport "Get the list 1000 lines of cluster logfile" " " >> $LOG_DEST_DIR/$RAC_LOG_FILE
         SCRIPTHOST=$(hostname| awk -F'.' '{print $1}')
         tail -1000 $RAC_HOME/log/$SCRIPTHOST/alert$SCRIPTHOST.log >> $LOG_DEST_DIR/$RAC_LOG_FILE

else
	echo -e "\n"
	echo "--------------> Collecting logs and metrics For Oracle Clusterware was skipped."
fi

 	echo "--------------> Log, metrics and statistics collection completed."

sleep 2
clear

