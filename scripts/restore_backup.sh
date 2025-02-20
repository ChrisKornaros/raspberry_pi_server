#!/bin/bash

# Check if a backup directory was provided
if [ $# -ne 1 ]; then
    echo "Error: Please provide the backup directory path"
    echo "Usage: $0 /path/to/backup/directory"
    exit 1
fi

BACKUP_DIR=$1
LOG_DIR="/mnt/backup/logs"
DATEYMD=$(date +%Y%m%d)
LOG_FILE="$LOG_DIR/${DATEYMD}_restore.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Start logging
{
    echo "Starting system restore at: $(date)"
    echo "Restoring from: $BACKUP_DIR"

    # Check if backup directory exists
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Error: Backup directory does not exist"
        exit 1
    fi

    # Verify we're not trying to restore from an empty directory
    if [ -z "$(ls -A $BACKUP_DIR)" ]; then
        echo "Error: Backup directory is empty"
        exit 1
    }

    echo "Warning: This will overwrite current system files."
    echo "Please type 'yes' to continue:"
    read -r response
    if [ "$response" != "yes" ]; then
        echo "Restore cancelled by user"
        exit 1
    fi

    # Perform the restore using rsync
    # -a: archive mode (preserves permissions, timestamps, etc.)
    # -A: preserve ACLs
    # -X: preserve extended attributes
    # -v: verbose
    # --delete: remove files in destination that aren't in source
    sudo rsync -aAXv --delete \
        --exclude="/proc/*" \
        --exclude="/sys/*" \
        --exclude="/dev/*" \
        --exclude="/run/*" \
        --exclude="/mnt/*" \
        --exclude="/media/*" \
        --exclude="/tmp/*" \
        "$BACKUP_DIR/" /

    echo "Restore completed at: $(date)"
    echo "System should be rebooted to complete restore"
    
} > "$LOG_FILE" 2>&1

echo "Restore complete. Logs available at: $LOG_FILE"
echo "Please reboot your system to complete the restore process."