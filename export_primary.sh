#!/bin/bash
# export_primary.sh - Run this on the PRIMARY server

DUMP_FILE="/tmp/primary_dump.sql.gz"

if [ "$EUID" -ne 0 ]; then
  echo "Must run with sudo"
  exit 1
fi

echo -e "\033[0;33m=== Exporting Primary Database ===\033[0m"

# Dump all databases with binary log position
echo -e "\033[0;36mDumping databases...\033[0m"
mysqldump --all-databases \
  --single-transaction \
  --source-data=2 \
  --routines \
  --triggers \
  --events | gzip > "$DUMP_FILE"

if [ $? -ne 0 ]; then
  echo -e "\033[0;31mError: Failed to dump databases\033[0m"
  exit 1
fi

# Extract and display binary log position
echo -e "\n\033[0;36mReplication coordinates:\033[0m"
zcat "$DUMP_FILE" | grep "CHANGE MASTER TO" | head -1

echo -e "\n\033[0;32m✓ Export completed: $DUMP_FILE\033[0m"
echo -e "\033[0;33mTransfer this file to replica servers\033[0m"
