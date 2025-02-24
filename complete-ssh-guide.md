## SSH

I had Claude write this guide, I actually prefer Claude's explanatory guides to GPT, but prefer GPT for quick guides that point me in a general direction.

This section provides a thorough walkthrough of setting up and securing SSH (Secure Shell) on a Raspberry Pi running Ubuntu Server. SSH is a network protocol that creates an encrypted tunnel between computers, allowing secure remote management. Think of it as establishing a private, secure telephone line that only authorized parties can use to communicate.

### Understanding SSH Configuration Files

Before diving into the setup, it's important to understand the key configuration files:

#### SSH Client vs Server Configuration

The SSH system uses two main configuration files with distinct purposes:

1. `ssh_config`:
   - Lives on your client machine (like your laptop)
   - Controls how your system behaves when connecting to other SSH servers
   - Affects outgoing SSH connections
   - Located at `/etc/ssh/ssh_config` (system-wide) and `~/.ssh/config` (user-specific)

2. `sshd_config`:
   - Lives on your server (the Raspberry Pi)
   - Controls how your SSH server accepts incoming connections
   - Determines who can connect and how
   - Located at `/etc/ssh/sshd_config`
   - Requires root privileges to modify
   - Changes require restarting the SSH service

### Key-Based Authentication Setup

#### Understanding SSH Keys and Security

This guide uses ECDSA-384 keys, which offer several advantages:
- Uses the NIST P-384 curve, providing security equivalent to 192-bit symmetric encryption
- Better resistance to potential quantum computing attacks compared to smaller key sizes
- Standardized under FIPS 186-4
- Excellent balance between security and performance

#### Generating Your SSH Keys

On your laptop, generate a new SSH key pair:

```bash
# Generate a new SSH key pair using ECDSA-384
ssh-keygen -t ecdsa -b 384 -C "ubuntu-pi-server"
```

This command:
- `-t ecdsa`: Specifies the ECDSA algorithm
- `-b 384`: Sets the key size to 384 bits
- `-C "ubuntu-pi-server"`: Adds a descriptive comment

The command generates two files:
- `~/.ssh/id_ecdsa`: Your private key (keep this secret!)
- `~/.ssh/id_ecdsa.pub`: Your public key (safe to share)

#### Installing Your Public Key on the Raspberry Pi

Transfer your public key to the Pi:

```bash
ssh-copy-id -i ~/.ssh/id_ecdsa.pub chris@ubuntu-pi-server
```

This command:
1. Connects to your Pi using password authentication
2. Creates the `.ssh` directory if needed
3. Adds your public key to `authorized_keys`
4. Sets appropriate permissions automatically

### Server-Side SSH Configuration

#### Understanding Server Host Keys

Your Pi's `/etc/ssh` directory contains several important files:
- Host key pairs (public and private) for different algorithms
- Configuration files and directories
- The moduli file for key exchange

#### Optimizing Server Security

1. Back up the original configuration:
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup-$(date +%Y%m%d)
```

2. Create a custom security configuration:
```bash
sudo nano /etc/ssh/sshd_config.d/99-custom-security.conf
```

Add these security settings:
```bash
# Disable password authentication
PasswordAuthentication no

# Disable root login
PermitRootLogin no

# Specify allowed users
AllowUsers chris

# Use SSH Protocol 2
Protocol 2

# Set idle timeout (optional)
ClientAliveInterval 300
ClientAliveCountMax 2
```

3. Optimize host key settings in sshd_config:
```bash
# Specify host key order (prioritize ECDSA)
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# Specify key exchange algorithms
KexAlgorithms ecdh-sha2-nistp384,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512

# Specify host key algorithms
HostKeyAlgorithms ecdsa-sha2-nistp384,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
```

4. Strengthen the moduli file:
```bash
# Back up the existing file
sudo cp /etc/ssh/moduli /etc/ssh/moduli.backup

