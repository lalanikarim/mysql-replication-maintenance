# MySQL Replication Maintenance

This repository contains scripts for maintaining MySQL master-replica replication during maintenance windows.

## Scripts

### `export_primary.sh`
**Run on PRIMARY server**
- Creates a compressed dump of all databases with binary log coordinates
- Outputs replication position for replica synchronization
- Requires sudo privileges

### `import_replica.sh`
**Run on each REPLICA server**
- Imports the dump file and configures replication
- Automatically stops replica, imports data, updates coordinates, and restarts
- Shows final replica status
- Requires sudo privileges

### `verify_replica.sh`
**Run on REPLICA servers for monitoring**
- Checks replica IO and SQL thread status
- Automatically skips SQL errors and restarts if needed
- Provides color-coded status output
- Requires sudo privileges

## Usage

1. **Export from primary**: `sudo ./export_primary.sh`
2. **Transfer** `/tmp/primary_dump.sql.gz` to replica servers
3. **Import on replicas**: `sudo ./import_replica.sh`
4. **Verify status**: `sudo ./verify_replica.sh`

## Requirements

- MySQL server with replication configured
- Sudo privileges on all servers
- Network access between primary and replica servers
