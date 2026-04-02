#!/bin/bash
# One-time setup script for chezmoi on first init
# Executed automatically by chezmoi - do NOT manually edit

set -e

echo "🔧 Running one-time setup tasks..."

# ============================================================================
# VS Code: Ensure gnome-libsecret password storage
# ============================================================================

VSCODE_DIR="${HOME}/.vscode"
ARGV_JSON="${VSCODE_DIR}/argv.json"

if [ ! -d "$VSCODE_DIR" ]; then
    mkdir -p "$VSCODE_DIR"
fi

if [ ! -f "$ARGV_JSON" ]; then
    echo "📝 Creating VS Code argv.json with gnome-libsecret..."
    cat > "$ARGV_JSON" << 'VSCODE'
{
"password-store": "gnome-libsecret"
}
VSCODE
else
    # File exists - check if gnome-libsecret is configured
    if grep -q '"password-store"' "$ARGV_JSON"; then
        if grep -q 'gnome-libsecret' "$ARGV_JSON"; then
            echo "✓ VS Code gnome-libsecret already configured"
        else
            echo "⚠ VS Code has password-store configured but not gnome-libsecret"
            echo "  Manual fix: Edit ~/.vscode/argv.json and ensure:"
            echo '    "password-store": "gnome-libsecret"'
        fi
    else
        echo "⚠ VS Code argv.json exists but password-store not configured"
        echo "  Injecting gnome-libsecret setting..."
        # Backup and add the setting
        cp "$ARGV_JSON" "$ARGV_JSON.backup"
        jq '. + {"password-store": "gnome-libsecret"}' "$ARGV_JSON.backup" > "$ARGV_JSON"
        rm "$ARGV_JSON.backup"
        echo "✓ VS Code gnome-libsecret injected"
    fi
fi

# ============================================================================
# Additional setup tasks can be added here
# ============================================================================

echo "✅ Setup complete!"
