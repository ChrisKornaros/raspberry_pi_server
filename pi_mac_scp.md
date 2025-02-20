# Copying Bash Scripts from Ubuntu Pi Server to MacBook Air

## Overview
This document outlines the process of securely copying Bash scripts from an Ubuntu Pi Server to a MacBook Air using SSH and SCP. The user has an SSH configuration file (`~/.ssh/config`) set up to simplify connections to their Raspberry Pi server.

## Steps Taken

### 1. Ensuring SSH Configuration Works
Initially, the `ssh ubuntu-pi-server` command did not use the expected user-specific SSH configuration (`~/.ssh/config`). Instead, it defaulted to the system-wide configuration (`/etc/ssh/ssh_config`).

#### Solution
Running the command with the `-F` flag explicitly specifying the user config worked:
```bash
ssh -F ~/.ssh/config ubuntu-pi-server
```

To make SSH always use the correct config, the following solutions were explored:

- Ensuring `~/.ssh/config` exists and has correct permissions (`chmod 600 ~/.ssh/config`).
- Modifying `/etc/ssh/ssh_config` to include the user config:
  ```plaintext
  Include ~/.ssh/config
  ```

After fixing the issue, the command `ssh ubuntu-pi-server` worked as expected.

### 2. Copying Scripts from Server to MacBook Air
Once SSH was working correctly, the next step was to copy two Bash scripts from the Ubuntu Pi Server to the MacBook Air using `scp`.

#### Identifying Script Locations
The scripts were stored on the Pi in:
```plaintext
/home/ubuntu/scripts/backup.sh
/home/ubuntu/scripts/maintenance.sh
```

#### Copying Individual Files
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

### 3. Verifying the Transfer
After copying, the user verified the files were successfully transferred by listing the local directory:
```bash
ls ~/Documents/pi-scripts/
```
The expected scripts were present.

## Final Outcome
- SSH is now correctly configured and working using `ssh ubuntu-pi-server`.
- Bash scripts can be securely copied from the Ubuntu Pi Server to the MacBook Air using `scp`.
- The user can now maintain local backups of important scripts efficiently.

