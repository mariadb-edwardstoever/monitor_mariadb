#!/bin/bash
# Script by Edward Stoever for MariaDB Support

# Tested on 10.6.12-7-MariaDB-enterprise

# Written to record CPU, Redo Log Occupancy, number of transactions, number of sessions
# once per minute

# Ref CS0573249

# Comment out the line for CSV_OUTPUT to insert into database table
# CSV_OUTPUT=TRUE
CSV_FILE=/tmp/$(hostname)_monitor_mariadb.csv

# IF NOT OUPUTTING TO EXTERNAL CSV FILE, REQUIRES DATABASE OBJECTS:
#
# CREATE SCHEMA if not exists `monitor_hist`;
# use monitor_hist;
#
#CREATE TABLE `monitor_history` (
#  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
#  `tick` timestamp NOT NULL DEFAULT current_timestamp(),
#  `hostname` varchar(128) DEFAULT NULL,
#  `mariadbd_cpu_pct` decimal(5,2) DEFAULT NULL,
#  `redo_log_occupancy` decimal(5,2) DEFAULT NULL,
#  `threads_running` int(11) DEFAULT NULL,
#  `handler_read_rnd_next` bigint(20) DEFAULT NULL,
#  `com_select` bigint(20) DEFAULT NULL,
#  `com_dml` bigint(20) DEFAULT NULL,
#  PRIMARY KEY (`id`)
#) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci

# NOTE, YOU MAY NEED TO CHANGE the mariadb commands below to include -u and -p for username and password:
# add -u -p if needed. accessing via socket works best. This script must be run on localhost to capture CPU from top.
MDB_COMMAND="/usr/bin/mariadb" 

# Ref https://mariadb.com/kb/en/innodb-redo-log/#determining-the-redo-log-occupancy
SQL="select VARIABLE_VALUE 
     from information_schema.global_status 
     where VARIABLE_NAME='INNODB_CHECKPOINT_AGE' limit 1;"

CHECKPOINT_AGE=$($MDB_COMMAND -ABNe "$SQL")
####### LOG_FILES_IN_GROUP
# For 10.5 and higher, LOG_FILES_IN_GROUP is always 1. 
# For 10.4 and prior, get this value: show global variables like 'innodb_log_files_in_group';
LOG_FILES_IN_GROUP=1
#######

SQL="select format(($CHECKPOINT_AGE/(VARIABLE_VALUE * $LOG_FILES_IN_GROUP)) * 100,2) as PCT 
     from information_schema.global_variables
     where VARIABLE_NAME='INNODB_LOG_FILE_SIZE' limit 1;"
REDO_LOG_OCCUPANCY=$($MDB_COMMAND -ABNe "$SQL")

SQL="select VARIABLE_VALUE 
     from information_schema.global_status 
     where VARIABLE_NAME='THREADS_RUNNING' limit 1;"
THREADS_RUNNING=$($MDB_COMMAND -ABNe "$SQL")

SQL="select variable_value 
     from information_schema.GLOBAL_STATUS 
     where variable_name='HANDLER_READ_RND_NEXT';"
HANDLER_READ_RND_NEXT=$($MDB_COMMAND -ABNe "$SQL")

SQL="select variable_value 
     from information_schema.GLOBAL_STATUS 
     where variable_name='COM_SELECT';"
COM_SELECT=$($MDB_COMMAND -ABNe "$SQL")

SQL="select sum(VARIABLE_VALUE) 
     from information_schema.global_status 
     where VARIABLE_NAME in ('COM_INSERT','COM_UPDATE','COM_DELETE');"
COM_DML=$($MDB_COMMAND -ABNe "$SQL")
MARIADB_TOP_CPU_PCT=$(top -bn1 -p $(pidof mariadbd) | tail -1 | awk '{print $9}')

if [ ! $CSV_OUTPUT ]; then
  SQL="INSERT INTO monitor_hist.monitor_history 
  (hostname, mariadbd_cpu_pct, redo_log_occupancy, threads_running, handler_read_rnd_next, com_select, com_dml) 
  VALUES 
  (@@hostname, $MARIADB_TOP_CPU_PCT, $REDO_LOG_OCCUPANCY, $THREADS_RUNNING, $HANDLER_READ_RND_NEXT, $COM_SELECT, $COM_DML);"
  $MDB_COMMAND -ABNe "$SQL"
else

  if [ -f $CSV_FILE ]; then
    ID=$(tail -1 $CSV_FILE | cut -d"," -f1 | xargs)
  else
    ID=0;
  fi

  ID=$(( $ID + 1 ))

  printf "$ID,\"$(date "+%Y-%m-%d %H:%M:%S")\",\"$(hostname)\",\"$MARIADB_TOP_CPU_PCT\",\"$REDO_LOG_OCCUPANCY\",\"$THREADS_RUNNING\",\"$HANDLER_READ_RND_NEXT\",\"$COM_SELECT\",\"$COM_DML\n" >> $CSV_FILE

fi
