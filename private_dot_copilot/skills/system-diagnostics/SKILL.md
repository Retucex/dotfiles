---
name: system-diagnostics
description: Diagnose system health - check services, disks, network, resources, and logs. Read-only diagnostics with troubleshooting suggestions for Arch Linux systems (SamPC desktop and sam-x1 laptop).

---

# System Diagnostics Skill

Use this skill to troubleshoot and monitor system health. All operations are read-only and safe to run anytime.

## Workflow Checklist

### 1. Identify the Diagnostic Need
- [ ] What are you checking? (service/disk/network/resources/logs/process)
- [ ] Is this urgent troubleshooting or routine health check?
- [ ] Does it affect a specific machine (SamPC or sam-x1)?

### 2. Machine Context
Current machine affects some checks:

**On SamPC (Desktop):**
- Check OpenDeck service status (if installed)
- Monitor 3-monitor display setup
- Desktop-specific services (if any)
- Check for external drives/NAS mounts

**On sam-x1 (Laptop):**
- Check TLP power management (tlp, tlp-rdw)
- Monitor battery status
- Check single monitor setup
- Check suspend/hibernate readiness

### 3. Select Diagnostic Category
- **Service Status** - Check if service is running/enabled
- **Disk & Mounts** - Verify disks are mounted, check usage
- **Network** - Check IP, DNS, connectivity, firewall
- **Resources** - Monitor CPU, RAM, disk I/O usage
- **Logs** - Check systemd journal for errors
- **Process** - Find what's running, consuming resources
- **Ports** - See what's listening and where

### 4. Run Appropriate Checks

#### Service Status Check
```bash
# Check if a service is running
systemctl is-active SERVICE_NAME

# Check if enabled on boot
systemctl is-enabled SERVICE_NAME

# Show full status
systemctl status SERVICE_NAME

# Example: SSH
systemctl status sshd
systemctl is-active sshd
ss -tulpn | grep :22  # Check port 22

# Example: Docker (if installed)
systemctl status docker
systemctl is-active docker
```

**Common Services to Check:**
- sshd (SSH server)
- docker/podman (containers)
- systemd-resolved (DNS)
- systemd-networkd (networking)
- pulseaudio/pipewire (audio)
- tlp (laptop power management)
- opendeck (desktop hardware - SamPC only)

#### Disk & Mount Check
```bash
# See all mounts
mount

# Better format
lsblk -f  # Shows file systems

# Disk usage
df -h     # Human-readable disk space
du -sh /*  # Directory sizes

# Check specific mount
mountpoint /path/to/mount

# Find unmounted devices
lsblk  # Shows all devices with mount points
```

**What to look for:**
- Root (/) mounted read-write
- /home mounted (should be read-write)
- /boot mounted (if separate partition)
- External drives mounted if expected
- No "unmounted" status for critical partitions

#### Network Diagnostics
```bash
# Check IP address
ip addr show

# Check default route
ip route show

# Check DNS resolution
resolvectl status
cat /etc/resolv.conf

# Test connectivity
ping 8.8.8.8  # Google DNS
ping google.com  # DNS test

# Check listening ports
ss -tulpn

# Check firewall (if using)
sudo firewall-cmd --list-all  # If using firewalld
sudo ufw status  # If using ufw
```

**Common issues:**
- No IP address assigned
- DNS not resolving
- Firewall blocking connections
- Routing problems

#### Resource Usage Check
```bash
# Quick overview
btop  # Better top (installed in your setup)

# Or if not available:
top -b -n 1 -u $USER  # One iteration of top

# Per-process
ps aux

# Memory
free -h

# Disk I/O
iostat -x 1 5  # 5 iterations, 1 second interval

# Process by resource
ps aux --sort=-%mem | head -10  # Top by memory
ps aux --sort=-%cpu | head -10  # Top by CPU
```

**Warning signs:**
- CPU at 100% consistently
- Memory nearly full (>90%)
- Disk I/O at 100% for extended periods
- One process using excessive resources

