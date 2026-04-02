#!/bin/bash
# Test version of run_once_setup.sh (without sudo)
# IDEMPOTENT: Safe to run multiple times

set -e

echo "🔧 Running one-time setup tasks (TEST MODE - no sudo)..."
HOSTNAME=$(hostname)
echo "  Hostname: $HOSTNAME"

# Get absolute path to script directory (works even if run with relative paths)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# ============================================================================
# Ensure yay is installed (IDEMPOTENT)
# ============================================================================

echo ""
echo "🛠️  Checking AUR helper (yay)..."
if command -v yay &> /dev/null; then
    echo "  ✓ yay already installed"
else
    echo "  ⚠️  yay not installed"
fi

# ============================================================================
# Install packages from packages.txt (IDEMPOTENT)
# ============================================================================

echo ""
echo "📥 Installing packages for $HOSTNAME..."

PACKAGES_FILE="$SCRIPT_DIR/packages.txt"
if [ ! -f "$PACKAGES_FILE" ]; then
    echo "❌ packages.txt not found at: $PACKAGES_FILE"
    exit 1
else
    echo "  ✓ Found packages.txt"
    # Parse packages.txt and filter by hostname
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

    PKG_COUNT=$(echo "$PACKAGES_TO_INSTALL" | grep -c . || echo 0)
    echo "  Would install $PKG_COUNT packages:"
    echo "$PACKAGES_TO_INSTALL" | sed 's/^/    • /'
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
    echo "  ✓ Would create argv.json"
else
    if grep -q '"password-store".*gnome-libsecret' "$ARGV_JSON"; then
        echo "  ✓ gnome-libsecret already configured"
    else
        echo "  ⚠️  needs configuration"
    fi
fi

# ============================================================================
# Complete
# ============================================================================

echo ""
echo "✅ Test complete!"
