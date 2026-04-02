#!/bin/bash
# One-time setup script for chezmoi on first init
# Executed automatically by chezmoi - do NOT manually edit
# IDEMPOTENT: Safe to run multiple times (auto-skips already-done steps)

set -e

echo "🔧 Running one-time setup tasks..."
HOSTNAME=$(hostname)

# Get absolute path to script directory (handles chezmoi symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="."
fi

# ============================================================================
# System Update (IDEMPOTENT)
# ============================================================================

echo ""
echo "📦 System update..."
if sudo pacman -Syu --noconfirm 2>&1 | grep -q "there is nothing to do"; then
    echo "  ✓ System already up to date"
else
    echo "  ✓ System updated"
fi

# ============================================================================
# Ensure yay is installed (IDEMPOTENT)
# ============================================================================

echo ""
echo "🛠️  Checking AUR helper (yay)..."
if command -v yay &> /dev/null; then
    echo "  ✓ yay already installed"
else
    echo "  Installing yay..."
    if sudo pacman -S --noconfirm yay; then
        echo "  ✓ yay installed"
    else
        echo "  ❌ Failed to install yay. Aborting."
        exit 1
    fi
fi

# ============================================================================
# Install packages from packages.txt (IDEMPOTENT)
# ============================================================================

echo ""
echo "📥 Installing packages for $HOSTNAME..."

PACKAGES_FILE="$SCRIPT_DIR/packages.txt"

# If packages.txt not in script dir, try common chezmoi locations
if [ ! -f "$PACKAGES_FILE" ]; then
    for potential_dir in ~/.local/share/chezmoi ~/.chezmoi /tmp/.chezmoi* ~/.config/chezmoi; do
        if [ -f "$potential_dir/packages.txt" ]; then
            PACKAGES_FILE="$potential_dir/packages.txt"
            break
        fi
    done
fi

if [ ! -f "$PACKAGES_FILE" ]; then
    echo "⚠️  packages.txt not found (tried: $SCRIPT_DIR and common locations)"
else
    # Parse packages.txt and filter by hostname
    # Include: lines without @, and lines with @HOSTNAME
    PACKAGES_TO_INSTALL=$(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | while read -r line; do
        if [[ $line =~ ^@([^ ]+)[[:space:]](.+)$ ]]; then
            # Machine-specific package
            if [ "${BASH_REMATCH[1]}" = "$HOSTNAME" ]; then
                echo "${BASH_REMATCH[2]}"
            fi
        else
            # Universal package
            echo "$line"
        fi
    done | sort -u)

    if [ -z "$PACKAGES_TO_INSTALL" ]; then
        echo "  ℹ️  No packages to install"
    else
        # IDEMPOTENT: yay automatically skips already-installed packages
        echo "  Installing/verifying packages:"
        echo "$PACKAGES_TO_INSTALL" | sed 's/^/    • /'
        echo ""
        
        # Install packages, continue even if some fail
        if yay -S --noconfirm $PACKAGES_TO_INSTALL 2>&1 | tee /tmp/yay-install.log; then
            echo "  ✓ All packages installed/verified"
        else
            # Check if failure was just "already installed" (exit code 0 in some cases)
            if grep -q "there is nothing to do" /tmp/yay-install.log || [ $? -eq 0 ]; then
                echo "  ✓ All packages already installed or up to date"
            else
                echo "  ⚠️  Some packages had issues. Continuing with setup..."
            fi
        fi
        rm -f /tmp/yay-install.log
    fi
fi

# ============================================================================
# VS Code: Ensure gnome-libsecret password storage (IDEMPOTENT)
# ============================================================================

echo ""
echo "⚙️  Configuring VS Code..."

VSCODE_DIR="${HOME}/.vscode"
ARGV_JSON="${VSCODE_DIR}/argv.json"

if [ ! -d "$VSCODE_DIR" ]; then
    mkdir -p "$VSCODE_DIR"
fi

if [ ! -f "$ARGV_JSON" ]; then
    echo "  Creating argv.json with gnome-libsecret..."
    cat > "$ARGV_JSON" << 'VSCODE'
{
"password-store": "gnome-libsecret"
}
VSCODE
    echo "  ✓ Created"
else
    # IDEMPOTENT: Check existing file
    if grep -q '"password-store".*gnome-libsecret' "$ARGV_JSON"; then
        echo "  ✓ gnome-libsecret already configured"
    elif grep -q '"password-store"' "$ARGV_JSON"; then
        echo "  ⚠️  password-store configured but not gnome-libsecret"
        echo "    Attempting to fix..."
        
        if command -v jq &> /dev/null; then
            cp "$ARGV_JSON" "$ARGV_JSON.backup"
            jq '.["password-store"] = "gnome-libsecret"' "$ARGV_JSON.backup" > "$ARGV_JSON"
            rm "$ARGV_JSON.backup"
            echo "  ✓ Fixed with jq"
        else
            # Fallback: use sed to replace the value
            sed -i 's/"password-store"[[:space:]]*:[[:space:]]*"[^"]*"/"password-store": "gnome-libsecret"/' "$ARGV_JSON"
            echo "  ✓ Fixed with sed"
        fi
    else
        echo "  ⚠️  argv.json exists but password-store not found"
        echo "    Attempting to inject gnome-libsecret..."
        
        if command -v jq &> /dev/null; then
            cp "$ARGV_JSON" "$ARGV_JSON.backup"
            jq '. + {"password-store": "gnome-libsecret"}' "$ARGV_JSON.backup" > "$ARGV_JSON"
            rm "$ARGV_JSON.backup"
            echo "  ✓ Injected with jq"
        else
            # Fallback: append before closing brace
            sed -i '/{[[:space:]]*$/a\\t"password-store": "gnome-libsecret",' "$ARGV_JSON" 2>/dev/null || {
                echo "  ❌ Could not inject. Manual fix needed: ~/.vscode/argv.json"
            }
        fi
    fi
fi

# ============================================================================
# Complete
# ============================================================================

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Reboot to apply system changes (optional)"
echo "  2. Test all applications"
echo "  3. Run 'packages-update.sh' periodically to sync new packages"
echo ""
echo "This script is idempotent and safe to run multiple times."
