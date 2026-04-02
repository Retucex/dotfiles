---
name: managing-linux-system
description: Router skill for Arch Linux system management. Dispatches diagnostic, administrative, and package management tasks to appropriate sub-skills with machine awareness for SamPC (desktop) and sam-x1 (laptop).

---

# Managing Linux System - Main Dispatcher Skill

This is the entry point for all system management tasks. It routes your request to the appropriate sub-skill:
- **system-diagnostics** - Troubleshoot and check system health
- **system-administration** - Make system changes (services, users, settings)
- **system-package-management** - Install/update/remove packages

## Quick Decision Tree

### What do you want to do?

**I want to CHECK or TROUBLESHOOT:**
- "Is SSH running?"
- "Are my disks mounted?"
- "Why is my system slow?"
- "Check my network"
- "Show me disk usage"

→ **USE: system-diagnostics**

---

**I want to CHANGE or MANAGE:**
- "Start Docker"
- "Restart systemd-resolved"
- "Stop SSH service"
- "Enable service on boot"
- "Add a new user"
- "Change file permissions"

→ **USE: system-administration**

---

**I want to INSTALL, UPDATE, or REMOVE:**
- "Install neovim"
- "Update all packages"
- "Remove flatpak"
- "Search for a package"
- "What new packages did I install?"

→ **USE: system-package-management**

---

## How This Works

### You Ask a Question
```
"Is my network working?"
```

### The System Classifies It
```
Is it a diagnostic question? → YES
Load: system-diagnostics
```

### Sub-Skill Executes
```
system-diagnostics runs:
1. Check IP address
2. Check DNS
3. Check connectivity
4. Report status
```

### You Get Results
```
Network Status: ✅ Working
- IP: 192.168.1.100
- DNS: Configured and working
- Internet: Connected
```

---

## Examples for Each Category

### Diagnostics Examples

**Question:** "Is SSH running?"
```
Routed to: system-diagnostics
Checks:
- systemctl status sshd
- Port 22 listening?
- Enabled on boot?
Report: SSH status with suggestions
```

**Question:** "Are my disks mounted?"
```
Routed to: system-diagnostics
Checks:
- mount status
- lsblk -f
- df -h
- Usage report
Report: All mounts and health
```

**Question:** "Why is my system slow?" (SamPC)
```
Routed to: system-diagnostics
Checks:
- CPU usage
- Memory usage
- Disk I/O
- Top processes
- Recent errors
Report: Identifies bottleneck
Suggestion: May route to system-administration if action needed
```

**Question:** "What's using all my disk space?"
```
Routed to: system-diagnostics
Checks:
- df -h
- du -sh /*
- Large files
- Cache directories
Report: Disk space breakdown
Suggestion: "Consider cleaning [location]"
```

### Administration Examples

**Request:** "Start Docker"
```
Routed to: system-administration
Safety checks:
- ✓ Docker exists
- ✓ User has sudo
- Asks: Confirm start Docker?
Executes:
- sudo systemctl start docker
Verifies:
- systemctl is-active docker
- Shows status
```

**Request:** "Restart systemd-resolved"
```
Routed to: system-administration
Safety checks:
- ✓ Service exists
- ✓ Not critical (brief downtime ok)
- Asks: Confirm restart DNS?
Executes:
- sudo systemctl restart systemd-resolved
Warns: May interrupt DNS queries
Verifies: Service restarted
```

**Request:** "Enable SSH on boot"
```
Routed to: system-administration
Safety checks:
- ✓ SSH service exists
- ✓ Not already enabled
Executes:
- sudo systemctl enable sshd
Verifies:
- systemctl is-enabled sshd
Report: SSH now starts on boot
```

**Request:** "Add a new user"
```
Routed to: system-administration
Asks:
- Username?
- Shell preference?
- Need sudo access?
- Add to special groups?
Executes:
- sudo useradd -m -s /bin/bash USERNAME
- sudo passwd USERNAME (prompt for password)
- sudo usermod -aG sudo USERNAME (if needed)
Verifies:
- User created
- Groups set
- Home directory ready
```

