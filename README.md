# Dotfiles - Sam's Linux Configuration

Multi-machine dotfiles management using [chezmoi](https://www.chezmoi.io/) with intelligent hostname-based configuration and automated package management.

## Features

✨ **Multi-Machine Support** - Auto-detect hostname and apply machine-specific configs  
📦 **Smart Package Management** - Track, sync, and install packages across machines  
⚡ **One-Time Setup** - Automatic initialization script on first run  
🔄 **Idempotent Scripts** - Safe to run multiple times  
🎯 **Minimal Overhead** - Only essential configs tracked, auto-generated files excluded  

## Machines

- **SamPC** (Desktop): Hyprland + 3 monitors (DP-1, DP-2, HDMI-A-1)
- **sam-x1** (Laptop): Hyprland + 1 monitor (auto-detect)

## Quick Start

### New Machine Setup

```bash
chezmoi init --apply https://github.com/Retucex/dotfiles.git
```

This will:
1. Clone the dotfiles repo
2. Auto-detect your hostname
3. Apply machine-specific configs (monitors, packages, etc.)
4. Run one-time setup tasks (system update, package install, VS Code config)
5. You're done! ✓

### Manual Updates

```bash
chezmoi update    # Pull latest changes
chezmoi diff      # See what would change
chezmoi apply     # Apply changes to your system
```

## How It Works

### Hostname-Based Configuration

Configs are automatically selected based on your machine's hostname using `.chezmoidata.yaml`:

**Example: Monitor Config (hyprland.conf.tmpl)**
```bash
{{- if eq .chezmoi.hostname "sam-x1" }}
monitor=,preferred,auto,1.07          # Laptop: auto-detect
{{- else if eq .chezmoi.hostname "SamPC" }}
monitor=DP-1,preferred,1080x0,1.0     # Desktop: 3 monitors
monitor=DP-2,preferred,0x0,1,transform,3
monitor=HDMI-A-1,preferred,4920x0,1,transform,1
{{- end }}
```

### Package Management

#### `packages.txt` - Single Source of Truth

```
# Universal packages (all machines)
kitty
fish
hyprland

# Desktop only
@SamPC opendeck

# Laptop only
@sam-x1 tlp
@sam-x1 tlp-rdw
```

**Format:**
- `package_name` — Installs on all machines
- `@hostname package_name` — Machine-specific (only that machine)
- Lines starting with `#` are comments

#### `packages-update.sh` - Track New Packages

Run manually when you install new packages:

```bash
~/.local/share/chezmoi/packages-update.sh
```

This:
1. Scans your system for newly installed packages
2. Compares against packages.txt
3. Asks if each new package is universal or machine-specific
4. Auto-updates packages.txt
5. Shows git diff for review

**Idempotent:** Safe to run multiple times. Skips packages already in the file.

#### `run_once_setup.sh` - Automatic Initialization

Runs automatically on first init (via chezmoi). Does:

1. **System Update** - `pacman -Syu`
2. **Install yay** - If not present (AUR helper)
3. **Install Packages** - From packages.txt, respecting hostname filters
4. **VS Code Setup** - Ensures gnome-libsecret password storage
5. **Error Resilience** - Continues even if some packages fail

**Idempotent:** Safe to re-run anytime. Skips already-done steps.

To re-run manually:
```bash
bash ~/.local/share/chezmoi/run_once_setup.sh
```

## Machine-Specific Configuration

### Adding a New Machine

1. Edit `.chezmoidata.yaml` with new hostname
2. Update `*.tmpl` files with conditional logic:
   ```bash
   {{ if eq .chezmoi.hostname "new-hostname" }}
   # config for new machine
   {{ else }}
   # config for other machines
   {{ end }}
   ```
3. Update `packages.txt` with `@new-hostname` entries
4. Commit and push
5. On new machine: `chezmoi init --apply`

### Current Templates

- **hyprland.conf.tmpl** - Monitor configuration per machine

## One-Time Setup Tasks

### VS Code gnome-libsecret

The setup script ensures VS Code uses gnome-libsecret for password storage:

```json
{
  "password-store": "gnome-libsecret"
}
```

This is auto-configured via `run_once_setup.sh` and prevents repeated password prompts.

**Manual fix if needed:**
```bash
bash ~/.local/share/chezmoi/run_once_setup.sh
```

## Sensitive Files (NOT Tracked)

The following files are excluded and should be set up via their respective applications:

- `~/.config/rclone/rclone.conf` - Contains auth tokens
- `~/.config/Code/languagepacks.json` - VS Code auto-generated
- `~/.vscode/argv.json` - VS Code user settings (auto-generated, we only inject gnome-libsecret)

## Applications Configured

**WM & Desktop:**
- Hyprland (window manager, machine-specific monitors)
- Hyprlock (lock screen)
- Waybar (status bar)
- Dunst (notifications)
- Swaybg (background)

**Terminal & Shell:**
- Kitty (terminal)
- Fish (shell)
- Starship (prompt)

**File Manager & Tools:**
- Yazi (file manager)
- btop (system monitor)
- Ripgrep, fd, fzf, bat, exa (CLI tools)

**Development:**
- Neovim (editor)
- VS Code (with gnome-libsecret)
- Git & git-delta (version control)

**Theme:**
- Rose Pine Moon (consistent across all apps)

## Workflow Examples

### 1. New Desktop Setup

```bash
# On new machine
chezmoi init --apply https://github.com/Retucex/dotfiles.git

# Wait for automatic setup
# System updates, packages install, configs applied ✓
```

### 2. Install a New Package

```bash
# Install on your machine
yay -S some-package

# Sync to dotfiles repo
~/.local/share/chezmoi/packages-update.sh

# Follow prompts to mark as universal or machine-specific
# Commit and push
cd ~/.local/share/chezmoi
git add packages.txt
git commit -m "chore: add some-package (universal/machine-specific)"
git push
```

### 3. Pull Updates on Another Machine

```bash
# On another machine
chezmoi update && chezmoi apply

# Gets all updates including new packages
```

## Troubleshooting

### Monitor Config Wrong

Check chezmoi detected your hostname correctly:
```bash
chezmoi data | grep hostname
```

If wrong, update `.chezmoidata.yaml` with your actual hostname and re-run:
```bash
chezmoi update && chezmoi apply
```

### VS Code Password Prompt Every Time

Ensure gnome-libsecret is configured:
```bash
grep password-store ~/.vscode/argv.json
# Should show: "password-store": "gnome-libsecret"
```

Re-run setup to fix:
```bash
bash ~/.local/share/chezmoi/run_once_setup.sh
```

### Packages Not Installing

Check if packages are available:
```bash
yay -S package_name
```

If missing, it may not exist in Arch/AUR. Update packages.txt to remove it.

## Adding New Configs

1. Copy config to chezmoi source:
   ```bash
   cp ~/.config/app/config ~/.local/share/chezmoi/dot_config/app/config
   ```

2. If machine-specific, rename to `.tmpl` and add conditions:
   ```bash
   mv ~/.local/share/chezmoi/dot_config/app/config \
      ~/.local/share/chezmoi/dot_config/app/config.tmpl
   ```

3. Add hostname conditions to the template

4. Commit and push:
   ```bash
   cd ~/.local/share/chezmoi
   git add dot_config/app/
   git commit -m "feat: add app config with machine-specific support"
   git push
   ```

## Repository Structure

```
.
├── README.md                          # This file
├── .chezmoidata.yaml                  # Machine data (monitor configs)
├── packages.txt                       # Package list (universal + @hostname)
├── run_once_setup.sh                  # Auto-run on init
├── run_once_setup_test.sh             # Test version (no sudo)
├── packages-update.sh                 # Manual: sync new packages
└── dot_config/
    ├── background.png
    ├── btop/btop.conf
    ├── fish/config.fish
    ├── hypr/
    │   ├── hyprland.conf.tmpl         # Machine-specific monitors
    │   ├── hyprlock.conf
    ├── kitty/
    │   ├── kitty.conf
    │   └── current-theme.conf
    ├── waybar/
    │   ├── config
    │   └── style.css
    ├── yazi/
    │   ├── keymap.toml
    │   ├── theme.toml
    │   └── flavors/rose-pine-moon.yazi/
    └── [other app configs]
```

## Commands Reference

```bash
# Setup new machine
chezmoi init --apply https://github.com/Retucex/dotfiles.git

# Pull updates
chezmoi update

# See what would change
chezmoi diff

# Apply changes
chezmoi apply

# Track new packages
~/.local/share/chezmoi/packages-update.sh

# Re-run setup (safe - idempotent)
bash ~/.local/share/chezmoi/run_once_setup.sh

# Check detected hostname
chezmoi data | grep hostname

# View template rendering
chezmoi execute-template < ~/.local/share/chezmoi/dot_config/hypr/hyprland.conf.tmpl
```

## Tips

- **Idempotent scripts:** All scripts are safe to run multiple times
- **Regular syncs:** Run `packages-update.sh` periodically to capture new packages
- **Git workflow:** Always review changes with `chezmoi diff` before applying
- **Backups:** chezmoi backs up modified files before applying changes
- **Testing:** Use `run_once_setup_test.sh` to test without sudo/installation

## Contributing

To add a new feature to your dotfiles:

1. Make your change locally
2. Test it works on your machine
3. If machine-specific, add `.tmpl` and hostname conditions
4. Commit with descriptive message
5. Push to GitHub

Example:
```bash
# Add a new app config
cp ~/.config/newapp/config ~/.local/share/chezmoi/dot_config/newapp/

# If machine-specific
mv ~/.local/share/chezmoi/dot_config/newapp/config \
   ~/.local/share/chezmoi/dot_config/newapp/config.tmpl

# Commit
cd ~/.local/share/chezmoi
git add dot_config/newapp/
git commit -m "feat: add newapp config"
git push
```

## Resources

- [chezmoi Documentation](https://www.chezmoi.io/)
- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [Hyprland Wiki](https://wiki.hyprland.org/)

---

**Last Updated:** 2026-04-02  
**Repository:** https://github.com/Retucex/dotfiles
