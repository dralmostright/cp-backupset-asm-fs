#!/bin/bash
##
## Author :
## Company :
## Description : Archive backups
##

##
## Directory for Backup Base
##
BACKUPTANSFERBASE='/home/oracle/scripts'

##
## Parameter to hold all backup details which were successful
## No update required, generated automatically by script
##
BACKUPALL=""

##
## Parameter to get last backup archive date
## No update required, generated automatically by script
##
LASTTRASFERDATE=""

##
## Parameter to hold all backup pieces which were successful 
## No update required, generated automatically by script
##
BACKUPDETAILS=""

##
## Parameter to get backup which started from [COPYSTARTTIME]
## No update required, generated automatically by script
##
COPYSTARTTIME=""

##
## Parameter to get backup which ended on  [COPYSTARTTIME]
## No update required, generated automatically by script
##
COPYENDTIME=""

##
## Parameter to filter which backsets to include
## No update required, generated automatically by script
##
BACKUPFILTER=""

##
## Parameter to be set where desired backupsets are to be copied
##
BACKUPCPDEST="/archive/bkcopy"

##
## Backupsets to copy
## No update required, generated automatically by script
##
BACKUPSETS=""

LASTTRASFERDATE=`cat ${BACKUPTANSFERBASE}/confs/backup.lck`
if [ -z ${LASTTRASFERDATE} ]
then
  echo "i am null"
else
BACKUPFILTER=" and end_time > to_date('${LASTTRASFERDATE}', 'YYYYMMDDHH24MISS')"
echo ${LASTTRASFERDATE}
fi
echo ${BACKUPFILTER}

##
## Function will get backup start and end time based on parameter [LASTTRASFERDATE]
##
funGetBackupTime(){
BACKUPALL=$($ORACLE_HOME/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
alter session set NLS_DATE_FORMAT='YYYYMMDDHH24MISS';
select end_time, start_time from v\$RMAN_BACKUP_JOB_DETAILS where status like 'COMPLETED%' ${BACKUPFILTER} order by 1 desc;
END
)
}

funGetBackupTime

if [ -z "${BACKUPALL}" ]
then
echo "No backups to transfer"
else 
echo "${BACKUPALL}"
fi
COPYSTARTTIME=`echo ${BACKUPALL}| awk '{ print $NF }'`
COPYENDTIME=`echo ${BACKUPALL}| awk '{ print $1 }'`

echo "Starttime"${COPYSTARTTIME}
echo "Endtime"${COPYENDTIME}
echo ${LASTTRASFERDATE}
echo ${BACKUPALL}

funGetBackupDetails(){
BACKUPDETAILS=$($ORACLE_HOME/bin/rman target / <<END
list backup completed between "to_date('${COPYSTARTTIME}','YYYYMMDDHH24MISS')" and "to_date('${COPYENDTIME}','YYYYMMDDHH24MISS')";
END
)
##
## Get piece names
##
BACKUPSETS=`echo "${BACKUPDETAILS}" |grep "Piece Name:" |  awk '{ print $NF }'`

}
echo ${BACKUPDETAILS}
BACKUPSETS=`echo "${BACKUPDETAILS}" |grep "Piece Name:" |  awk '{ print $NF }'`
echo "${BACKUPSETS}"
exit 0;
copyBACKUP(){
for i in ${BACKUPSETS}
do
cp $i ${BACKUPCPDEST}
echo $i
echo "========="
echo "successful"
done
}
copyBACKUP
echo ${COPYENDTIME} > ${BACKUPTANSFERBASE}/confs/backup.lck
