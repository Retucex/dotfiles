name: system-package-management
description: Manage Arch Linux packages with chezmoi integration. Install, update, remove, search packages while maintaining synchronization with chezmoi packages.txt for reproducible multi-machine setups (SamPC desktop and sam-x1 laptop).

---

# System Package Management Skill

Use this skill to install, update, and remove packages while keeping your chezmoi packages.txt synchronized across machines.

## Workflow Checklist

### 1. Identify the Package Task
- [ ] What are you doing? (install/update/remove/search)
- [ ] Is it a single package or multiple?
- [ ] Should this be universal or machine-specific?
- [ ] Is it from official repos or AUR?

### 2. Machine-Specific Considerations

**Packages tracked in packages.txt:**
```
universal_package        # Both machines
@SamPC desktop_package   # SamPC only
@sam-x1 laptop_package   # sam-x1 only
```

**Current packages.txt has:**
```
# Universal (all machines)
kitty, fish, hyprland, etc.

# SamPC only (@SamPC prefix)
opendeck, other-desktop-tools

# sam-x1 only (@sam-x1 prefix)
tlp, tlp-rdw (power management for laptop)
```

**Before installing anything:**
- [ ] Is this going on both machines or just this one?
- [ ] Is it in official Arch repos or AUR?
- [ ] Does it conflict with existing packages?
- [ ] Will it be needed on the other machine too?

### 3. Search for Packages

#### Search Official Repos
```bash
# Search packages
pacman -Ss SEARCH_TERM

# Example
pacman -Ss neovim
pacman -Ss python

# More detailed info
pacman -Si PACKAGE_NAME
```

#### Search AUR
```bash
# Using yay (AUR helper)
yay -Ss SEARCH_TERM

# Example
yay -Ss neovim-git

# Package info
yay -Si PACKAGE_NAME
```

#### Check if Installed
```bash
# Installed locally
pacman -Q PACKAGE_NAME

# Check if available (not installed)
pacman -Sp PACKAGE_NAME | head -1
```

**Decision tree:**
```
Found in official repos?
├─ YES → Use pacman -S
└─ NO → Check AUR
   ├─ In AUR? → Use yay -S
   └─ Not in AUR? → Package doesn't exist or needs custom build
```

### 4. Install Packages

#### Install from Official Repos
```bash
# Install single package
sudo pacman -S PACKAGE_NAME

# Install multiple packages
sudo pacman -S PACKAGE1 PACKAGE2 PACKAGE3

# Example
sudo pacman -S neovim ripgrep fzf

# Confirm if prompted
# Type 'y' and press Enter
```

**Before confirming:**
- [ ] Is this package what I want?
- [ ] Any conflicting packages listed?
- [ ] Disk space available?

#### Install from AUR
```bash
# Install single AUR package
yay -S PACKAGE_NAME

# Install multiple
yay -S PACKAGE1 PACKAGE2

# Example
yay -S spotify-client
```

**AUR packages:**
- May require compilation (takes time)
- May need additional dependencies
- May not be tested as thoroughly as official packages
- Useful for niche tools

#### Install Specific Version
```bash
# Install specific version from official repos
sudo pacman -S PACKAGE_NAME=VERSION

# Example
sudo pacman -S nginx=1.24.0-1

# List available versions
pacman -Si PACKAGE_NAME  # Shows available version
```

### 5. Update/Upgrade Packages

#### Full System Update
```bash
# Update all packages
sudo pacman -Syu

# This is what run_once_setup.sh does on first init
# Safe to run regularly (weekly/monthly recommended)

# Confirm when prompted:
# Type 'y' and press Enter
```

**Warning signs:**
- Very large updates (might be major version bumps)
- Kernel updates (may require reboot to take effect)
- Breaking changes in logs

**After update:**
```bash
# Verify system is stable
systemctl status systemd-journald
journalctl -p err -n 10  # Check for errors
```

#### Update Specific Package
```bash
# Update just one package
sudo pacman -Su PACKAGE_NAME

# Usually just use full update instead:
sudo pacman -Syu
```

#### Check for Updates
```bash
# See what would be updated (dry run)
sudo pacman -Syu --print

# Same for AUR
yay -Sua --print
```

### 6. Remove Packages

#### Remove Package Only (Keep Config)
```bash
# Remove package but keep config
sudo pacman -R PACKAGE_NAME

# Example
sudo pacman -R flatpak

# Confirm removal
# Type 'y' and press Enter
```

**Check dependencies first:**
```bash
# See what depends on this package
pacman -Qi PACKAGE_NAME  # Shows 'Required By:'

# If other packages need it, removal will fail (safe!)
```

#### Remove Package and Dependencies
```bash
# Remove package and unused dependencies
sudo pacman -Rs PACKAGE_NAME

# CAREFUL: might remove shared dependencies other packages need
```

#### Remove Package and Config (Clean)
```bash
# Remove package, dependencies, and config files
sudo pacman -Rns PACKAGE_NAME

# Example (complete removal)
sudo pacman -Rns flatpak

# This is the "clean" removal
```

