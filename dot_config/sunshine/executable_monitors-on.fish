#!/bin/fish

# Restore physical screens from the Hyprland config
hyprctl reload
sleep 1

# Reload resets HEADLESS-1's mode; re-apply it if a stream is using it
if hyprctl monitors all -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null
    (status dirname)/headless-up.fish
end
exit 0
