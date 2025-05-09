#!/bin/bash
# Using the {} around DATEYMD in the file path ensure it's specified as the variable's value, and the subsequent parts are not included

DATEYMD=$(date +%Y%m%d)
BACKUP_DIR="/mnt/backups/configs/$DATEYMD"
LOG_DIR="/mnt/backups/logs"
LOG_FILE="$LOG_DIR/${DATEYMD}_config_backup.log"

# Create backup directory
mkdir -p "$BACKUP_DIR"

{
    # 1. User and Group Information
    echo "Backing up User and Group configuration..."
    sudo rsync -aAXv /etc/passwd "$BACKUP_DIR/passwd.bak"
    sudo rsync -aAXv /etc/group "$BACKUP_DIR/group.bak"
    sudo rsync -aAXv /etc/shadow "$BACKUP_DIR/shadow.bak"
    sudo rsync -aAXv /etc/gshadow "$BACKUP_DIR/gshadow.bak"

    # 2. Crontab Configurations
    echo "Backing up Crontab configuration..."
    sudo rsync -aAXv /etc/crontab "$BACKUP_DIR/"
    sudo rsync -aAXv /var/spool/cron/crontabs/. "$BACKUP_DIR/crontabs/"

     # 3. SSH Configuration
    echo "Backing up SSH configuration..."
    sudo rsync -aAXv /etc/ssh/. "$BACKUP_DIR/ssh/"
    
    # Create user_ssh directory
    mkdir -p "$BACKUP_DIR/user_ssh"
    
    # Copy SSH user configuration with explicit handling of authorized_keys
    rsync -aAXv ~/.ssh/config "$BACKUP_DIR/user_ssh/" 2>/dev/null || true
    rsync -aAXv ~/.ssh/id_* "$BACKUP_DIR/user_ssh/" 2>/dev/null || true
    rsync -aAXv ~/.ssh/known_hosts "$BACKUP_DIR/user_ssh/" 2>/dev/null || true
    
    # Explicitly backup authorized_keys if it exists
    if [ -f ~/.ssh/authorized_keys ]; then
        echo "Backing up authorized_keys file..."
        rsync -aAXv ~/.ssh/authorized_keys "$BACKUP_DIR/user_ssh/"
    else
        echo "No authorized_keys file found in ~/.ssh/"
    fi

    # 4. UFW (Uncomplicated Firewall) Configuration
    echo "Backing up ufw configuration..."
    sudo rsync -aAXv /etc/ufw/. "$BACKUP_DIR/ufw/"
    sudo ufw status verbose > "$BACKUP_DIR/ufw_rules.txt"

    # 5. Fail2Ban Configuration
    echo "Backing up fail2ban configuration..."
    sudo rsync -aAXv /etc/fail2ban/. "$BACKUP_DIR/fail2ban/"

    # 6. Network Configuration
    echo "Backing up Network configuration..."
    sudo rsync -aAXv /etc/network/. "$BACKUP_DIR/network/"
    sudo rsync -aAXv /etc/systemd/network/. "$BACKUP_DIR/systemd/network/"
    sudo rsync -aAXv /etc/netplan/. "$BACKUP_DIR/netplan/"
    sudo rsync -aAXv /etc/hosts "$BACKUP_DIR/hosts.bak"
    sudo rsync -aAXv /etc/hostname "$BACKUP_DIR/hostname.bak"
    sudo rsync -aAXv /etc/resolv.conf "$BACKUP_DIR/resolv.conf.bak"
    sudo rsync -aAXv /etc/wpa_supplicant/. "$BACKUP_DIR/wpa_supplicant/"

    # 7. Systemd Services and Timers
    echo "Backing up Systemd Timers configuration..."
    sudo rsync -aAXv /etc/systemd/system/. "$BACKUP_DIR/systemd/"

    # 8. Logrotate Configuration
    echo "Backing up Logrotate configuration..."
    sudo rsync -aAXv /etc/logrotate.conf "$BACKUP_DIR/logrotate.conf.bak"
    sudo rsync -aAXv /etc/logrotate.d/. "$BACKUP_DIR/logrotate.d/"

    # 9. Timezone and Locale
    echo "Backing up Timezone and Locale configuration..."
    sudo rsync -aAXv /etc/timezone "$BACKUP_DIR/timezone.bak"
    sudo rsync -aAXv /etc/localtime "$BACKUP_DIR/localtime.bak"
    sudo rsync -aAXv /etc/default/locale "$BACKUP_DIR/locale.bak"

    # 10. Keyboard Configuration
    echo "Backing up Keyboard configuration..."
    sudo rsync -aAXv /etc/default/keyboard "$BACKUP_DIR/keyboard.bak"

    # Set appropriate permissions
    echo "Configuring backup directory permissions..."
    sudo chown -R chris:chris "$BACKUP_DIR"
    sudo chmod -R 600 "$BACKUP_DIR"

    echo "Configuration backup completed at: $BACKUP_DIR"

} > "$LOG_FILE" 2>&1

echo "Logs available at: $LOG_FILE"