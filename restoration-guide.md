# Ubuntu Server Configuration Restoration Guide

This guide provides detailed instructions for restoring an Ubuntu Server configuration from backup. It covers the complete process from initial backup transfer to final system verification.

## Prerequisites

Before beginning the restoration process, ensure you have:
- A fresh installation of Ubuntu Server
- Your backup files containing system configurations
- SSH access to the target server
- Root or sudo privileges
- rsync installed on both source and target systems

## 1. Initial Connection Setup

When connecting to a freshly installed system, you may encounter SSH host key warnings. This is normal after a fresh installation. Here's how to handle it:

```bash
# Remove the old host key
ssh-keygen -R your-server-hostname

# Connect to the server (you'll be prompted to accept the new host key)
ssh -i ~/.ssh/your_key user@your-server-hostname
```

The `-R` option removes all keys belonging to the specified hostname from your known_hosts file. This is necessary because the server's identity has changed with the fresh installation.

## 2. Transferring Backup Files

Use rsync to transfer your backup files. rsync is preferred over scp because it:
- Provides delta transfer (only copies changed parts of files)
- Maintains file permissions and attributes
- Can resume interrupted transfers
- Includes built-in verification

```bash
# Create the destination directory
ssh -i ~/.ssh/your_key user@your-server-hostname "mkdir -p ~/backup_restore"

# Transfer backup files with progress indication
rsync -avP -e "ssh -i ~/.ssh/your_key" /path/to/backups/ user@your-server-hostname:~/backup_restore/
```

The rsync flags explained:
- `-a`: Archive mode (preserves permissions, timestamps, etc.)
- `-v`: Verbose output
- `-P`: Shows progress and enables resume capability
- `-e`: Specifies the SSH command

## 3. Package Installation

Before restoring configurations, ensure all necessary packages are installed:

```bash
# Update package list
sudo apt-get update

# Install packages from your backup list
sudo apt-get install -y $(cat ~/backup_restore/configs/package_list.txt)
```

## 4. Configuration Restoration

### 4.1 Backup Current Configurations

Always create backups of the fresh installation's configurations:

```bash
sudo cp -r /etc/ssh /etc/ssh.new_install
sudo cp -r /etc/fail2ban /etc/fail2ban.new_install
sudo cp -r /etc/ufw /etc/ufw.new_install
```

### 4.2 SSH Configuration

SSH configuration must be restored carefully to avoid lockouts:

```bash
# Review differences
diff ~/backup_restore/configs/ssh/sshd_config /etc/ssh/sshd_config

# Restore configuration
sudo cp ~/backup_restore/configs/ssh/sshd_config /etc/ssh/
sudo systemctl restart sshd

# Verify SSH is working in a new terminal before proceeding
```

### 4.3 Firewall (UFW) Configuration

Restore firewall rules systematically:

```bash
# Reset to default state
sudo ufw reset

# Review rules before applying
cat ~/backup_restore/configs/ufw_rules.txt

# Apply rules
while IFS= read -r rule; do
    sudo ufw $rule
done < ~/backup_restore/configs/ufw_rules.txt

sudo ufw enable
```

### 4.4 Fail2ban Configuration

```bash
# Restore fail2ban configuration
sudo cp -r ~/backup_restore/configs/fail2ban/* /etc/fail2ban/
sudo systemctl restart fail2ban

# Monitor for issues
sudo tail -f /var/log/fail2ban.log
```

### 4.5 User Configurations

```bash
# Restore user SSH configurations
sudo cp ~/backup_restore/configs/user_ssh ~/.ssh/
```

### 4.6 Scheduled Tasks

```bash
sudo cp ~/backup_restore/configs/crontab /etc/crontab
sudo cp -r ~/backup_restore/configs/crontabs/* /etc/cron.d/
```

## 5. System Verification

After restoration, verify all services are running correctly:

```bash
# Check service statuses
systemctl status sshd
systemctl status ufw
systemctl status fail2ban

# Check UFW status
sudo ufw status verbose

# Verify fail2ban jails
sudo fail2ban-client status

# Check system logs for any errors
sudo journalctl -xe
```

## Troubleshooting

If you encounter issues:

1. SSH Connection Problems:
   - Verify SSH service is running: `systemctl status sshd`
   - Check SSH configuration syntax: `sudo sshd -t`
   - Review SSH logs: `sudo journalctl -u ssh`

2. UFW Issues:
   - Check UFW logs: `sudo tail -f /var/log/ufw.log`
   - Verify rule syntax: `sudo ufw show raw`

3. Fail2ban Problems:
   - Check jail status: `sudo fail2ban-client status`
   - Review fail2ban logs: `sudo tail -f /var/log/fail2ban.log`
   - Verify jail configurations: `sudo fail2ban-client -d`

## Best Practices

1. Always verify configurations before applying them
2. Test services after each major configuration change
3. Keep the .new_install backup configurations until everything is working
4. Monitor system logs for any issues during and after restoration

## Additional Considerations

- Consider implementing configuration management tools for future deployments
- Document any manual changes made during restoration
- Verify backup integrity before major configuration changes
- Maintain separate backups of critical configuration files

Remember to adjust file paths and hostnames according to your specific setup. This guide assumes a basic Ubuntu Server installation with standard service configurations.