---
name: managing-linux-config-with-chezmoi
description: Safely manage Linux configuration changes across SamPC (desktop) and sam-x1 (laptop) using chezmoi, with automatic machine-specific templating and git synchronization.

---

# Managing Linux Config with Chezmoi Skill

Use this skill whenever you're asked to modify, add, or customize any Linux configuration file (hyprland, kitty, waybar, fish, etc.).

## Workflow Checklist

### 1. Identify the Configuration Target
- [ ] Which application/tool needs config changes? (e.g., hyprland, kitty, fish, waybar)
- [ ] Is this a new config or modifying existing one?
- [ ] Ask user if unclear: "Should this apply to both machines or just [current-machine]?"

### 2. Determine Machine Scope
**CRITICAL:** Ask yourself for EVERY config:
- "Will this config differ between SamPC (desktop, 3 monitors) and sam-x1 (laptop, 1 monitor)?"

#### If UNIVERSAL (same on both machines):
- [ ] Use regular file (no `.tmpl`)
- [ ] Store in `~/.local/share/chezmoi/dot_config/app/config`
- [ ] Commit with: `git commit -m "feat: update app config (machine: universal)"`

#### If MACHINE-SPECIFIC (different on each):
- [ ] Use `.tmpl` file extension
- [ ] Store in `~/.local/share/chezmoi/dot_config/app/config.tmpl`
- [ ] Add hostname conditionals (see template pattern below)
- [ ] Commit with: `git commit -m "feat: customize app config for SamPC/sam-x1 (machine: both)"`

#### If CURRENT-MACHINE-ONLY (only for SamPC or only for sam-x1):
- [ ] Use `.tmpl` file if not already templated
- [ ] Add hostname conditionals
- [ ] Commit with: `git commit -m "feat: add SamPC-specific config (machine: SamPC)"`

### 3. Template Pattern (Machine-Specific Configs)

**Standard Pattern:**
```bash
{{- if eq .chezmoi.hostname "sam-x1" }}
# Laptop-specific config
config_option_laptop_value
{{- else if eq .chezmoi.hostname "SamPC" }}
# Desktop-specific config
config_option_desktop_value
{{- end }}
```

**Multiple conditional sections:**
```bash
# Common config (applies to both)
universal_option=value

{{- if eq .chezmoi.hostname "SamPC" }}
# Desktop only
desktop_specific=true
{{- else if eq .chezmoi.hostname "sam-x1" }}
# Laptop only
laptop_specific=true
{{- end }}
```

### 4. Implementation Steps

**For NEW config file:**
1. [ ] Check current file in `~/.config/app/`
2. [ ] Copy to `~/.local/share/chezmoi/dot_config/app/`
3. [ ] If machine-specific, rename to `.tmpl` extension
4. [ ] Add/modify hostname conditionals
5. [ ] Test with: `chezmoi diff`
6. [ ] Apply with: `chezmoi apply`
7. [ ] Verify changes applied correctly
8. [ ] Commit to git with proper message

**For EXISTING config file:**
1. [ ] Locate file in `~/.local/share/chezmoi/dot_config/app/`
2. [ ] If adding machine-specific logic, convert to `.tmpl` if needed
3. [ ] Edit the file directly in chezmoi source
4. [ ] Test with: `chezmoi diff`
5. [ ] Apply with: `chezmoi apply`
6. [ ] Verify in `~/.config/app/` on both machines (if possible)
7. [ ] Commit to git with proper message

### 5. Testing Before Commit

```bash
# Always preview first
cd ~/.local/share/chezmoi
chezmoi diff

# Apply changes safely (chezmoi backs up originals)
chezmoi apply

# Verify the change took effect
cat ~/.config/app/config

# Check git status
git status

# Review what will be committed
git diff --cached
```

### 6. Git Commit and Push

**Commit format:**
```bash
cd ~/.local/share/chezmoi
git add dot_config/app/
git commit -m "<type>: <description> (machine: <scope>)"
git push
```

**Commit types:**
- `feat:` - New config or major feature
- `fix:` - Bug fix or correction
- `chore:` - Update, maintenance
- `refactor:` - Restructure without functional change

**Scope values:**
- `universal` - Both machines, identical config
- `both` - Both machines, different per-machine configs (templated)
- `SamPC` - Desktop only
- `sam-x1` - Laptop only

**Examples:**
```bash
git commit -m "feat: add custom keybindings (machine: universal)"
git commit -m "feat: monitor config for 3-monitor setup (machine: SamPC)"
git commit -m "fix: laptop monitor auto-detect on boot (machine: sam-x1)"
git commit -m "chore: update kitty theme colors (machine: universal)"
```

### 7. Package Management (If Applicable)

If your config change requires a new package:
```bash
# Sync packages to packages.txt
~/.local/share/chezmoi/packages-update.sh

# Follow prompts:
# - Mark as "universal" (all machines) or machine-specific
# - Review git diff
# - Commit changes

cd ~/.local/share/chezmoi
git add packages.txt
git commit -m "chore: add package-name (machine: <scope>)"
git push
```

## Common Scenarios

### Scenario 1: Customize Hyprland Monitor Config (SamPC)
- SamPC has 3 monitors, sam-x1 has 1
- Solution: Edit `hyprland.conf.tmpl` (already templated)
- Add SamPC-specific monitor settings in `{{- if eq .chezmoi.hostname "SamPC" }}` block
- Commit with: `git commit -m "feat: optimize monitor layout for 3-display setup (machine: SamPC)"`

### Scenario 2: Add a Universal Kitty Theme Update
- Same theme on both machines
- Solution: Edit `dot_config/kitty/kitty.conf` (no `.tmpl` needed)
- Make changes
- Commit with: `git commit -m "chore: update kitty color scheme (machine: universal)"`

### Scenario 3: Customize Fish Shell Aliases for SamPC Only
- Laptop doesn't need these aliases
- Solution: Convert `dot_config/fish/config.fish` to `config.fish.tmpl`
- Add universal aliases outside conditionals
- Add SamPC-specific aliases in `{{- if eq .chezmoi.hostname "SamPC" }}` block
- Commit with: `git commit -m "feat: add SamPC development aliases (machine: SamPC)"`

### Scenario 4: Update Waybar Config for Both Machines Differently
- Desktop needs 3-monitor layout, laptop needs single-monitor layout
- Solution: Edit `dot_config/waybar/config.tmpl` (or convert to .tmpl)
- Add conditionals for desktop vs laptop layout
- Commit with: `git commit -m "feat: machine-specific waybar layouts (machine: both)"`

## Red Flags 🚩

Stop and ask user if:
- [ ] Not clear which machines should use this config
- [ ] The change might break the laptop setup
- [ ] The file isn't in `dot_config/` yet
- [ ] User hasn't confirmed if it's machine-specific or universal
- [ ] The change requires new packages (ask before running packages-update.sh)
- [ ] The config file has complex template logic that might conflict

## Success Criteria ✅

After completing this workflow, verify:
- [ ] `chezmoi diff` shows expected changes
- [ ] `chezmoi apply` completes without errors
- [ ] Config changes are visible in `~/.config/app/`
- [ ] If machine-specific, conditionals are correct
- [ ] Git commit message is descriptive and includes machine scope
- [ ] Changes pushed to origin
- [ ] Other machine can pull and apply without conflicts
