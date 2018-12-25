#/bin/bash
#############################################################
# Author :                                                 ##
# Company : xxxxxxxxxxxxxxxxx                              ##
# Description :                                            ##
#############################################################
#echo -e "\n"  ## for new line.

## Funtions to wrapper scripts
## array for select choices

############################################################
# Setting environments
############################################################
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

destdir="/home/oracle/DBHC"
## 
## Set the directory to store the logs to be collected .
##
clear
destdir="/home/oracle/DBHC"
echo -e "\n"
echo "########################################################################################"
echo "  _   _                            __ _      _____       _       _   _                  "
echo "                                                                                        "
echo "                                                                                        "
echo "                                                                                        "
echo "                                                                                        "
echo "                                                                                        "
echo "  _____  ____  _    _  _____    _____  _____ _____  _____ _____ _______                 "
echo " |  __ \|  _ \| |  | |/ ____|  / ____|/ ____|  __ \|_   _|  __ \__   __|                "
echo " | |  | | |_) | |__| | |      | (___ | |    | |__) | | | | |__) | | |                   "
echo " | |  | |  _ <|  __  | |       \___ \| |    |  _  /  | | |  ___/  | |                   "
echo " | |__| | |_) | |  | | |____   ____) | |____| | \ \ _| |_| |      | |                   "
echo " |_____/|____/|_|  |_|\_____| |_____/ \_____|_|  \_\_____|_|      |_|                   "
echo "                                                                                        "
echo "-_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-"
echo "  ___              _                     _   ___                            _    "
echo " |   \ _____ _____| |___ _ __  ___ _ _  (_) / __|_  _ _ __  __ _ _ _       /_\   "
echo " | |) / -_) V / -_) / _ \ '_ \/ -_) '_|  _  \__ \ || | '  \/ _  | ' \   _ / _ \  "
echo " |___/\___|\_/\___|_\___/ .__/\___|_|   (_) |___/\_,_|_|_|_\__,_|_||_| (_)_/ \_\ "
echo "                        |_|                         |_|                          "
echo "-_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-_--_-_-_-"

echo -e "\n"

echo "--------------------[ Deaflut Directory Used : $destdir ]---------------------"

echo -e "\n"
#if [ -z "$destdir" -a "$destdir" == " " ]
#        then
#         _dashBanner
#		 destdir=/home/oracle/DBHC
#         #echo " Default destination directory is used:"
#         #_banner
#  else
#        _dashBanner $destdir
#        #echo "The destination directory for logs is $destdir :"
#        #_banner
#fi

#_choiceList(){
#                if [$1 | $2 -eq 0 ]
#}

# List the running databases in Server
myarr=($(ps -ef |grep smon | awk -F'_' '{print $3}'))

# Enter the database to run the health check up :
echo "------------------------[ List of instance running on box ]--------------------------"
#_dashBanner "List of instance running."
for i in "${myarr[@]}"
	do :
	echo -e "\t For "$i "Database Instance: "$i 
	done
printf  'Enter the database instance for which Health Check should be Performed : '
read -r instance

# Get the environment variables for the respective instance
		# Get the ORACLE sid
        export ORACLE_SID=`echo $instance`
		#ASM=$(cat /etc/oratab | awk -F':' '{print $1}'| grep $instance)

        # Get the Database home
        ORAHOME=$(cat /etc/oratab | awk -F"$instance" '{print $2}'| awk -F':' '{print $2}')

	if [ ! -z "$ORAHOME" -a "$ORAHOME" != " "]
		then
			export ORAHOME=`echo $ORAHOME`
	else 
			export ORAHOME=`echo $ORACLE_HOME`
	fi
		

export DATE_TIME=`date +%d_%m_%Y`
export FILE_NAME=$destdir"/DBarchitecture_"$instance"_DBHC_"$DATE_TIME".log"

##############################################
# Log in to the sqlplus session.
##############################################

$ORAHOME/bin/sqlplus '/ as sysdba' << EOF

SPOOL $FILE_NAME