**Decide which to use:**
- Might reinstall later → Use `-R` (keep config)
- Don't need it anymore → Use `-Rs` (remove deps)
- Want it completely gone → Use `-Rns` (nuke it)

### 7. Clean Package Cache

#### Remove Old Package Versions
```bash
# Keep only latest versions (safe)
paccache -r

# Example output:
# -> found 50 old packages
# -> removed 50 packages

# Verify disk space freed
df -h /var/cache/pacman/pkg/
```

**`paccache` options:**
```bash
paccache -r        # Remove old versions (SAFE - keep latest)
paccache -ruk0     # Remove ALL cached packages (DANGEROUS)
paccache -ri       # Interactive (ask which to remove)
paccache -du       # Show disk usage
```

**NEVER use `paccache -ruk0` unless:**
- You're desperate for disk space
- You're confident you can re-download packages if needed
- You have internet access to reinstall

#### Manual Cache Cleanup
```bash
# Location
ls -lh /var/cache/pacman/pkg/ | head -20

# See how much space
du -sh /var/cache/pacman/pkg/

# Remove everything (NUCLEAR option - not recommended)
sudo rm -rf /var/cache/pacman/pkg/*

# Then download fresh cache if needed
sudo pacman -Sy
```

### 8. Sync New Packages with Chezmoi

**This is the key integration!**

#### Detect New Packages
```bash
# After manually installing packages, run:
~/.local/share/chezmoi/packages-update.sh

# This script:
# 1. Scans your system for installed packages
# 2. Compares against packages.txt
# 3. Finds new packages you installed
# 4. Asks if each is universal or machine-specific
# 5. Updates packages.txt
# 6. Shows git diff for review
```

#### Manual Process (If Script Doesn't Help)
```bash
# Get list of all installed packages
pacman -Q > /tmp/installed.txt

# Compare with tracked packages
diff /tmp/installed.txt ~/.local/share/chezmoi/packages.txt

# Add new ones to packages.txt
nano ~/.local/share/chezmoi/packages.txt

# Format:
# package_name           (universal)
# @SamPC package_name    (SamPC only)
# @sam-x1 package_name   (sam-x1 only)
```

#### Commit Changes
```bash
cd ~/.local/share/chezmoi

# Review changes
git diff packages.txt

# Commit
git add packages.txt
git commit -m "chore: add new packages (machine: scope)"

# Push to both machines
git push
```

**Commit message format:**
```bash
# Universal packages
git commit -m "chore: add neovim, ripgrep (machine: universal)"

# SamPC-only packages
git commit -m "chore: add opendeck-tools (machine: SamPC)"

# Laptop-only packages
git commit -m "chore: add tlp power profiles (machine: sam-x1)"
```

### 9. Workflow Example: Install and Sync

**Complete workflow:**

```bash
# Step 1: Want to install neovim
# Check if available
pacman -Ss neovim | head -5

# Step 2: Install it
sudo pacman -S neovim

# Step 3: Sync to chezmoi
~/.local/share/chezmoi/packages-update.sh

# Script output:
# New package: neovim (not in packages.txt)
# Is this universal or machine-specific? (u/SamPC/sam-x1)
# Type: u (for universal)

# Step 4: Review
cd ~/.local/share/chezmoi
git diff packages.txt

# Shows:
# + neovim

# Step 5: Commit
git commit -m "chore: add neovim (machine: universal)"

# Step 6: Push
git push

# Step 7: On sam-x1 (laptop), pull and apply
chezmoi update && chezmoi apply
# Neovim is now installed on laptop too!
```

### 10. Common Package Management Tasks

#### Install Development Tools
```bash
# Essential build tools
sudo pacman -S base-devel

# Git and version control
sudo pacman -S git git-delta

# Language toolchains (choose what you need)
sudo pacman -S python python-pip
sudo pacman -S nodejs npm
sudo pacman -S rustup

# Then sync to packages.txt
~/.local/share/chezmoi/packages-update.sh
```

#### Remove Bloat
```bash
# Remove flatpak (if you're not using it)
sudo pacman -Rns flatpak

# Remove old Firefox if using newer version
sudo pacman -Rns firefox-old  # If exists

# Clean package cache
paccache -r

# Commit to packages.txt
cd ~/.local/share/chezmoi
git status
git add packages.txt
git commit -m "chore: remove flatpak (machine: universal)"
git push
```

#### Handle Conflicts
```bash
# If trying to install conflicting packages
sudo pacman -S PACKAGE1 PACKAGE2

# Pacman will show conflict and ask which to keep:
# :: package-a and package-b conflict
# Which do you want to remove?
# Type package name to remove, or press Enter to skip

# To force (DANGEROUS - use with caution)
sudo pacman -S --no-confirm PACKAGE1 PACKAGE2
```

### 11. Machine-Specific Package Management

