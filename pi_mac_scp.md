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

#### 

- SSH is now correctly configured and working using `ssh ubuntu-pi-server`.
- Bash scripts can be securely copied from the Ubuntu Pi Server to the MacBook Air using `scp`.
  - Just take note of the specific syntax used, namely `server-name:path/to/files`
- The user can now maintain local backups of important scripts efficiently.
  - Enables you to develop where you'd like and then easily move files to test scripts

