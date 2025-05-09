#!/bin/bash

# Simple Configuration Restoration Script for Ubuntu Pi Server
BACKUP_DIR=${1:-"/mnt/backups/configs/master"}

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root. Try using sudo."
    exit 1
fi

# Check if the backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory not found: $BACKUP_DIR"
    echo "Usage: $0 [backup_directory_path]"
    exit 1
fi

# Begin restoration process
echo "Starting configuration restoration from $BACKUP_DIR..."
echo "This will overwrite current system configurations with those from the backup."
read -p "Continue with restoration? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Restoration aborted by user."
    exit 0
fi

# 1. Restore User and Group Information
echo "Restoring user and group information..."
[ -f "$BACKUP_DIR/passwd.bak" ] && rsync -a "$BACKUP_DIR/passwd.bak" /etc/passwd
[ -f "$BACKUP_DIR/group.bak" ] && rsync -a "$BACKUP_DIR/group.bak" /etc/group
[ -f "$BACKUP_DIR/shadow.bak" ] && rsync -a "$BACKUP_DIR/shadow.bak" /etc/shadow
[ -f "$BACKUP_DIR/gshadow.bak" ] && rsync -a "$BACKUP_DIR/gshadow.bak" /etc/gshadow

# Explicitly Set Permissions for Critical System Files
echo "Fixing critical system file permissions..."
chmod 644 /etc/passwd   # Read-write for root, read-only for everyone else
chmod 644 /etc/group    # Read-write for root, read-only for everyone else  
chmod 640 /etc/shadow   # Read-write for root, read-only for shadow group
chmod 640 /etc/gshadow  # Read-write for root, read-only for shadow group

# 2. Restore SSH Configuration
echo "Restoring SSH configuration..."
[ -d "$BACKUP_DIR/ssh" ] && rsync -a "$BACKUP_DIR/ssh/" /etc/ssh/
chmod 600 /etc/ssh/ssh_host_*_key 2>/dev/null || true
chmod 644 /etc/ssh/ssh_host_*_key.pub 2>/dev/null || true

# 3. Restore UFW Configuration
echo "Restoring UFW configuration..."
if [ -d "$BACKUP_DIR/ufw" ]; then
    apt-get install -y ufw >/dev/null
    rsync -a "$BACKUP_DIR/ufw/" /etc/ufw/
fi

# 4. Restore Fail2Ban Configuration
echo "Restoring Fail2Ban configuration..."
if [ -d "$BACKUP_DIR/fail2ban" ]; then
    apt-get install -y fail2ban >/dev/null
    rsync -a "$BACKUP_DIR/fail2ban/" /etc/fail2ban/
fi

# 5. Restore Network Configuration
echo "Restoring network configuration..."
[ -d "$BACKUP_DIR/network" ] && rsync -a "$BACKUP_DIR/network/" /etc/network/
[ -d "$BACKUP_DIR/systemd/network" ] && rsync -a "$BACKUP_DIR/systemd/network/" /etc/systemd/network/
[ -d "$BACKUP_DIR/netplan" ] && rsync -a "$BACKUP_DIR/netplan/" /etc/netplan/
[ -f "$BACKUP_DIR/hosts.bak" ] && rsync -a "$BACKUP_DIR/hosts.bak" /etc/hosts
[ -f "$BACKUP_DIR/hostname.bak" ] && rsync -a "$BACKUP_DIR/hostname.bak" /etc/hostname
[ -f "$BACKUP_DIR/resolv.conf.bak" ] && rsync -a "$BACKUP_DIR/resolv.conf.bak" /etc/resolv.conf
[ -d "$BACKUP_DIR/wpa_supplicant" ] && rsync -a "$BACKUP_DIR/wpa_supplicant/" /etc/wpa_supplicant/

# 6. Restore Filesystem Table (fstab)
echo "Restoring filesystem table (fstab)..."
[ -f "$BACKUP_DIR/fstab.bak" ] && rsync -a "$BACKUP_DIR/fstab.bak" /etc/fstab

# 7. Restore Package List
#echo "Reinstalling packages from backup..."
#if [ -f "$BACKUP_DIR/package_list.txt" ]; then
#    apt-get update && apt-get install -y dselect
#    dpkg --set-selections < "$BACKUP_DIR/package_list.txt"
#    apt-get dselect-upgrade -y
#fi

# Restart services
systemctl restart systemd-networkd wpa_supplicant@wlan0.service ssh ufw fail2ban 

echo "Configuration restoration completed. A system reboot is recommended."
read -p "Would you like to reboot now? (y/n): " REBOOT
[[ "$REBOOT" == "y" || "$REBOOT" == "Y" ]] && reboot

exit 0