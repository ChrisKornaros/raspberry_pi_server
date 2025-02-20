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
    sudo rsync -aAXv /etc/netplan/. "$BACKUP_DIR/netplan/"
    sudo rsync -aAXv /etc/NetworkManager/. "$BACKUP_DIR/NetworkManager/"
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

    # 10. Timezone and Locale
    sudo rsync -aAXv /etc/timezone "$BACKUP_DIR/timezone.bak"
    sudo rsync -aAXv /etc/localtime "$BACKUP_DIR/localtime.bak"
    sudo rsync -aAXv /etc/default/locale "$BACKUP_DIR/locale.bak"

    # 11. Keyboard Configuration
    sudo rsync -aAXv /etc/default/keyboard "$BACKUP_DIR/keyboard.bak"

    # 12. Package List
    dpkg --get-selections > "$BACKUP_DIR/package_list.txt"

    # Set appropriate permissions
    sudo chown -R chris:chris "$BACKUP_DIR"
    sudo chmod -R 600 "$BACKUP_DIR"

    echo "Configuration backup completed at: $BACKUP_DIR"

} > "$LOG_FILE" 2>&1

echo "Logs available at: $LOG_FILE"