# Remove moduli less than 3072 bits
sudo awk '$5 >= 3072' /etc/ssh/moduli > /tmp/moduli
sudo mv /tmp/moduli /etc/ssh/moduli
```

5. Apply changes:
```bash
# Test the configuration
sudo sshd -t

# Restart the SSH service (on Ubuntu Server)
sudo systemctl restart ssh

# Verify the service status
sudo systemctl status ssh
```

### Client-Side Configuration

#### Setting Up Your SSH Config

Create or edit `~/.ssh/config` on your laptop:

```bash
Host ubuntu-pi-server
    HostName ubuntu-pi-server
    User chris
    IdentityFile ~/.ssh/id_ecdsa
    Port 22
```

#### Managing Known Hosts

1. Back up your current known_hosts file:
```bash
cp ~/.ssh/known_hosts ~/.ssh/known_hosts.backup
```

2. View current entries:
```bash
ssh-keygen -l -f ~/.ssh/known_hosts
```

3. Remove old entries:
```bash
# Remove specific host
ssh-keygen -R ubuntu-pi-server
```

4. Hash your known_hosts file for security:
```bash
ssh-keygen -H -f ~/.ssh/known_hosts
```

#### Securing the Key File

When using SSH key-based authentication, adding a password to your key enhances security by requiring a passphrase to use the key. This guide explains how to add and remove a password from an existing SSH key.

**Adding a Password to an SSH Key**

If you already have an SSH key and want to add a password to it, use the following command:

```sh
ssh-keygen -p -f ~/.ssh/id_rsa
```

Explanation:

    -p : Prompts for changing the passphrase.
    -f ~/.ssh/id_rsa : Specifies the key file to modify (adjust if your key has a different name).
    You will be asked for the current passphrase (leave blank if none) and then set a new passphrase.

**Removing a Password from an SSH Key**

If you want to remove the passphrase from an SSH key, run:

```bash
ssh-keygen -p -f ~/.ssh/id_rsa -N ""
```

Explanation:

    -N "" : Sets an empty passphrase (removes the password).
    The tool will ask for the current passphrase before removing it.

Verifying the Changes

After modifying the key, test the SSH connection from your CLI, or using an SSH tunnel.

```bash
ssh -i ~/.ssh/id_rsa user@your-server
```

If you added a passphrase, you'll be prompted to enter it when connecting.

By using a passphrase, your SSH key is protected against unauthorized use in case it gets compromised. If you frequently use your SSH key, consider using an SSH agent (ssh-agent) to cache your passphrase securely.

### Additional Security Measures

#### Firewall Configuration

```bash
# Install UFW
sudo apt install ufw

# Allow SSH connections
sudo ufw allow ssh

# Enable the firewall
sudo ufw enable
```

Now, you'll want to add rules for example, allowing traffic on a specific port if you took the step to choose a nonstandard, one that isn't the default **Port 22**. 

```bash
# Add a new rule in the port/protocol format
sudo ufw add 6025/tcp

# See a list of all rules
sudo ufw status numbered

# Remove the default rules
sudo ufw delete 1
```

#### Fail2Ban
Fail2Ban is a security tool designed to protect servers from brute force attacks. It works by monitoring log files for specified patterns, identifying suspicious activity (like multiple failed login attempts), and banning the offending IP addresses using firewall rules for a set period. It's especially useful for securing SSH, FTP, and web services.

The best part is the project is entirely open source, you can view the source code and contribute [here](https://https://github.com/fail2ban/fail2ban).

```bash
# Install Fail2Ban
sudo apt update
sudo apt install fail2ban

# Start and enable Fail2Ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```


### System Updates

Keep your system updated:
```bash
sudo apt update && sudo apt upgrade
```

### Monitoring and Maintenance

#### Regular Security Checks

1. Monitor SSH login attempts:
```bash
sudo journalctl -u ssh
```

2. Check authentication logs:
```bash
sudo tail -f /var/log/auth.log
```

