---
name: system-administration
description: Manage system services, users, and settings safely with confirmation prompts. Handles service control, user management, permissions, and system configuration for Arch Linux with machine-aware operations (SamPC desktop and sam-x1 laptop).

---

# System Administration Skill

Use this skill to make changes to system services, users, and settings. All operations require confirmation and have safety checks.

## Workflow Checklist

### 1. Identify the Administrative Task
- [ ] What needs to be changed? (service/user/permissions/settings)
- [ ] Is this urgent or routine maintenance?
- [ ] Does it only affect this machine or both machines?
- [ ] Will it require sudo/root access?

### 2. Machine Awareness
Some tasks differ by machine:

**On SamPC (Desktop):**
- May manage OpenDeck service (if installed)
- Desktop power profiles
- 3-monitor-related services/settings
- Desktop peripheral drivers

**On sam-x1 (Laptop):**
- TLP/TLP-Sleep power management
- Laptop power profiles
- Suspend/hibernate settings
- Battery management
- Thermal management

### 3. Safety Pre-Checks

Before ANY administrative change:
- [ ] Am I about to make a destructive change?
- [ ] Do I have a backup/rollback plan?
- [ ] Is this change reversible?
- [ ] Are there dependencies I should check?
- [ ] Should I verify the change afterward?

**Never:**
- Modify critical system files without backup
- Kill/restart services without understanding impact
- Change permissions without testing access
- Add users without verifying access requirements
- Make changes during critical operations

### 4. Service Management

#### Start a Service
```bash
# Check if service exists and is stopped
systemctl status SERVICE_NAME

# Start it
sudo systemctl start SERVICE_NAME

# Verify it started
systemctl is-active SERVICE_NAME
systemctl status SERVICE_NAME
```

**Safety checklist:**
- [ ] Does service exist?
- [ ] Is it currently stopped?
- [ ] Are dependencies available?
- [ ] Will starting it cause conflicts?

#### Stop a Service
```bash
# Check current status
systemctl status SERVICE_NAME

# Stop it gracefully
sudo systemctl stop SERVICE_NAME

# Verify it stopped (give it a moment)
sleep 2 && systemctl is-active SERVICE_NAME

# Check logs for shutdown issues
journalctl -u SERVICE_NAME --since="1 min ago"
```

**Safety checklist:**
- [ ] Is any process depending on this service?
- [ ] Is stopping it safe right now?
- [ ] Are there active connections that will drop?
- [ ] Do I understand why I'm stopping it?

**Example: Stop SSH for config edits**
```bash
# Before stopping SSH:
systemctl status sshd
who  # See active SSH connections

# Understand impact: Active users will be disconnected!
# Decide: Is this safe? Do you need to notify users?

# Then stop
sudo systemctl stop sshd
```

#### Restart a Service
```bash
# Most common operation - restart after config change
sudo systemctl restart SERVICE_NAME

# Verify it restarted
systemctl is-active SERVICE_NAME

# Check for startup errors
journalctl -u SERVICE_NAME -n 20
```

**Common restart reasons:**
- Config file updated (DNS, networking, app config)
- Apply security patches
- Fix stuck connections
- Reload after permission changes

**Safety:**
- Config changes applied correctly before restart
- Service will re-read config on startup
- Brief downtime (usually <1 second)

#### Enable/Disable on Boot
```bash
# Enable: service starts on system boot
sudo systemctl enable SERVICE_NAME

# Disable: service won't start on boot
sudo systemctl disable SERVICE_NAME

# Verify
systemctl is-enabled SERVICE_NAME  # Returns 'enabled' or 'disabled'
```

**Decision tree:**
- Should this service always run? → Enable
- Should it only run on demand? → Disable
- Is it critical? → Enable
- Is it optional/experimental? → Disable

### 5. User Management

#### Add a New User
```bash
# Add user with home directory
sudo useradd -m -s /bin/bash USERNAME

# Set password
sudo passwd USERNAME

# Verify user created
id USERNAME

# Check home directory
ls -la /home/USERNAME
```

**Pre-flight checks:**
- [ ] Does user already exist? `id USERNAME`
- [ ] What shell should they use? (bash, fish, zsh)
- [ ] Do they need sudo access?
- [ ] Should they be in specific groups?

**Add user to sudo group:**
```bash
# If they need sudo access
sudo usermod -aG sudo USERNAME

# Verify
groups USERNAME  # Should show 'sudo'

# Test (as that user)
sudo whoami  # Should print 'root'
```

**Add user to other groups:**
```bash
# Common groups on Arch:
sudo usermod -aG docker USERNAME     # Docker access
sudo usermod -aG audio USERNAME      # Audio devices
sudo usermod -aG video USERNAME      # GPU access
sudo usermod -aG wheel USERNAME      # Wheel group (alt to sudo)

# Verify
groups USERNAME
```

#### Remove a User
```bash
# List what user owns
find / -user USERNAME 2>/dev/null | head -20

# Backup home directory (optional)
sudo cp -r /home/USERNAME /tmp/USERNAME-backup

# Remove user and home directory
sudo userdel -r USERNAME

# Verify removed
id USERNAME  # Should fail: 'no such user'
```