### Package Management Examples

**Request:** "Install neovim"
```
Routed to: system-package-management
Checks:
- Available in repos? YES
- Already installed? NO
Executes:
- sudo pacman -S neovim
Asks: Universal or machine-specific?
If universal:
- Syncs to chezmoi packages.txt
- Commits: "chore: add neovim"
- Both machines will get it on next update
```

**Request:** "Update all packages"
```
Routed to: system-package-management
Executes:
- sudo pacman -Syu
Checks for:
- New dependencies
- Conflicts
- Disk space
Post-update:
- Checks for errors
- Offers to sync new packages to chezmoi
Report: X packages updated, Y new installed
```

**Request:** "Remove flatpak"
```
Routed to: system-package-management
Checks:
- Is flatpak installed? YES
- Other packages depend on it? Check
Asks: Remove with dependencies? (Rns)
Executes:
- sudo pacman -Rns flatpak
Verifies: Flatpak removed
Offers: Sync to chezmoi? (mark as removed)
```

---

## Machine-Aware Behavior

### SamPC (Desktop) Specific

**Diagnostic checks include:**
- OpenDeck service status (if installed)
- 3-monitor layout status
- Desktop GPU status
- Desktop-specific mounts

**Administration can handle:**
- OpenDeck service control
- 3-monitor settings
- Desktop power profiles

**Package management handles:**
- @SamPC packages only installed here
- Universal packages on both

### sam-x1 (Laptop) Specific

**Diagnostic checks include:**
- TLP power management status
- Battery information
- Power profile current
- Thermal info
- Suspend readiness

**Administration can handle:**
- TLP service control
- Power profile switching
- Battery/thermal settings

**Package management handles:**
- @sam-x1 packages only installed here
- Universal packages on both

---

## When to Use Each Sub-Skill

### system-diagnostics
**Use for:**
- Checking status
- Troubleshooting problems
- Understanding what's happening
- Getting system information
- Health checks

**Safety:** 100% safe - read-only
**Risk:** None - can run anytime

### system-administration
**Use for:**
- Starting/stopping services
- Managing users
- Changing settings
- Enabling/disabling features
- Any change to system state

**Safety:** Medium - requires confirmation
**Risk:** Low - changes are reversible with rollback plan

### system-package-management
**Use for:**
- Installing packages
- Updating system
- Removing packages
- Finding packages
- Syncing to chezmoi

**Safety:** Medium - may update multiple things
**Risk:** Medium - large updates can cause issues, recovery available via rollback

---

## Integrated Workflows

### Workflow 1: Diagnose and Fix

```
1. User asks: "Why is my internet not working?"
   ↓
2. Route to: system-diagnostics
   - Checks network status
   - Identifies: DNS not resolving
   ↓
3. Suggest: "Run system-administration: restart DNS"
   ↓
4. User runs system-administration
   - Restarts systemd-resolved
   - Verifies DNS working
   ↓
5. Result: Internet working again
```

### Workflow 2: Check and Update

```
1. User asks: "Update my system"
   ↓
2. Route to: system-package-management
   - Runs: sudo pacman -Syu
   - Reports: 27 packages updated
   ↓
3. Script runs: packages-update.sh
   - Detects: 3 new dependencies installed
   - Asks: Add to chezmoi?
   ↓
4. Commit to git:
   - git add packages.txt
   - git commit -m "chore: system update brought new packages"
   - git push
   ↓
5. Result: Both machines stay synchronized
```

### Workflow 3: Install New Tool

```
1. User asks: "Install ripgrep"
   ↓
2. Route to: system-package-management
   - Search: Found in official repos
   - Install: sudo pacman -S ripgrep
   ↓
3. Ask: "Universal or machine-specific?"
   - Answer: Universal
   ↓
4. Sync to chezmoi:
   - Update packages.txt
   - Commit with message
   - Push to GitHub
   ↓
5. On sam-x1:
   - chezmoi update
   - chezmoi apply
   - ripgrep automatically installed
   ↓
6. Result: Tool available on both machines
```

