#!/bin/bash

# Variables
BACKUP_DIR="/mnt/backups/configs/$1"
LOG_DIR="/mnt/backups/logs"
LOG_FILE="$LOG_DIR/${1}_config_restore.log"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory $BACKUP_DIR does not exist. Exiting."
    exit 1
fi

# Restore function
restore_file() {
    local src="$1"
    local dest="$2"
    local owner="$3"
    local perms="$4"

    if [ -f "$src" ] || [ -d "$src" ]; then
        sudo rsync -aAXv "$src" "$dest"
        sudo chown "$owner" "$dest"
        sudo chmod "$perms" "$dest"
        echo "Restored $src to $dest with owner $owner and permissions $perms"
    else
        echo "Source $src does not exist. Skipping."
    fi
}

# Start restoration
{
    echo "Starting restoration from $BACKUP_DIR"

    # 1. User and Group Information
    restore_file "$BACKUP_DIR/passwd.bak" /etc/passwd root:root 644
    restore_file "$BACKUP_DIR/group.bak" /etc/group root:root 644
    restore_file "$BACKUP_DIR/shadow.bak" /etc/shadow root:shadow 640
    restore_file "$BACKUP_DIR/gshadow.bak" /etc/gshadow root:shadow 640

    # 2. Crontab Configurations
    restore_file "$BACKUP_DIR/crontab" /etc/crontab root:root 644
    restore_file "$BACKUP_DIR/crontabs/" /var/spool/cron/crontabs/ root:crontab 700

    # 3. SSH Configuration
    restore_file "$BACKUP_DIR/ssh/" /etc/ssh/ root:root 700
    restore_file "$BACKUP_DIR/user_ssh/" ~/.ssh/ "$USER:$USER" 700

    # 4. UFW Configuration
    restore_file "$BACKUP_DIR/ufw/" /etc/ufw/ root:root 700

    # 5. Fail2Ban Configuration
    restore_file "$BACKUP_DIR/fail2ban/" /etc/fail2ban/ root:root 700

    # 6. Network Configuration
    restore_file "$BACKUP_DIR/network/" /etc/network/ root:root 700
    restore_file "$BACKUP_DIR/netplan/" /etc/netplan/ root:root 700
    restore_file "$BACKUP_DIR/NetworkManager/" /etc/NetworkManager/ root:root 700
    restore_file "$BACKUP_DIR/hosts.bak" /etc/hosts root:root 644
    restore_file "$BACKUP_DIR/hostname.bak" /etc/hostname root:root 644
    restore_file "$BACKUP_DIR/resolv.conf.bak" /etc/resolv.conf root:root 644
    restore_file "$BACKUP_DIR/wpa_supplicant.conf.bak" /etc/wpa_supplicant/wpa_supplicant.conf root:root 600

    # 7. Package Manager Configurations (apt)
    restore_file "$BACKUP_DIR/apt/" /etc/apt/ root:root 700

    # 8. Systemd Services and Timers
    restore_file "$BACKUP_DIR/systemd/" /etc/systemd/system/ root:root 700

    # 9. Logrotate Configuration
    restore_file "$BACKUP_DIR/logrotate.conf.bak" /etc/logrotate.conf root:root 644
    restore_file "$BACKUP_DIR/logrotate.d/" /etc/logrotate.d/ root:root 700

    # 10. Timezone and Locale
    restore_file "$BACKUP_DIR/timezone.bak" /etc/timezone root:root 644
    restore_file "$BACKUP_DIR/localtime.bak" /etc/localtime root:root 644
    restore_file "$BACKUP_DIR/locale.bak" /etc/default/locale root:root 644

    # 11. Keyboard Configuration
    restore_file "$BACKUP_DIR/keyboard.bak" /etc/default/keyboard root:root 644

    # 12. Package List
    if [ -f "$BACKUP_DIR/package_list.txt" ]; then
        sudo dpkg --set-selections < "$BACKUP_DIR/package_list.txt"
        sudo apt-get -y dselect-upgrade
        echo "Restored package list from $BACKUP_DIR/package_list.txt"
    else
        echo "Package list not found. Skipping."
    fi

    echo "Restoration completed successfully."

} > "$LOG_FILE" 2>&1

echo "Logs available at: $LOG_FILE"