**DANGER:** This is destructive!
- All home directory files are deleted
- User data is lost (unless backed up)
- Services run as this user will break

**Safer approach:**
```bash
# Just disable, don't delete
sudo usermod -L USERNAME  # Lock account
sudo usermod -s /usr/sbin/nologin USERNAME  # Disable login
```

#### Modify User
```bash
# Change shell
sudo usermod -s /bin/fish USERNAME

# Add to group
sudo usermod -aG GROUPNAME USERNAME

# Lock/unlock account
sudo usermod -L USERNAME  # Lock
sudo usermod -U USERNAME  # Unlock

# Change home directory
sudo usermod -d /new/home/path USERNAME
```

### 6. File Permissions

#### Understanding Permissions
```bash
# Example: -rw-r--r-- 1 user group 1234 date filename
#          ^^^^^^^^^^   ^^^^ ^^^^^
#          permissions  user group

# Permission format: [owner][group][others]
# r (read=4), w (write=2), x (execute=1)
# Example: 755 = rwx r-x r-x (owner can all, others can read+exec)
```

#### Change Permissions
```bash
# Make file readable by all
chmod 644 FILENAME  # rw- r-- r--

# Make file executable
chmod 755 FILENAME  # rwx r-x r-x

# Make file private (owner only)
chmod 600 FILENAME  # rw- --- ---

# Remove all permissions (dangerous!)
chmod 000 FILENAME  # --- --- ---

# Add execute permission to owner
chmod u+x FILENAME

# Remove write from group
chmod g-w FILENAME

# Recursive (all files in directory)
chmod -R 755 DIRECTORY
```

**Common scenarios:**
```bash
# Config file (owner only)
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa

# Shared directory
chmod 755 /shared/dir

# Script file
chmod 755 script.sh

# Avoid this:
chmod 777 ANYTHING  # Never make everything writable to everyone!
```

#### Change Ownership
```bash
# Change owner
sudo chown NEWUSER FILENAME

# Change owner and group
sudo chown NEWUSER:NEWGROUP FILENAME

# Recursive
sudo chown -R NEWUSER:NEWGROUP DIRECTORY

# Example: Fix home directory ownership
sudo chown -R samhl:samhl /home/samhl
```

### 7. Systemd Unit Management

#### Check Unit Status
```bash
# Status of one unit
systemctl status SERVICE_NAME

# List all units (verbose)
systemctl status

# List running units
systemctl list-units --state=running

# List failed units
systemctl list-units --state=failed

# Find all units with a pattern
systemctl list-units -all | grep PATTERN
```

#### Edit Unit Configuration
```bash
# View active config
systemctl cat SERVICE_NAME

# Edit with override (doesn't modify original file)
sudo systemctl edit SERVICE_NAME
# This creates /etc/systemd/system/SERVICE_NAME.d/override.conf
# Add your overrides there

# Reload after editing
sudo systemctl daemon-reload

# Restart service
sudo systemctl restart SERVICE_NAME
```

**Example: Add environment variable to service**
```bash
sudo systemctl edit SERVICE_NAME

# In the editor, add:
[Service]
Environment="VAR_NAME=value"

# Save and exit

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart SERVICE_NAME
```

### 8. Network Interface Management

#### Check Interface Status
```bash
# Show all interfaces
ip link show

# Show IP addresses
ip addr show

# Show routes
ip route show

# More detailed
nmcli device status  # If using NetworkManager
```

#### Restart Networking
```bash
# Safe restart of networking
sudo systemctl restart systemd-networkd

# Or if using NetworkManager
sudo systemctl restart NetworkManager

# Check status after
systemctl status systemd-networkd
ip addr show
```

**Before restarting network:**
- [ ] Are you SSH'd in remotely? (This will disconnect you)
- [ ] Is anything critical downloading?
- [ ] Do you understand how networking is configured?

### 9. Common Administrative Tasks

#### Restart DNS Resolution
```bash
# Check current DNS
resolvectl status

# Restart DNS daemon
sudo systemctl restart systemd-resolved

# Verify
resolvectl status
nslookup google.com  # Test DNS
```

**When to do this:**
- DNS queries hanging
- Can't resolve domain names
- Changed DNS settings

#### Clean Up Disk Space
```bash
# Remove old package cache (safe)
paccache -r

# Remove ALL package cache (dangerous - can't reinstall from cache)
paccache -ruk0

# Clean package downloads
rm -rf ~/.cache/pacman/pkg/*

# Clean journal logs (keep 1 month)
sudo journalctl --vacuum=time=30d

# Find large files
find ~ -type f -size +100M  # Files > 100MB
```

**Safety:**
- Use `paccache -r` first (keeps latest packages)
- Only use `paccache -ruk0` if space is critical
- Journal cleaning is usually safe

#### Manage Power Profiles (Laptop)
```bash
# Check available profiles
powerprofilesctl list

# Set power profile
powerprofilesctl set performance  # Max performance
powerprofilesctl set balanced     # Balanced
powerprofilesctl set power-saver  # Minimum power

# Check current
powerprofilesctl get

# On battery vs plugged in (automatic with tlp)
systemctl status tlp
```