set linesize 200
set pages 100
column name format a50
column comp_name format a50
column member format a60
COLUMN FILE_NAME FORMAT A60
COLUMN TABLESPACE_NAME FORMAT A30
column platform_name format a30

----************************************
---- Basic Database Info
----************************************

select dbid,name, FLASHBACK_ON, PLATFORM_NAME,DATABASE_ROLE from v\$database;

----************************************
---- List the version of the database 
----************************************

select * from v\$version;

----************************************
---- List the components of dba registry
----************************************
 
select comp_name, version, status from dba_registry order by comp_name;


----************************************
---- View the database size and its usage
----************************************

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


----********************************************************
---- List the log groups along with their members and size
----********************************************************

select a.group#, a.thread#,bytes/(1024*1024) SIZE_MB, b.member from v\$log a, v\$logfile b where a.group#=b.group# order by a.group#;



----********************************************************
---- List the standby log groups with their members and size
----********************************************************

select a.group#, a.thread#,bytes/(1024*1024) SIZE_MB, b.member from v\$standby_log a, v\$logfile b where a.group#=b.group# order by a.group#;


----********************************************************
---- List the tablespace info and its usage
----********************************************************

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


----********************************************************
---- Control file information
----********************************************************

select name, STATUS,IS_RECOVERY_DEST_FILE , BLOCK_SIZE, FILE_SIZE_BLKS  from v\$controlfile order by name;


----********************************************************
---- Health of system and sysaux tablespaces
----********************************************************

select sum(bytes/1024/1024) from dba_segments
where tablespace_name = 'SYSTEM'
and owner not in ('SYS','SYSTEM');


----********************************************************
---- Select the space of system tablespace consumed by users other then sys and system
----********************************************************

select owner, segment_name, segment_type
from dba_segments
where tablespace_name = 'SYSTEM'
and owner not in ('SYS','SYSTEM');


----********************************************************
------ Temporary Tablespace in Database
----********************************************************

select tablespace_name, sum(bytes)/1024/1024 "Size in MB"
from dba_temp_files
group by tablespace_name;


----********************************************************
---- Users Information
----********************************************************

select username, default_tablespace, temporary_tablespace, account_status,EXPIRY_DATE from dba_users order by username;



----********************************************************
---- Wallet Information
----********************************************************

select * from v\$encryption_wallet;



----********************************************************
---- Archive Information
----********************************************************

archive log list;


----********************************************************
---- last 15 days archive status
----********************************************************

select to_char(COMPLETION_TIME,'DD/MM/YYYY HH24:MI:SS') "Archived Date",sequence#, archived, applied from v\$archived_log where COMPLETION_TIME >= sysdate -3 order by sequence#; 



----********************************************************
---- last 100 archive sequence status
----********************************************************

select THREAD#, sequence#, archived, applied from (select THREAD#, sequence#, archived, applied from v\$archived_log order by sequence# desc) where rownum <=100 order by sequence#; 


----********************************************************
---- Dataguard Information 
----********************************************************

show parameter remote_login
select force_logging from v\$database;
show parameter db_name;
show parameter memory_target;
show parameter memory_max_target;
show parameter db_unique_name;
show parameter archive_lag_target;
show parameter compatible;
show parameter control_files;
show parameter db_create_file_dest;
show parameter DB_CREATE_ONLINE_LOG_DEST;
show parameter db_recovery_file_dest;
show parameter log_archive_config;
show parameter log_archive_max_processes;
show parameter log_archive_dest_1;
show parameter log_archive_dest_state_1;
show parameter log_archive_dest_2;
show parameter log_archive_dest_state_2;
show parameter fal_server;
show parameter fal_client;
show parameter standby_file_management;
show parameter db_file_name_convert;
show parameter log_file_name_convert;


----********************************************************
---- Check for the redo transport
----********************************************************

select status , error from v\$archive_dest where dest_id=2;


----********************************************************
---- Data guard archive log status  
----********************************************************

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

