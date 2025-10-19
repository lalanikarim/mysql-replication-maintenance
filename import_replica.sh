#!/bin/bash
# import_replica.sh - Run this on each REPLICA server

DUMP_FILE="/tmp/primary_dump.sql.gz"

if [ "$EUID" -ne 0 ]; then
  echo "Must run with sudo"
  exit 1
fi

if [ ! -f "$DUMP_FILE" ]; then
  echo -e "\033[0;31mError: Dump file not found: $DUMP_FILE\033[0m"
  exit 1
fi

echo -e "\033[0;33m=== Importing to Replica ===\033[0m"

# Step 1: Extract binary log position from dump
echo -e "\033[0;36mStep 1: Extracting replication coordinates...\033[0m"
log_file=$(zcat "$DUMP_FILE" | grep "CHANGE MASTER TO" | sed -n "s/.*MASTER_LOG_FILE='\([^']*\)'.*/\1/p")
log_pos=$(zcat "$DUMP_FILE" | grep "CHANGE MASTER TO" | sed -n "s/.*MASTER_LOG_POS=\([0-9]*\).*/\1/p")

if [ -z "$log_file" ] || [ -z "$log_pos" ]; then
  echo -e "\033[0;31mError: Could not extract binary log position\033[0m"
  exit 1
fi

echo -e "\033[0;32m✓ Log File: $log_file, Position: $log_pos\033[0m"

# Step 2: Stop replica
echo -e "\033[0;36mStep 2: Stopping replica...\033[0m"
mysql -e "STOP REPLICA;"
echo -e "\033[0;32m✓ Replica stopped\033[0m"

# Step 3: Import dump
echo -e "\033[0;36mStep 3: Importing databases...\033[0m"
zcat "$DUMP_FILE" | mysql

if [ $? -ne 0 ]; then
  echo -e "\033[0;31mError: Failed to import dump\033[0m"
  exit 1
fi

echo -e "\033[0;32m✓ Import completed\033[0m"

# Step 4: Update replication coordinates
echo -e "\033[0;36mStep 4: Updating replication coordinates...\033[0m"
mysql -e "CHANGE REPLICATION SOURCE TO SOURCE_LOG_FILE='$log_file', SOURCE_LOG_POS=$log_pos;"

if [ $? -ne 0 ]; then
  echo -e "\033[0;31mError: Failed to update replication coordinates\033[0m"
  exit 1
fi

echo -e "\033[0;32m✓ Replication coordinates updated\033[0m"

# Step 5: Start replica
echo -e "\033[0;36mStep 5: Starting replica...\033[0m"
mysql -e "START REPLICA;"
echo -e "\033[0;32m✓ Replica started\033[0m"

# Step 6: Show status
echo -e "\n\033[0;33m=== Replica Status ===\033[0m"
mysql -e "SHOW REPLICA STATUS\G" | grep -E "Replica_IO_Running:|Replica_SQL_Running:|Seconds_Behind_Source:"

echo -e "\n\033[0;32m✓ Import completed\033[0m"
