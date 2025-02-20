#!/bin/bash

DATEYMD=$(date +%Y%m%d)
BACKUP_DIR="/mnt/backups/system/$DATEYMD"
LOG_DIR="/mnt/backups/logs"
LOG_FILE="$LOG_DIR/${DATEYMD}_system_backup.log"



# Create backup directory
mkdir -p "$BACKUP_DIR"

{
    # Starting script
    echo "Starting system backup at: $(date)"
    echo "Backup directory: $BACKUP_DIR"

    # The --one-file-system option prevents crossing filesystem boundaries
    # --hard-links preserves hard links
    # --acls and --xattrs preserve extended attributes
    sudo rsync -aAXv --one-file-system --hard-links \
        --exclude="/mnt/" \
        / "$BACKUP_DIR"

    # 2. System Information Files
    # Partition layout
    sudo fdisk -l > "$BACKUP_DIR/partition_layout.txt"
    # Disk UUIDs
    sudo blkid > "$BACKUP_DIR/disk_uuids.txt"

    # Set appropriate permissions
    sudo chown -R chris:chris "$BACKUP_DIR"
    sudo chmod -R 600 "$BACKUP_DIR"

    echo "System backup completed at: $BACKUP_DIR."

} > "$LOG_FILE" 2>&1

echo "Logs available at: $LOG_FILE"