# Copilot CLI Instructions

## Environment Overview

Managing a multi-machine Linux dotfiles setup using **chezmoi**:
- **SamPC** (Desktop): Hyprland WM, 3 monitors (DP-1, DP-2, HDMI-A-1)
- **sam-x1** (Laptop): Hyprland WM, 1 monitor (auto-detect)

Dotfiles repo: `~/.local/share/chezmoi/` (GitHub: Retucex/dotfiles)

**Current Machine:** `SamPC` (Desktop)

## Skills

The following personal skills are available for specialized tasks. Use them when relevant:

- **managing-linux-system** — Router skill; use first for any system management task
- **system-diagnostics** — Read-only health checks (services, disk, network, logs)
- **system-administration** — Service control, user management, permissions, settings
- **system-package-management** — Package install/update/remove with chezmoi sync
- **managing-linux-config-with-chezmoi** — Dotfile changes across machines with templates

## Critical Rules for Config Changes

### 1. Always Check Machine Scope
Before editing any config file:
- Ask: "Does this config differ between SamPC and sam-x1?"
- If YES → Use `.tmpl` file with hostname conditionals
- If NO → Use regular file (applies to both machines)

### 2. Workflow for Config Changes

1. Identify the file in `~/.local/share/chezmoi/dot_config/`
2. Determine scope (machine-specific → `.tmpl`; universal → regular file)
3. Edit in the chezmoi source, **never** in `~/.config` directly
4. Test: `chezmoi diff` then `chezmoi apply`
5. Sync packages if needed: `~/.local/share/chezmoi/packages-update.sh`
6. Commit with scoped message (see below)

### 3. Git Commit Message Format
`<type>: <description> (machine: <scope>)`

Scope values: `universal`, `both`, `SamPC`, `sam-x1`

```bash
git commit -m "feat: add custom keybinding to hyprland (machine: universal)"
git commit -m "feat: adjust monitor layout for 3-monitor setup (machine: SamPC)"
git commit -m "fix: auto-detect monitor on boot (machine: sam-x1)"
git commit -m "feat: customize waybar appearance (machine: both)"
```

### 4. Template Pattern
```
{{- if eq .chezmoi.hostname "SamPC" }}
# Desktop-specific config
{{- else if eq .chezmoi.hostname "sam-x1" }}
# Laptop-specific config
{{- end }}
```

### 5. Adding New Config Files
```bash
# Add to chezmoi source
cp ~/.config/app/config ~/.local/share/chezmoi/dot_config/app/config
# If machine-specific, rename to .tmpl and add conditionals
chezmoi diff && chezmoi apply
git add dot_config/app/ && git commit -m "feat: add app config (machine: <scope>)"
git push
```

### 6. `.chezmoidata.yaml`
Use for machine-specific data referenced in templates (e.g., monitor layouts).

## Agent Handoff Format

When delegating config tasks to sub-agents, provide this context:

```
Environment:
- Current machine: SamPC (Desktop: 3 monitors DP-1, DP-2, HDMI-A-1)
- Dotfiles repo: ~/.local/share/chezmoi/
- GitHub: Retucex/dotfiles

Constraints:
- Check if change is machine-specific; use .tmpl if so
- Test with `chezmoi diff` before committing
- Commit format: "<type>: description (machine: scope)"
- Never edit ~/.config directly

Report back: whether universal/machine-specific, files modified, git commit hash, chezmoi apply status.
```

## Key Paths

| Path | Purpose |
|------|---------|
| `~/.local/share/chezmoi/` | Dotfiles source / git repo |
| `~/.local/share/chezmoi/dot_config/` | Tracked configs |
| `~/.local/share/chezmoi/.chezmoi.toml.tmpl` | Chezmoi config template |
| `~/.local/share/chezmoi/.chezmoidata.yaml` | Per-machine data |

## Useful Commands

```bash
chezmoi diff                        # Preview changes
chezmoi apply                       # Apply to system
chezmoi data | grep -E "(hostname|os)"  # View machine info
chezmoi execute-template < file.tmpl    # Test template rendering
~/.local/share/chezmoi/packages-update.sh  # Sync packages
cd ~/.local/share/chezmoi && git status
```

## Safety Guidelines

- ✅ Always `chezmoi diff` before applying
- ✅ Use templates for machine-specific configs
- ✅ Commit frequently with scoped messages
- ✅ Push to sync with other machines
- ❌ Never edit `~/.config` directly
- ❌ Never push untested changes