---

## Quick Command Reference

### Diagnostics Questions
```
"Is SSH running?"
→ system-diagnostics → systemctl status sshd

"Are my disks mounted?"
→ system-diagnostics → lsblk -f; mount

"Show me disk usage"
→ system-diagnostics → df -h; du -sh /*

"Is network working?"
→ system-diagnostics → ip addr; resolvectl status

"What's using all my RAM?"
→ system-diagnostics → ps aux --sort=-%mem
```

### Administration Actions
```
"Start Docker"
→ system-administration → sudo systemctl start docker

"Restart DNS"
→ system-administration → sudo systemctl restart systemd-resolved

"Add user"
→ system-administration → sudo useradd -m -s /bin/bash user

"Enable service on boot"
→ system-administration → sudo systemctl enable service
```

### Package Tasks
```
"Install neovim"
→ system-package-management → sudo pacman -S neovim

"Update system"
→ system-package-management → sudo pacman -Syu

"Remove flatpak"
→ system-package-management → sudo pacman -Rns flatpak

"Search for package"
→ system-package-management → pacman -Ss search_term
```

---

## Decision Matrix

| Task | Category | Sub-Skill | Destructive | Confirmation |
|------|----------|-----------|------------|--------------|
| Check service | Diagnostic | diagnostics | No | No |
| Start service | Admin | administration | Yes | Yes |
| Install package | Package | package-management | Yes | Yes |
| Update system | Package | package-management | Yes | Yes |
| Check disk usage | Diagnostic | diagnostics | No | No |
| Remove user | Admin | administration | Yes | Yes |
| Search package | Package | package-management | No | No |
| Check RAM usage | Diagnostic | diagnostics | No | No |
| Enable on boot | Admin | administration | Yes | Yes |
| Check network | Diagnostic | diagnostics | No | No |

---

## Chaining Skills Together

Sometimes a task requires multiple skills:

### Example: "Fix my network and update the system"

```
Step 1: Diagnose
→ system-diagnostics
"Network is down - DNS not responding"

Step 2: Fix
→ system-administration
sudo systemctl restart systemd-resolved
"Network restored"

Step 3: Update
→ system-package-management
sudo pacman -Syu
"System updated, 3 new packages installed"

Step 4: Sync
→ system-package-management
packages-update.sh
"New packages added to chezmoi"

Result: Full workflow completed
```

---

## Safety Reminders

### For Diagnostics
- ✅ All read-only - always safe
- ✅ Can run as regular user
- ✅ No data at risk
- ✅ Safe to run repeatedly

### For Administration
- ⚠️ Requires sudo/confirmation
- ⚠️ Makes system changes
- ⚠️ Have rollback plan
- ⚠️ Don't use over unstable SSH
- ✅ Minor changes usually reversible

### For Package Management
- ⚠️ May update many packages
- ⚠️ Can affect system stability
- ⚠️ Need stable internet
- ⚠️ Disk space required
- ✅ Can usually rollback via package cache

---

## When to Escalate

These situations should probably not be handled by the automated skills:

- [ ] System won't boot
- [ ] Critical file corruption
- [ ] Hardware failure
- [ ] Cascading service failures
- [ ] Unknown critical processes
- [ ] Complex multi-step configuration
- [ ] Security incident response

**What to do:** Document the problem, check logs, and consider asking for expert help.

---

## Success: You Got Help When You Needed It

After using the managing-linux-system ecosystem:

- [ ] Diagnosed the problem correctly
- [ ] Understood the root cause
- [ ] Made appropriate changes
- [ ] System is stable
- [ ] Changes are documented/synced
- [ ] Both machines stay synchronized
- [ ] You learned something new