#### Log Checking
```bash
# Recent errors/warnings
journalctl -p err -n 20  # Last 20 errors

# Last hour of logs
journalctl --since="1 hour ago"

# Specific service logs
journalctl -u SERVICE_NAME

# Real-time log watch
journalctl -f

# Specific time range
journalctl --since "2026-04-02 20:00" --until "2026-04-02 23:00"

# Full verbose logs
journalctl -x -n 50  # Verbose, last 50 lines
```

**What to look for:**
- Error patterns (repeated errors often point to root cause)
- Recently started/stopped services
- Permission denied messages
- Timeout/connection errors

#### Process Investigation
```bash
# Find process by name
ps aux | grep PROCESS_NAME

# Find what's listening on port
ss -tulpn | grep :PORT_NUMBER

# Show open files for process
lsof -p PID

# Process tree
pstree -p

# Process memory/CPU
ps -o pid,user,vsz,rss,%mem,%cpu,comm | sort -k5 -rn
```

**Example:**
```bash
# Find what's using port 8080
ss -tulpn | grep :8080

# Find what's listening on SSH
ss -tulpn | grep :22

# Show all SSH connections
ss -tulpn | grep sshd
```

### 5. Interpret Results & Suggest Fixes

**Service not running:**
- Is it installed? `pacman -Q SERVICE_NAME`
- Is it enabled? `systemctl enable SERVICE_NAME`
- Why did it stop? `journalctl -u SERVICE_NAME -n 50`
- Suggestion: "Try: sudo systemctl start SERVICE_NAME"

**Disk full:**
- What's using space? `du -sh /* | sort -rh | head -10`
- Can you delete? Check: `~/.cache`, `/tmp`, package caches
- Suggestion: "Run: paccache -r to clean old packages"

**Network down:**
- Is interface up? `ip link show`
- Can ping localhost? `ping 127.0.0.1`
- Can ping gateway? `ip route show` then `ping GATEWAY_IP`
- Suggestion: "Try: sudo systemctl restart systemd-networkd"

**High resource usage:**
- Is it a known process? Check startup apps, background services
- Can it be killed? `kill -15 PID` (graceful) or `kill -9 PID` (force)
- Suggestion: "This might need investigation in system-administration"

### 6. Machine-Specific Checks

**On SamPC (Desktop):**
```bash
# Check OpenDeck if installed
systemctl status opendeck  # If you have OpenDeck hardware

# Check 3-monitor setup
xrandr  # X11 way
wlr-randr  # Wayland way
hyprctl monitors  # If using Hyprland
```

**On sam-x1 (Laptop):**
```bash
# Check TLP power management
systemctl status tlp
systemctl status tlp-sleep  # Sleep hooks

# Battery status
upower -e
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Power profiles
powerprofilesctl get

# Thermal
sensors  # Temperature readings
watch -n 1 sensors  # Monitor temperatures
```

### 7. Report Findings

**Format:**
```
Service/Item: [Name]
Status: [Running/Stopped/N/A]
Enabled on boot: [Yes/No/N/A]
Health: [Green ✅ / Yellow ⚠️ / Red ❌]
Details: [What you found]
Suggestion: [What to do if needed]
```

**Example:**
```
Service: SSH (sshd)
Status: Running ✅
Enabled: Yes ✅
Port: 22
Health: Green ✅
Details: SSH is active and listening on all interfaces
Suggestion: All good! No action needed.

---

Mount: /home
Status: Mounted ✅
Used: 450 GB / 1 TB (45%)
Health: Green ✅
Details: Home directory is accessible with good space
Suggestion: Monitor before hitting 80%

---

CPU Usage: 25% (2 cores active)
Memory Usage: 6.2 GB / 16 GB (38%)
Health: Green ✅
Details: System running well, plenty of headroom
Suggestion: No action needed
```

## Common Diagnostic Scenarios