select to_char(START_TIME,'DD/MM/YYYY HH24:MI') "Start Time", to_char(END_TIME,'DD/MM/YYYY HH24:MI') "End Time",
round(INPUT_BYTES/1024/1024,2) "BK Input Size: MB",round(OUTPUT_BYTES/1024/1024,2) "BK Output Size: MB",
OUTPUT_DEVICE_TYPE "Backup To",STATUS "Status",INPUT_TYPE "Backup Type",TIME_TAKEN_DISPLAY "Total Time"
from V\$RMAN_BACKUP_JOB_DETAILS
where sysdate - START_TIME < 30 order by 1 desc; 


---- ***************************************************
---- log switch information
----********************************************************

set pages 999;
select to_char(first_time,'DD-MON-RR') "Date",
to_char(sum(decode(to_char(first_time,'HH24'),'00',2,0)),'99') " 00",
to_char(sum(decode(to_char(first_time,'HH24'),'01',2,0)),'99') " 01",
to_char(sum(decode(to_char(first_time,'HH24'),'02',2,0)),'99') " 02",
to_char(sum(decode(to_char(first_time,'HH24'),'03',2,0)),'99') " 03",
to_char(sum(decode(to_char(first_time,'HH24'),'04',2,0)),'99') " 04",
to_char(sum(decode(to_char(first_time,'HH24'),'05',2,0)),'99') " 05",
to_char(sum(decode(to_char(first_time,'HH24'),'06',2,0)),'99') " 06",
to_char(sum(decode(to_char(first_time,'HH24'),'07',2,0)),'99') " 07",
to_char(sum(decode(to_char(first_time,'HH24'),'08',2,0)),'99') " 08",
to_char(sum(decode(to_char(first_time,'HH24'),'09',2,0)),'99') " 09",
to_char(sum(decode(to_char(first_time,'HH24'),'10',2,0)),'99') " 10",
to_char(sum(decode(to_char(first_time,'HH24'),'11',2,0)),'99') " 11",
to_char(sum(decode(to_char(first_time,'HH24'),'12',2,0)),'99') " 12",
to_char(sum(decode(to_char(first_time,'HH24'),'13',2,0)),'99') " 13",
to_char(sum(decode(to_char(first_time,'HH24'),'14',2,0)),'99') " 14",
to_char(sum(decode(to_char(first_time,'HH24'),'15',2,0)),'99') " 15",
to_char(sum(decode(to_char(first_time,'HH24'),'16',2,0)),'99') " 16",
to_char(sum(decode(to_char(first_time,'HH24'),'17',2,0)),'99') " 17",
to_char(sum(decode(to_char(first_time,'HH24'),'18',2,0)),'99') " 18",
to_char(sum(decode(to_char(first_time,'HH24'),'19',2,0)),'99') " 19",
to_char(sum(decode(to_char(first_time,'HH24'),'20',2,0)),'99') " 20",
to_char(sum(decode(to_char(first_time,'HH24'),'21',2,0)),'99') " 21",
to_char(sum(decode(to_char(first_time,'HH24'),'22',2,0)),'99') " 22",
to_char(sum(decode(to_char(first_time,'HH24'),'23',2,0)),'99') " 23"
from v\$log_history
where first_time-sysdate <30
group by to_char(first_time,'DD-MON-RR')
order by 1;



----********************************************************
---- ASM Disk Information
----********************************************************

set linesize 500
column name format a30
column COMPATIBILITY format a20
column DATABASE_COMPATIBILITY format a20
column FREE_MB format a20
column type format a20

select GROUP_NUMBER GROUP_NO ,NAME,STATE, TYPE,(TOTAL_MB/(1024)) total_GB  , (FREE_MB/1024) free_GB  from  v\$asm_diskgroup order by group_number, name;
select GROUP_NUMBER GROUP_NO ,NAME,REQUIRED_MIRROR_FREE_MB ,USABLE_FILE_MB,OFFLINE_DISKS,COMPATIBILITY ,DATABASE_COMPATIBILITY  from v\$asm_diskgroup order by group_number, name;



