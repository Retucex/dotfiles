# Dotfiles - Sam's Linux Configuration

Multi-machine dotfiles management using [chezmoi](https://www.chezmoi.io/).

## Machines

- **SamPC** (Desktop): Hyprland + 3 monitors
- **sam-x1** (Laptop): Hyprland + 1 monitor (auto-detect)

## Quick Start

### New Machine Setup

```bash
chezmoi init --apply https://github.com/Retucex/dotfiles.git
```

This will:
1. Clone the dotfiles repo
2. Auto-detect your hostname
3. Apply machine-specific configs (monitors, etc.)
4. Run `run_once_setup.sh` to handle one-time setup tasks

### Manual Updates

```bash
chezmoi update    # Pull latest changes
chezmoi diff      # See what would change
chezmoi apply     # Apply changes to your system
```

## Machine-Specific Configuration

Configs are automatically detected by hostname using `.chezmoidata.yaml`:

```yaml
# Monitor config per machine
SamPC → 3 monitors (DP-1, DP-2, HDMI-A-1)
sam-x1 → 1 monitor (auto-detect)
```

To add a new machine:
1. Edit `.chezmoidata.yaml` with new hostname
2. Update `*.tmpl` files with conditional logic: `{{ if eq .chezmoi.hostname "hostname" }}`
3. Commit and push

## One-Time Setup Tasks

The `run_once_setup.sh` script executes automatically on first init and handles:

- **VS Code argv.json**: Ensures gnome-libsecret is configured for password storage
- **Future setup needs**: Add more tasks as needed

**Note:** This script only runs once. To re-run manually:

```bash
chezmoi execute-template < ~/.local/share/chezmoi/run_once_setup.sh | bash
```

## Sensitive Files

The following files are **NOT** tracked in chezmoi (user/machine specific):

- `~/.config/rclone/rclone.conf` - Contains auth tokens (auto-generated after first rclone mount)
- `~/.config/Code/languagepacks.json` - VS Code language packs (auto-generated)

These are excluded and should be set up manually or via their respective application's auth flow.

## Applications Configured

- **WM**: Hyprland (with machine-specific monitor configs)
- **Terminal**: Kitty
- **Shell**: Fish
- **Status Bar**: Waybar
- **File Manager**: Yazi
- **System Monitor**: btop
- **Editor**: VS Code (with gnome-keyring integration)
- **Lock Screen**: Hyprlock
- **Theme**: Rose Pine Moon (across all apps)

## Troubleshooting

### "Monitor config is wrong"
Verify chezmoi detected your hostname correctly:
```bash
chezmoi data | grep hostname
```

If wrong, update `.chezmoidata.yaml` with your actual hostname.

### "VS Code password prompt every time"
Ensure `~/.vscode/argv.json` contains:
```json
{
  "password-store": "gnome-libsecret"
}
```

Run the setup script to fix:
```bash
bash ~/.local/share/chezmoi/run_once_setup.sh
```

## Adding New Configs

1. Copy config to `~/.local/share/chezmoi/dot_config/<app>/config`
2. If machine-specific, rename to `*.tmpl` and add conditions
3. Add data to `.chezmoidata.yaml` if needed
4. `cd ~/.local/share/chezmoi && git add . && git commit`
5. `git push`

## Updates

Pull latest changes across all machines:

```bash
chezmoi update && chezmoi apply
```
