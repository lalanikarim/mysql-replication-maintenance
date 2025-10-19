#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Must run with sudo"
  exit 1
fi

# Get replica status
output=$(mysql -e "SHOW REPLICA STATUS\G" 2>/dev/null)

if [ -z "$output" ]; then
  echo "Error: Cannot connect to MySQL"
  exit 1
fi

# Extract status
io_running=$(echo "$output" | awk '/Replica_IO_Running:/ {print $2}')
sql_running=$(echo "$output" | awk '/Replica_SQL_Running:/ {print $2}')
last_errno=$(echo "$output" | awk '/Last_SQL_Errno:/ {print $2}')

echo -e "IO: \033[0;32m$io_running\033[0m | SQL: \033[0;32m$sql_running\033[0m"

# Check if running
if [[ "$io_running" == "Yes" ]] && [[ "$sql_running" == "Yes" ]]; then
  echo -e "\033[0;32mReplica is running\033[0m"
  exit 0
fi

# Handle SQL thread error
if [[ "$sql_running" != "Yes" ]] && [[ "$last_errno" != "0" ]]; then
  echo -e "\033[0;33mSQL thread stopped with error $last_errno. Skipping and restarting...\033[0m"
  mysql -e "STOP REPLICA; SET GLOBAL sql_replica_skip_counter = 1; START REPLICA;"
else
  echo -e "\033[0;31mReplica stopped. Check logs manually.\033[0m"
  exit 1
fi