#### Manage TLP Power Management (Laptop - sam-x1)
```bash
# Check TLP status
systemctl status tlp
systemctl status tlp-sleep

# View current power settings
sudo tlp-stat -s  # Power state
sudo tlp-stat -b  # Battery info
sudo tlp-stat -t  # Thermal info

# Apply settings from config
sudo tlp start

# Disable TLP
sudo systemctl stop tlp
sudo systemctl disable tlp
```

### 10. Machine-Specific Administrative Tasks

#### SamPC (Desktop)

**OpenDeck Management** (if installed):
```bash
# Check OpenDeck service
systemctl status opendeck

# Start/stop OpenDeck
sudo systemctl start opendeck
sudo systemctl stop opendeck

# Check logs
journalctl -u opendeck -n 50
```

**Desktop Power Settings:**
```bash
# Performance power profile
powerprofilesctl set performance

# Check CPU frequency scaling
cat /proc/cpuinfo | grep MHz
```

#### sam-x1 (Laptop)

**Battery/Power Management:**
```bash
# Check battery
upower -e
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Check power profiles
powerprofilesctl list
powerprofilesctl get

# TLP configuration (main power tool for laptops)
systemctl status tlp
sudo tlp-stat -p
```

**Thermal Management:**
```bash
# Check temperatures
sensors

# Monitor continuously
watch -n 1 sensors

# If thermal throttling
sudo systemctl restart thermald  # If available
```

### 11. Pre-Change Checklist

Before making ANY administrative change:

**Documentation**
- [ ] Understand what I'm changing
- [ ] Know the before state (note current settings)
- [ ] Know the after state (what should happen)
- [ ] Know how to revert if needed

**Testing**
- [ ] Did I test this safely first? (dry run/staging)
- [ ] Do I have a rollback plan?
- [ ] What will break if this fails?

**Impact Analysis**
- [ ] Will other services be affected?
- [ ] Will users be impacted?
- [ ] Is this the right time to make this change?
- [ ] Should I notify anyone?

**Safety**
- [ ] Is this change reversible?
- [ ] Did I create backups?
- [ ] Do I have sudo access?
- [ ] Am I logged in locally (not remote SSH)?

### 12. Post-Change Verification

After each administrative change:

```bash
# Verify the change took effect
systemctl status SERVICE_NAME

# Check for errors
journalctl -u SERVICE_NAME -n 20

# Test functionality
# (depends on what changed)

# Log the change (optional but recommended)
echo "$(date): Changed SERVICE_NAME - reason" >> ~/.admin-log
```

## Red Flags 🚩

Stop and ask for help if:
- [ ] Command hangs or doesn't respond
- [ ] Unexpected error messages
- [ ] Service won't start after change
- [ ] Multiple services broke after one change
- [ ] Can't SSH in to fix a remote system
- [ ] File ownership wrong after change
- [ ] Permissions too restrictive (can't read critical files)
- [ ] Permissions too open (security issue)

## Safety Guardrails ✅

**NEVER:**
- ❌ Use `chmod 777` on anything
- ❌ Delete system directories
- ❌ Modify core systemd units without override
- ❌ Kill PID 1 (systemd) or critical processes
- ❌ Remove all backups before testing
- ❌ Make changes over unstable SSH
- ❌ Run untested administrative scripts
- ❌ Ignore error messages and proceed

**ALWAYS:**
- ✅ Check before changing
- ✅ Understand the impact
- ✅ Have a rollback plan
- ✅ Backup critical files
- ✅ Test in safe environment first
- ✅ Verify the change worked
- ✅ Document what you changed
- ✅ Ask for confirmation before destructive changes

## Success Criteria ✅

After administrative action:
- [ ] Change was applied successfully
- [ ] System is stable (no new errors)
- [ ] Affected services are working
- [ ] No unintended side effects
- [ ] Change is documented
- [ ] Rollback plan is ready if needed
- [ ] Tested that functionality works as intended

## Common Commands Reference

```bash
# Service management quick reference
sudo systemctl status SERVICE        # Check status
sudo systemctl start SERVICE         # Start
sudo systemctl stop SERVICE          # Stop
sudo systemctl restart SERVICE       # Restart
sudo systemctl enable SERVICE        # Enable on boot
sudo systemctl disable SERVICE       # Disable on boot

# User management quick reference
sudo useradd -m -s /bin/bash USER   # Add user
sudo passwd USER                     # Set password
sudo usermod -aG GROUP USER          # Add to group
sudo userdel -r USER                 # Delete user
groups USER                          # Show groups

# Permission quick reference
chmod 644 FILE       # rw- r-- r-- (documents)
chmod 755 FILE       # rwx r-x r-x (scripts)
chmod 600 FILE       # rw- --- --- (secrets)
chmod -R 755 DIR     # Recursive

# System quick reference
sudo systemctl daemon-reload         # Reload systemd
sudo journalctl -u SERVICE -n 50    # Last 50 logs
sudo systemctl list-units --failed  # Failed services
```
