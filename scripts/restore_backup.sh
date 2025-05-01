#!/bin/bash

# Function to ensure we can always execute essential commands
preserve_critical_permissions() {
    # Ensure critical system directories maintain correct permissions
    sudo chmod --preserve-root 755 /
    sudo chmod --preserve-root 755 /usr
    sudo chmod --preserve-root 755 /usr/bin
    sudo chmod --preserve-root 755 /bin
    sudo chmod --preserve-root 755 /sbin
    sudo chmod --preserve-root 755 /usr/sbin
    
    # Ensure critical commands remain executable
    sudo chmod --preserve-root 755 /usr/bin/sudo
    sudo chmod --preserve-root 755 /bin/bash
    sudo chmod --preserve-root 755 /bin/chmod
    sudo chmod --preserve-root 755 /bin/ls
}

# Function to verify system accessibility after restore
verify_system_access() {
    # Test basic command execution
    if ! command -v sudo >/dev/null 2>&1 || \
       ! command -v bash >/dev/null 2>&1 || \
       ! command -v chmod >/dev/null 2>&1; then
        echo "ERROR: Critical system commands are not accessible!"
        echo "Restoring essential permissions..."
        preserve_critical_permissions
    fi
}

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script with sudo"
    exit 1
fi

# Check if a backup directory was provided
if [ $# -ne 1 ]; then
    echo "Error: Please provide the backup directory path"
    echo "Usage: sudo $0 /path/to/backup/directory"
    exit 1
fi

# Set up our variables
BACKUP_DIR=$1
LOG_DIR="/mnt/backups/logs"
DATEYMD=$(date +%Y%m%d)
LOG_FILE="$LOG_DIR/${DATEYMD}_restore.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Check if backup directory exists - do this BEFORE starting the log
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory does not exist: $BACKUP_DIR"
    exit 1
fi

# Verify backup directory isn't empty - do this BEFORE starting the log
if [ -z "$(ls -A $BACKUP_DIR)" ]; then
    echo "Error: Backup directory is empty: $BACKUP_DIR"
    exit 1
fi

# Prompt for user confirmation - do this BEFORE starting the log
echo "WARNING: This will restore system files from: $BACKUP_DIR"
echo "This operation will:"
echo "1. Overwrite current system files"
echo "2. Require a system reboot afterward"
echo "3. Cannot be undone"
echo
echo "Please type 'RESTORE' (all caps) to continue:"
read -r response
if [ "$response" != "RESTORE" ]; then
    echo "Restore cancelled by user"
    exit 1
fi

# Start logging block - only for the restore operation itself
{
    echo "Starting system restore at: $(date)"
    echo "Restoring from: $BACKUP_DIR"

    # Save current permissions of critical directories
    echo "Saving current permissions of critical directories..."
    preserve_critical_permissions
    
    # Perform the restore using rsync
    echo "Starting rsync restore operation..."
    sudo rsync -aAXv --delete \
        --exclude="/proc/*" \
        --exclude="/sys/*" \
        --exclude="/dev/*" \
        --exclude="/run/*" \
        --exclude="/mnt/*" \
        --exclude="/media/*" \
        --exclude="/tmp/*" \
        --exclude="/home/*/.cache/*" \
        --exclude="/var/cache/*" \
        --exclude="/var/tmp/*" \
        --exclude="/lost+found" \
        "$BACKUP_DIR/" /

    echo "Rsync restore completed at: $(date)"
    
    # Verify and fix permissions after restore
    echo "Verifying system access..."
    verify_system_access
    
    echo "Restore process completed at: $(date)"

} > "$LOG_FILE" 2>&1

# These messages appear on screen only, not in the log
echo "Restore operation completed."
echo "Logs available at: $LOG_FILE"
echo
echo "IMPORTANT: Please reboot your system now using:"
echo "sudo reboot"