### Scenario 1: "Is my SSH working?"
```
Check:
1. systemctl status sshd → active (running)?
2. systemctl is-enabled sshd → enabled?
3. ss -tulpn | grep :22 → listening on :22?
4. journalctl -u sshd -n 10 → any recent errors?

Result:
✅ If all green: SSH is working
⚠️ If not enabled: "Try: sudo systemctl enable sshd"
❌ If not running: "Try: sudo systemctl start sshd"
```

### Scenario 2: "Are my disks mounted?"
```
Check:
1. lsblk -f → see all devices and mounts
2. mount → check mount points
3. df -h → check space usage

Result:
✅ All expected disks mounted with good space
⚠️ If partition is unmounted: "This needs admin intervention"
❌ If full: "Need to clean up or add space"
```

### Scenario 3: "Is my network working?"
```
Check:
1. ip addr show → have IP address?
2. ip route show → have default route?
3. resolvectl status → can resolve DNS?
4. ping 8.8.8.8 → can reach internet?

Result:
✅ All green: Network is good
⚠️ No IP: "Interface may not be configured"
❌ No internet: "Network interface issue"
```

### Scenario 4: "What's using all my disk space?"
```
Check:
1. df -h / → which partition is full?
2. du -sh /* → what's in root?
3. du -sh ~/* → what's in home?
4. du -sh ~/.cache/* → cache directories

Result:
Identify the culprit:
- /var/log too large?
- ~/.cache/something huge?
- Downloads folder?

Suggestion: "Clean up [specific location]"
```

### Scenario 5: "Why is my system slow?" (SamPC)
```
Check:
1. btop → overall resource usage
2. ps aux --sort=-%cpu | head → top CPU hogs
3. ps aux --sort=-%mem | head → top memory hogs
4. iostat -x 1 5 → disk I/O
5. journalctl -p err -n 20 → recent errors

Result:
Identify the bottleneck:
- CPU maxed? What process?
- Memory filling up? Which app?
- Disk I/O stuck? What's accessing disk?

Suggestion: Point to system-administration for remediation
```

### Scenario 6: "Laptop battery dying fast" (sam-x1)
```
Check:
1. upower -e → battery info
2. systemctl status tlp → power management running?
3. powerprofilesctl get → power profile set?
4. sensors → CPU temperature high?
5. ps aux --sort=-%cpu | head → what's using CPU?

Result:
✅ TLP is running and power profile is good
⚠️ High CPU usage when idle = investigate process
❌ TLP not running = system-administration can fix
```

## Red Flags 🚩

Stop and escalate to system-administration if:
- [ ] Service won't start (needs troubleshooting/fixes)
- [ ] Disk is full (needs cleanup/expansion)
- [ ] Out of memory (needs process killing/investigation)
- [ ] Network completely down (needs interface restart)
- [ ] Repeated error patterns in logs (needs deep investigation)
- [ ] Unknown process consuming resources (needs analysis)
- [ ] Hardware errors appearing (may need hardware check)

## Safety Checklist ✅

- [x] All diagnostics are read-only
- [x] No changes made to system
- [x] No data at risk
- [x] Safe to run repeatedly
- [x] Can be run on both machines
- [x] Suggests next steps instead of forcing them
- [x] No destructive commands

## Success Criteria ✅

After diagnostic:
- [ ] You understand the system status
- [ ] You know what's working and what's not
- [ ] You have suggestions for next steps
- [ ] If needed, you know what to escalate to system-administration
- [ ] You can decide if action is needed or if it's a false alarm

## Useful Commands Reference

```bash
# Quick health check script
echo "=== System Health Check ===" && \
systemctl status systemd-networkd && \
systemctl status sshd && \
df -h / && \
free -h && \
systemctl is-system-running

# What's listening?
ss -tulpn

# Top resource users
ps aux --sort=-%mem | head -5
ps aux --sort=-%cpu | head -5

# Any recent errors?
journalctl -p err -n 20

# Network connectivity
ping -c 1 8.8.8.8 && echo "Internet OK" || echo "No internet"

# Disk full?
du -sh /* | sort -rh
```
