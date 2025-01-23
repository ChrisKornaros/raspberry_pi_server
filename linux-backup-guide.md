# Comprehensive Linux Configuration Backup Guide for Raspberry Pi Server

This guide explains how to create a complete backup of Linux configurations and system files on a Raspberry Pi Server running Ubuntu Server LTS using rsync. We'll use rsync because it provides several important advantages over simple copy commands:

- Incremental backups that only transfer changed files
- Preservation of file permissions, ownership, and timestamps
- Built-in compression for efficient transfers
- Detailed progress information and logging
- The ability to resume interrupted transfers

## Prerequisites

- Raspberry Pi Server running Ubuntu Server LTS
- Physical keyboard access
- Root or sudo privileges
- Mounted backup drive at `/mnt/backup/`
- rsync (typically pre-installed on Ubuntu Server)

## Setting Up the Backup Directory

First, we'll prepare the backup directory structure and set appropriate permissions:

```bash
# Create backup directories if they don't exist
sudo mkdir -p /mnt/backup/configs
sudo mkdir -p /mnt/backup/system

# Change ownership to your user (replace 'chris' with your username)
sudo chown -R chris:chris /mnt/backup

# Set appropriate permissions
sudo chmod 700 /mnt/backup  # Only owner can read/write/execute
```

## Configuration Files Backup

We'll use rsync to create a structured backup of essential configuration files. The following script demonstrates how to perform the backup while preserving all file attributes:

```bash
#!/bin/bash
# Using the {} around DATEYMD in the file path ensure it's specified as the variable's value, and the subsequent parts are not included

DATEYMD=$(date +%Y%m%d)
BACKUP_DIR="/mnt/backup/configs/$DATEYMD"
LOG_DIR="/mnt/backup/logs"
LOG_FILE="$LOG_DIR/${DATEYMD}_config_backup.log"

# Create backup directory
mkdir -p "$BACKUP_DIR"

{
    # 1. User and Group Information
    sudo rsync -aAXv /etc/passwd "$BACKUP_DIR/passwd.bak"
    sudo rsync -aAXv /etc/group "$BACKUP_DIR/group.bak"
    sudo rsync -aAXv /etc/shadow "$BACKUP_DIR/shadow.bak"
    sudo rsync -aAXv /etc/gshadow "$BACKUP_DIR/gshadow.bak"

    # 2. Crontab Configurations
    sudo rsync -aAXv /etc/crontab "$BACKUP_DIR/"
    sudo rsync -aAXv /var/spool/cron/crontabs/. "$BACKUP_DIR/crontabs/"

    # 3. SSH Configuration
    sudo rsync -aAXv /etc/ssh/. "$BACKUP_DIR/ssh/"
    sudo rsync -aAXv ~/.ssh/. "$BACKUP_DIR/user_ssh/"

    # 4. UFW (Uncomplicated Firewall) Configuration
    sudo rsync -aAXv /etc/ufw/. "$BACKUP_DIR/ufw/"
    sudo ufw status verbose > "$BACKUP_DIR/ufw_rules.txt"

    # 5. Fail2Ban Configuration
    sudo rsync -aAXv /etc/fail2ban/. "$BACKUP_DIR/fail2ban/"

    # 6. Network Configuration
    sudo rsync -aAXv /etc/network/. "$BACKUP_DIR/network/"
    sudo rsync -aAXv /etc/hosts "$BACKUP_DIR/hosts.bak"
    sudo rsync -aAXv /etc/hostname "$BACKUP_DIR/hostname.bak"
    sudo rsync -aAXv /etc/resolv.conf "$BACKUP_DIR/resolv.conf.bak"
    sudo rsync -aAXv /etc/wpa_supplicant/wpa_supplicant.conf "$BACKUP_DIR/wpa_supplicant.conf.bak"

    # 7. Package Manager Configurations (apt)
    sudo rsync -aAXv /etc/apt/. "$BACKUP_DIR/apt/"

    # 8. Systemd Services and Timers
    sudo rsync -aAXv /etc/systemd/system/. "$BACKUP_DIR/systemd/"

    # 9. Logrotate Configuration
    sudo rsync -aAXv /etc/logrotate.conf "$BACKUP_DIR/logrotate.conf.bak"
    sudo rsync -aAXv /etc/logrotate.d/. "$BACKUP_DIR/logrotate.d/"

    # 10. Custom Application Configurations (add more as needed)
    sudo rsync -aAXv /etc/myapp/. "$BACKUP_DIR/myapp/"

    # 11. Timezone and Locale
    sudo rsync -aAXv /etc/timezone "$BACKUP_DIR/timezone.bak"
    sudo rsync -aAXv /etc/localtime "$BACKUP_DIR/localtime.bak"
    sudo rsync -aAXv /etc/default/locale "$BACKUP_DIR/locale.bak"

    # 12. Keyboard Configuration
    sudo rsync -aAXv /etc/default/keyboard "$BACKUP_DIR/keyboard.bak"

    # 13. Package List
    dpkg --get-selections > "$BACKUP_DIR/package_list.txt"

    # Set appropriate permissions
    sudo chown -R chris:chris "$BACKUP_DIR"
    sudo chmod -R 600 "$BACKUP_DIR"

    echo "Configuration backup completed at: $BACKUP_DIR"

} > "$LOG_FILE" 2>&1

echo "Logs available at: $LOG_FILE"
```