----********************************************************
---- Begin spooling for Memory Advisor
----********************************************************

select name, open_mode, database_role from v\$database;

show parameter memory;

show parameter sga;

show parameter pga;

select * from v\$memory_target_advice;

select * from v\$sga_target_advice;

select pga_target_for_estimate, pga_target_factor, ESTD_PGA_CACHE_HIT_PERCENTAGE from v\$pga_target_advice;

-- ************************************************
-- Display pga target advice
-- ************************************************

SELECT
   ROUND(pga_target_for_estimate /(1024*1024)) c1,
   estd_pga_cache_hit_percentage         c2,
   estd_overalloc_count                  c3
FROM
   v\$pga_target_advice;

-- ************************************************
-- Display pga target advice histogram
-- ************************************************
 
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
   
spool off;

EOF

#quit

# Clear the screen
clear

echo -e "\n"
echo "--------------------[ Collecting logs and metrics For Operating System ]---------------------"
printf "\tDo you Prefer to collect O/S info [Y | N] : "
read -r oschoice

#echo $oschoice

if [ "$oschoice" == "Y" ]
  then
	_banner "COLLECTING Logs and redirect out put ot osinfo"

	_banner "COLLECTING Logs and redirect out put ot osinfo" >> $destdir/osinfo.log
	date > $destdir/osinfo.log

	_printNewline >> $destdir/osinfo.log ## for new line.

	echo ===== Gathering the host file info =======>>$destdir/osinfo.log
	cat /etc/hosts >> $destdir/osinfo.log

	_printNewline >> $destdir/osinfo.log ## for new line.

	echo ===== Gathering the user info ============>> $destdir/osinfo.log
	cat /etc/passwd >> $destdir/osinfo.log

	_printNewline >> $destdir/osinfo.log ## for new line.

	echo ==== Gathering the user info =============>> $destdir/osinfo.log
	cat /etc/group >> $destdir/osinfo.log

	_printNewline >> $destdir/osinfo.log ## for new line.

	echo "=========== Virtual memory statistics =========" >> $destdir/osinfo.log
	vmstat >> $destdir/osinfo.log

	_printNewline >> $destdir/osinfo.log ## for new line.

	echo "=========== Input/output statistics ===========" >> $destdir/osinfo.log
	iostat >> $destdir/osinfo.log

	_printNewline >> $destdir/osinfo.log ## for new line.

	echo "=========== Track System files modification date ===========" >> $destdir/osinfo.log
	ls -ltr /etc/hosts /etc/passwd /etc/group /etc/hosts /etc/resolv.conf >> $destdir/osinfo.log

	_printNewline  ## for new line.
	_banner "COLLECTING INFORMATION SPECIFIC TO O/S"
	_banner "COLLECTING INFORMATION SPECIFIC TO O/S" >> $HOME/DBHC/osinfo.log
	echo "Copy the O/S info files:" >> $HOME/DBHC/osinfo.log
	#echo "Copy the O/S info files:"
	#cp  ~/.profile $HOME/DBHC/
	#cp -r $ORACLE_HOME/network/admin $HOME/DBHC/
	#cp -r $ORACLE_HOME/dbs $HOME/DBHC/
	cp -r /etc/hosts $HOME/DBHC/
	cp -r /etc/passwd $HOME/DBHC/
	cp -r /etc/group $HOME/DBHC/
	
	_printNewline  ## for new line.
	_banner "COLLECTING INFORMATION SPECIFIC TO PLATFORM"
	_banner "COLLECTING INFORMATION SPECIFIC TO PLATFORM" >> $HOME/DBHC/osinfo.log
	echo " AIX: For AIX"
	echo " HP: For HP-UX"
	echo " LX: For Linux"
	echo " SL: For Solaris"
	echo "########################################################"
	echo -e "\n"
	printf "Please Enter the Platform in which you are executing Script from above list : "
	read -r platform
	case "$platform" in
    		'AIX')
        	#####################################################
        	# Your Platform is IBM-AIX and Collecting Data      #
        	#####################################################
                	_banner "Your Platform is IBM-AIX and Collecting Data " >> $HOME/DBHC/osinfo.log
                	echo "==================== File system Info ================" $HOME/DBHC/osinfo.log
                	df -g >> $HOME/DBHC/osinfo.log
                	_printNewline >> $HOME/DBHC/osinfo.log ## for new line.
                	echo "Collect the environment variables set in profle." >> $HOME/DBHC/osinfo.log
                	echo ~/.profile >> $HOME/DBHC/osinfo.log
                	_printNewline >> $HOME/DBHC/osinfo.log ## for new line.
                	echo "==== Swap Info and Memory =====" >> $HOME/DBHC/osinfo.log
                	/usr/sbin/lsattr -E -l sys0 -a realmem  >> $HOME/DBHC/osinfo.log
                	_printNewline >> $HOME/DBHC/osinfo.log ## for new line.
                	/usr/sbin/lsps -a >>$HOME/DBHC/osinfo.log
        	;;
    		'HP')
       		#####################################################
        	# Your Platform is HP-UX and Collecting Data        #
        	#####################################################
                	_banner "Your Platform is HP-UX and Collecting Data" >> $HOME/DBHC/osinfo.log
                	echo "==================== File system Info ================" $HOME/DBHC/osinfo.log
                	bdf >> $HOME/DBHC/osinfo.log
                	_printNewline "\n" >> $HOME/DBHC/osinfo.log ## for new line.
                	echo "Collect the environment variables set in profle." >> $HOME/DBHC/osinfo.log
                	echo ~/.profile >> $HOME/DBHC/osinfo.log
                	_printNewline >> $HOME/DBHC/osinfo.log ## for new line.
                	echo "==== Swap Info and Memory =====" >> $HOME/DBHC/osinfo.log
                	/usr/contrib/bin/machinfo | grep -i Memory >>$HOME/DBHC/osinfo.log
                	_printNewline >> $HOME/DBHC/osinfo.log ## for new line.
               		/usr/sbin/swapinfo -a >>$HOME/DBHC/osinfo.log
        	;;
    		'LX')
        	#####################################################
        	# Your Platform is linux and Collecting Data        #
        	#####################################################
                	_banner "Your Platform is Linux and Collecting Data" >> $HOME/DBHC/osinfo.log
                	echo "==================== File system Info ================" >> $HOME/DBHC/osinfo.log
                	df -h >> $HOME/DBHC/osinfo.log

               		_printNewline >> $HOME/DBHC/osinfo.log ## for new line.
                	echo "Collect the environment variables set in profle." >> $HOME/DBHC/osinfo.log
                	echo ~/.bash_profile >> $HOME/DBHC/osinfo.log

                	_printNewline >> $HOME/DBHC/osinfo.log ## for new line.

                	echo "==== Swap Info and Memory =====" >> $HOME/DBHC/osinfo.log
                	cat /proc/meminfo | grep "Mem" >>$HOME/DBHC/osinfo.log

                	_printNewline >> $HOME/DBHC/osinfo.log ## for new line.
                	cat /proc/meminfo | grep "Swap" >>$HOME/DBHC/osinfo.log
        	;;
    		'SL')
        	#####################################################
        	# Your Platform is Solaris and Collecting Data      #
       		#####################################################
                	_banner "Your Platform is Solaris and Collecting Data"  >> $HOME/DBHC/osinfo.log
                	echo "==================== File system Info ================" >> $HOME/DBHC/osinfo.log
                	df -h >> $HOME/DBHC/osinfo.log
            		_printNewline >> $HOME/DBHC/osinfo.log ## for new line.
                	echo "Collect the environment variables set in profle." >> $HOME/DBHC/osinfo.log
                	echo ~/.profile >> $HOME/DBHC/osinfo.log
                	_printNewline >> $HOME/DBHC/osinfo.log ## for new line.
                	echo "==== Swap Info and Memory =====" >> $HOME/DBHC/osinfo.log
                	/usr/sbin/prtconf | grep "Memory size" >> $HOME/DBHC/osinfo.log
                	_printNewline >> $HOME/DBHC/osinfo.log ## for new line.
                	/usr/sbin/swap -s >>$HOME/DBHC/osinfo.log
        	;;
	esac
