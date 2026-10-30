#!/bin/fish

# Keep the headless output while physical screens are off, otherwise there'd be no display
if hyprctl monitors -j | jq -e '.[] | select(.name != "HEADLESS-1")' >/dev/null
    hyprctl output remove HEADLESS-1 2>/dev/null
end
exit 0