```bash
# Make the script executable
chmod +x /scripts/config_backup.sh
```

## System Files Backup

For system files, we'll create a separate rsync script that handles system directories efficiently:

```bash
#!/bin/bash

DATEYMD=$(date +%Y%m%d)
BACKUP_DIR="/mnt/backup/system/$DATEYMD"
LOG_DIR="/mnt/backup/logs"
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
```

```bash
# Make the script executable
chmod +x /scripts/system_backup.sh
```

## Understanding the rsync Options

The rsync commands use several important options:

- `-a`: Archive mode, preserves almost everything
- `-A`: Preserve ACLs (Access Control Lists)
- `-X`: Preserve extended attributes
- `-v`: Verbose output
- `--one-file-system`: Don't cross filesystem boundaries
- `--hard-links`: Preserve hard links
- `--exclude`: Skip specified directories

## **Note:**
**Everything up until this point has been tested and works-- relatively efficiently for such a simple setup. That being said, I still haven't tested the restore script, nor have I tried to setup simple cron jobs to automate and cleanup the backups.**

## Restoring from Backup

To restore your system from these backups:

```bash
# 1. Restore configuration files
sudo rsync -aAXv /mnt/backup/configs/[TIMESTAMP]/passwd.bak /etc/passwd
sudo rsync -aAXv /mnt/backup/configs/[TIMESTAMP]/group.bak /etc/group
sudo rsync -aAXv /mnt/backup/configs/[TIMESTAMP]/ssh/ /etc/ssh/
sudo rsync -aAXv /mnt/backup/configs/[TIMESTAMP]/ufw/ /etc/ufw/
sudo rsync -aAXv /mnt/backup/configs/[TIMESTAMP]/fail2ban/ /etc/fail2ban/

# 2. Restore installed packages
sudo dpkg --set-selections < /mnt/backup/configs/[TIMESTAMP]/package_list.txt
sudo apt-get dselect-upgrade

# 3. For a full system restore
sudo rsync -aAXv --delete /mnt/backup/system/[TIMESTAMP]/ /
```

## Important Notes

1. The `--delete` option during restore will remove files at the destination that don't exist in the backup. Use with caution.
2. Consider using rsync's `--dry-run` option to test backups and restores without making changes.
3. The backup includes sensitive system files. Store it securely and restrict access.
4. Consider encrypting the backup directory for additional security.
5. Test the restore process in a safe environment before using in production.

## Automating the Backup

Create a master backup script that runs both configuration and system backups:

```bash
# Create master backup script (save as master-backup.sh)
cat << 'EOF' > /mnt/backup/master-backup.sh
#!/bin/bash

# Set up logging
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Run configuration backup
/mnt/backup/backup-configs.sh

# Run system backup
/mnt/backup/backup-system.sh

# Remove backups older than 30 days
find /mnt/backup/configs/ -type d -mtime +30 -exec rm -rf {} +
find /mnt/backup/system/ -type d -mtime +30 -exec rm -rf {} +
EOF

# Make the script executable
chmod +x /mnt/backup/master-backup.sh

# Add to crontab (run daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /mnt/backup/master-backup.sh") | crontab -
```

## Troubleshooting

If you encounter issues:

1. Check rsync error messages with `--verbose` option
2. Verify sufficient disk space with `df -h`
3. Monitor backup progress with `--progress` option
4. Check system logs: `sudo journalctl -u cron`
5. Verify file permissions and ownership
6. Test network connectivity for remote backups

Remember to regularly verify your backups by checking the log files and occasionally testing the restore process in a safe environment.