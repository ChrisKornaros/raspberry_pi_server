#!/bin/zsh

# Copy the fresh install configurations
sudo cp -r /etc/ssh /etc/ssh.new_install \\
sudo cp -r /etc/fail2ban /etc/fail2ban.new_install \\
sudo cp -r /etc/ufw /etc/ufw.new_install

# Review the ssh configuration differences
diff ~/backup_restore/configs/ssh/sshd_config /etc/ssh/sshd_config 

# If things look good, then copy the config
sudo cp ~/backup_restore/configs/ssh/sshd_config /etc/ssh/
sydo systemctl daemon-reload # Sometimes this is needed in addition to the ssh restart
sudo systemctl restart sshd

# Afterwards, verify that services are running
systemctl status sshd

# Review UFW rules first
cat ~/backup_restore/configs/ufw_rules.txt

# Apply the rules
while IFS= read -r rule; do
    sudo ufw $rule
done < ~/backup_restore/configs/ufw_rules.txt

sudo ufw enable

# Afterwards, verify that services are running
systemctl status ufw

# Review and restore fail2ban
sudo cp -r ~/backup_restore/configs/fail2ban/* /etc/fail2ban/
sudo systemctl restart fail2ban

# Afterwards, verify that services are running
systemctl status fail2ban

# Review and restore crontabs
sudo cp ~/backup_restore/configs/crontab /etc/crontab
sudo cp -r ~/backup_restore/configs/crontabs/* /etc/cron.d/

# Be very careful with these - we'll only copy specific entries
sudo cp ~/backup_restore/configs/user_ssh ~/.ssh/