#### On SamPC (Desktop)
```bash
# Desktop packages already tracked:
# @SamPC opendeck (or other desktop tools)

# Example: Add another desktop tool
sudo pacman -S obs-studio  # Screen recording

# Then sync
~/.local/share/chezmoi/packages-update.sh
# Choose: SamPC (not universal)

# Commit
git add packages.txt
git commit -m "chore: add obs-studio for streaming (machine: SamPC)"
git push

# sam-x1 won't install it (not marked @sam-x1)
```

#### On sam-x1 (Laptop)
```bash
# Laptop packages already tracked:
# @sam-x1 tlp, tlp-rdw (power management)

# Example: Add power profile GUI
sudo pacman -S power-profiles-daemon

# Then sync
~/.local/share/chezmoi/packages-update.sh
# Choose: sam-x1 (not universal)

# SamPC won't install it (not marked @SamPC)
```

### 12. Update Workflow

**Regular system maintenance:**

```bash
# Monthly or as desired
sudo pacman -Syu

# Check for errors
journalctl -p err -n 5

# If new packages were installed as dependencies:
~/.local/share/chezmoi/packages-update.sh

# If packages-update.sh added anything:
cd ~/.local/share/chezmoi
git status
git add packages.txt
git commit -m "chore: system update brought in dependencies"
git push
```

### 13. Troubleshooting Package Issues

#### Package Won't Install
```bash
# Check conflicts
sudo pacman -S PACKAGE_NAME

# If conflict shown, choose which to keep
# If it still fails, check:
pacman -Si PACKAGE_NAME  # Is it available?
pacman -Q PACKAGE_NAME   # Already installed?

# Try AUR version (if available)
yay -S PACKAGE_NAME-git  # Git version
```

#### Package Broken After Update
```bash
# Check what broke
journalctl -u PACKAGE_NAME -n 50

# Downgrade to previous version
sudo pacman -U /var/cache/pacman/pkg/PACKAGE_NAME-OLDVERSION.pkg.tar.zst

# Or reinstall
sudo pacman -S PACKAGE_NAME --force
```

#### Dependency Issues
```bash
# Check what depends on this
pacman -Qi PACKAGE_NAME  # Look for "Required By:"

# Force dependency resolution
sudo pacman -S --force PACKAGE_NAME

# Or check for broken dependencies
sudo pacman -Dk  # Check database integrity
```

### 14. AUR Special Notes

**For AUR packages specifically:**

```bash
# Install with yay (recommended AUR helper on Arch)
yay -S PACKAGE_NAME

# Remove AUR package
sudo pacman -R PACKAGE_NAME  # Same as official packages

# Update AUR packages
yay -Sua  # Update all AUR packages

# Clean AUR build cache
yay -Sc   # Clean old build files
```

**AUR risks:**
- Some packages are personal/experimental
- Quality varies (not vetted like official repos)
- Build failures if dependencies missing
- Security: review PKGBUILD before installing

**Safe AUR practices:**
```bash
# Review PKGBUILD before installing
yay -Si PACKAGE_NAME  # See info first
yay -P PACKAGE_NAME   # Show PKGBUILD

# Install with confirmation
yay -S PACKAGE_NAME
# Review what it will do
# Type 'y' to confirm

# After installation
sudo pacman -Qi PACKAGE_NAME  # Verify installed
```

## Red Flags 🚩

Stop before executing if:
- [ ] Package has many unmet dependencies
- [ ] Package conflicts with multiple installed packages
- [ ] Package is marked "unsupported" or "outdated" in AUR
- [ ] Disk space critical before large update
- [ ] Internet connection unstable (update might corrupt)
- [ ] Over SSH and might lose connection (dangerous!)
- [ ] Don't understand what package does

## Safety Checklist ✅

**BEFORE installing:**
- [ ] Searched and found the package
- [ ] Know what it does
- [ ] Checked for conflicts
- [ ] Disk space available
- [ ] Stable internet connection

**BEFORE removing:**
- [ ] Understand the impact
- [ ] Other packages don't depend on it
- [ ] It's not critical system package
- [ ] I won't need it soon
- [ ] Backup any configs I need

**BEFORE updating system:**
- [ ] Read update notes if major version
- [ ] Disk space available
- [ ] Time to handle potential issues
- [ ] Not in middle of critical work
- [ ] Have stable power/internet

## Success Criteria ✅

After package management:
- [ ] Package installed/removed/updated successfully
- [ ] System is stable
- [ ] No new error messages
- [ ] Related packages still work
- [ ] New packages synced to chezmoi (if needed)
- [ ] Changes committed and pushed (if applicable)
- [ ] Can reproduce on other machine (if universal)

## Quick Reference

```bash
# Search
pacman -Ss TERM           # Official repos
yay -Ss TERM              # AUR

# Install
sudo pacman -S PACKAGE    # Official
yay -S PACKAGE            # AUR

# Update
sudo pacman -Syu          # Full update

# Remove
sudo pacman -R PACKAGE    # Keep config
sudo pacman -Rs PACKAGE   # Remove deps
sudo pacman -Rns PACKAGE  # Full removal

# Clean
paccache -r               # Remove old
paccache -du              # Show usage

# Sync to chezmoi
~/.local/share/chezmoi/packages-update.sh
```