#### Key Management Best Practices

1. Protect your private key:
- Use a strong passphrase
- Never share or copy to unsecured devices
- Keep secure backups

2. Verify file permissions:
```bash
# On your laptop
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ecdsa
chmod 644 ~/.ssh/id_ecdsa.pub

# On your Pi
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Troubleshooting

If you can't connect:

1. Verify SSH service status:
```bash
sudo systemctl status ssh
```

2. Check SSH connectivity:
```bash
# Test SSH connection verbosely
ssh -v chris@ubuntu-pi-server
```

3. Verify host key fingerprints:
```bash
# On the Pi
ssh-keygen -l -f /etc/ssh/ssh_host_ecdsa_key.pub
```

Remember: When you see a host key verification prompt, always verify the fingerprint matches your server's key before accepting.

### Using SCP to transfer files
This document outlines the process of securely copying Bash scripts from an Ubuntu Pi Server to a MacBook Air using SCP (Secure Copy Protocol), a file transfer tool built on top of SSH. The user should have an SSH configuration file (`~/.ssh/config`) set up to simplify connections to their Raspberry Pi server.

#### Ensure the SSH Configuration Works

Initially, the `ssh ubuntu-pi-server` command did not use the expected user-specific SSH configuration (`~/.ssh/config`). Instead, it defaulted to the system-wide configuration (`/etc/ssh/ssh_config`).To fix this, I ran the command with the `-F` flag explicitly specifying the user config:

```bash
ssh -F ~/.ssh/config ubuntu-pi-server
```

**Note:** To make sure SSH always uses the correct config, I tried the following:

- Made sure `~/.ssh/config` exists and has the correct permissions (`chmod 600 ~/.ssh/config`).
- Modified the `/etc/ssh/ssh_config` to include the user config:
```plaintext
Include ~/.ssh/config
```

After fixing the issue, the command `ssh ubuntu-pi-server` worked as expected.

#### Copying Scripts from Server to MacBook Air
Once SSH was working correctly, the next step was to copy two Bash scripts from the Ubuntu Pi Server to the MacBook Air using `scp`.

The scripts were stored on the Pi as:

```plaintext
/home/chris/scripts/system_backup.sh
/home/chris/scripts/config_backup.sh
```

The following `scp` commands were used to transfer them to the MacBook Air:

```bash
scp ubuntu-pi-server:~/scripts/backup.sh ~/Documents/pi-scripts/
scp ubuntu-pi-server:~/scripts/maintenance.sh ~/Documents/pi-scripts/
```

#### Copying Multiple Files at Once
To copy all Bash scripts from the `scripts` directory in one command:

```bash
scp ubuntu-pi-server:~/scripts/*.sh ~/Documents/pi-scripts/
```

#### Copying Files from MacBook Air to Server
Simply enter the command in reverse, but notice here I did things a little differently.

- `-r` tells `scp` to *recursively* copy a directory, meaning it moves it and all of its contents
- `chris@` tells `scp` to specify the user when connecting to the server, this can be helpful if you have connection issues

```bash
scp -r ~/Documents/pi-scripts chris@ubuntu-pi-server:~/scripts
```

#### SCP Notes

- SSH is now correctly configured and working using `ssh ubuntu-pi-server`.
- Bash scripts can be securely copied from the Ubuntu Pi Server to the MacBook Air using `scp`.
  - Just take note of the specific syntax used, namely `server-name:path/to/files`
- The user can now maintain local backups of important scripts efficiently.
  - Enables you to develop where you'd like and then easily move files to test scripts

## Conclusion

This configuration provides a robust, secure SSH setup for your Raspberry Pi. It uses modern cryptography (ECDSA-384) while maintaining compatibility with other systems. Regular monitoring and maintenance will help ensure your server remains secure.

Remember to keep your private keys secure and regularly update your system. If you need to make changes to the SSH configuration, always test them before disconnecting from your current session to avoid being locked out.
