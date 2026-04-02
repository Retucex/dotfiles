#!/bin/bash
# One-time setup script for chezmoi on first init
# Executed automatically by chezmoi - do NOT manually edit

set -e

echo "🔧 Running one-time setup tasks..."
HOSTNAME=$(hostname)

# ============================================================================
# System Update
# ============================================================================

echo ""
echo "📦 System update..."
sudo pacman -Syu --noconfirm

# ============================================================================
# Ensure yay is installed (AUR helper)
# ============================================================================

echo ""
echo "🛠️  Checking AUR helper (yay)..."
if ! command -v yay &> /dev/null; then
    echo "  Installing yay..."
    sudo pacman -S --noconfirm yay
else
    echo "  ✓ yay already installed"
fi

# ============================================================================
# Install packages from packages.txt
# ============================================================================

echo ""
echo "📥 Installing packages for $HOSTNAME..."

PACKAGES_FILE="${0%/*}/packages.txt"
if [ ! -f "$PACKAGES_FILE" ]; then
    echo "⚠️  packages.txt not found, skipping package installation"
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
        echo "  Installing:"
        echo "$PACKAGES_TO_INSTALL" | sed 's/^/    • /'
        echo ""
        yay -S --noconfirm $PACKAGES_TO_INSTALL || {
            echo "⚠️  Some packages failed to install. Continuing..."
        }
    fi
fi

# ============================================================================
# VS Code: Ensure gnome-libsecret password storage
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
else
    # File exists - check if gnome-libsecret is configured
    if grep -q '"password-store"' "$ARGV_JSON"; then
        if grep -q 'gnome-libsecret' "$ARGV_JSON"; then
            echo "  ✓ gnome-libsecret already configured"
        else
            echo "  ⚠️  password-store configured but not gnome-libsecret"
            echo "    Manual fix needed: ~/.vscode/argv.json"
        fi
    else
        echo "  ⚠️  argv.json exists but password-store not configured"
        echo "  Attempting to inject gnome-libsecret..."
        if command -v jq &> /dev/null; then
            cp "$ARGV_JSON" "$ARGV_JSON.backup"
            jq '. + {"password-store": "gnome-libsecret"}' "$ARGV_JSON.backup" > "$ARGV_JSON"
            rm "$ARGV_JSON.backup"
            echo "  ✓ gnome-libsecret injected"
        else
            echo "  ⚠️  jq not found, cannot auto-merge. Manual fix needed."
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
echo "  1. Reboot to apply system changes"
echo "  2. Test all applications"
echo "  3. Run 'packages-update.sh' periodically to sync new packages"