else 
echo -e "\n"
echo "-----------------[ Collecting logs and metrics For Operating System Skipped ]-------------------"
fi

sleep 2
# Clear Screen
clear

##############################################################
# RAC information                                           ##
#                                                           ##
##############################################################
echo -e "\n"
echo -e "\n" >> $destdir/racinfo.log ## for new line.
echo -e "\n" >> $destdir/racinfo.log ## for new line.

echo -e "\n"
echo "-----------------[ Collecting logs and metrics For Oracle Clusterware ]-------------------"
echo "-----------------[ Collecting logs and metrics For Oracle Clusterware ]-------------------" >> $destdir/racinfo.log

#_banner "ORACLE CLUSTERWARE INFORMATION AND ITS SERVICES STATUS"
#_banner "ORACLE CLUSTERWARE INFORMATION AND ITS SERVICES STATUS" >> $destdir/racinfo.log
echo -e "\n" >> $HOME/DBHC/racinfo.log ## for new line.
#echo " 1: Yes it is RAC-node."
#echo " 2: No its standalone."
echo "########################################################"
printf "Do you wish to collect information related to Oracle Clusterware [Y | N] : "
read -r racinfo
if [ "$racinfo" == "Y" ]
then

echo -e "\n"

printf "Is this node Rac [Y | N] : "
read -r mtype
case "$mtype" in
    'Y')
        # Set the proper environment variables run the commands from grid home

        # Get the ASM sid
        ASM=$(cat /etc/oratab | awk -F':' '{print $1}'| grep +ASM)

        # Get the Grid home
        ASMHOME=$(cat /etc/oratab | awk -F':' '{print $2}'| grep grid)

        # set the obtained variables in respective variables
        export ORACLE_SID=$ASM
        PATH=$PATH:$ASMHOME/bin
                _banner "Instance type is RAC"
                _banner "Instance type is RAC" >> $destdir/racinfo.log

                # Get the crs information
                _banner "Get the crs information" >> $destdir/racinfo.log
                crsctl check crs >> $destdir/racinfo.log

                _printNewline >> $destdir/osinfo.log ## for new line.

                # Get the information of overall cluster
                _banner "Get the information of overall cluster" >> $destdir/racinfo.log
                crsctl check cluster -all >> $destdir/racinfo.log

                _printNewline >> $destdir/osinfo.log ## for new line.

                # Get the information of the services
                _banner "Get the information of the services" >> $destdir/racinfo.log
                crsctl stat res -t >> $destdir/racinfo.log

                _printNewline >> $destdir/osinfo.log ## for new line.

                # Get the OCR and Voting Disk information
                _banner "Get the Ocr information" >> $destdir/racinfo.log
                ocrcheck >> $destdir/racinfo.log

                _printNewline >> $destdir/osinfo.log ## for new line.

                _banner "Get the Voting Disk information" >> $destdir/racinfo.log
                crsctl query css votedisk >> $destdir/racinfo.log

                _printNewline >> $destdir/osinfo.log ## for new line.

                SCRIPTHOST=$(hostname| awk -F'.' '{print $1}')

                # Get the list 1000 lines of cluster logfile
                _banner "Get the list 1000 lies of the cluster logfile" >> $destdir/racinfo.log
                tail -1000 $ASMHOME/log/$SCRIPTHOST/alert$SCRIPTHOST.log >> $destdir/racinfo.log
        ;;
    'N')
        echo "In progress"
                echo "Instance type is Standalone" >> $destdir/racinfo.log
        ;;
esac

else
	echo -e "\n"
	echo "-----------------[ Collecting logs and metrics For Oracle Clusterware was skipped. ]-------------------"
fi

 echo "-----------------[ Log, metrics and statistics collection completed. ]-------------------"

sleep 2
clear
