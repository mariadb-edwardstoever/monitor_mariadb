# monitor_mariadb
Record CPU and other stats once per minute to determine overall working state


Decide whether you prefer output to a database table or to a CSV file. 
Comment out CSV_OUTPUT to send output to the database table. Create schema and table with monitor_hist.sql.
You can change the mariadb command to one that includes user and password if needed. Ensure enough privileges so that user gets all the needed statistics. 
You should run this from the localhost of the database server being monitored so that you capture the CPU statistic from top.
Run script monitor_mariadb.sh from crontab every minute.

Attach the CSV to a support ticket. In the case of stats saved to a table, dump the contents of the table with mariadb-dump:
mariadb-dump monitor_hist monitor_history > monitor_history.sql
