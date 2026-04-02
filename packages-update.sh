#!/bin/bash
# Package sync script - Run manually to capture new packages
# Compares installed packages against packages.txt and shows new ones

set -e

PACKAGES_FILE="${0%/*}/packages.txt"
HOSTNAME=$(hostname)

if [ ! -f "$PACKAGES_FILE" ]; then
    echo "❌ packages.txt not found: $PACKAGES_FILE"
    exit 1
fi

echo "🔍 Scanning installed packages on $HOSTNAME..."
echo ""

# Get list of explicitly installed packages (not dependencies)
INSTALLED=$(pacman -Qe | awk '{print $1}')

# Extract package names from packages.txt (strip comments and @hostname prefixes)
TRACKED=$(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | sed 's/@[^ ]* //' | sort -u)

# Find new packages (installed but not in packages.txt)
NEW_PACKAGES=()
while read -r pkg; do
    if ! echo "$TRACKED" | grep -q "^$pkg$"; then
        NEW_PACKAGES+=("$pkg")
    fi
done <<< "$INSTALLED"

if [ ${#NEW_PACKAGES[@]} -eq 0 ]; then
    echo "✅ No new packages found. packages.txt is up to date!"
    exit 0
fi

echo "📦 Found ${#NEW_PACKAGES[@]} new package(s):"
echo ""
for pkg in "${NEW_PACKAGES[@]}"; do
    echo "   • $pkg"
done
echo ""

read -p "Add these to packages.txt? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "For each package, specify scope:"
echo "  [u]niversal - installs on all machines"
echo "  [m]achine-specific - installs only on $HOSTNAME"
echo "  [s]kip - don't add to packages.txt"
echo ""

for pkg in "${NEW_PACKAGES[@]}"; do
    while true; do
        read -p "  $pkg: (u/m/s)? " -n 1 choice
        echo
        case $choice in
            [Uu])
                echo "$pkg" >> "$PACKAGES_FILE"
                echo "  ✓ Added as universal"
                break
                ;;
            [Mm])
                echo "@$HOSTNAME $pkg" >> "$PACKAGES_FILE"
                echo "  ✓ Added as machine-specific"
                break
                ;;
            [Ss])
                echo "  ⊘ Skipped"
                break
                ;;
            *)
                echo "  Invalid choice"
                ;;
        esac
    done
done

echo ""
echo "✅ Updated packages.txt"
echo ""
echo "Changes:"
git -C "${0%/*}" diff packages.txt
echo ""
echo "Next: Commit and push these changes"
echo "  cd ~/.local/share/chezmoi"
echo "  git add packages.txt && git commit -m 'chore: update packages list'"
echo "  git push"
