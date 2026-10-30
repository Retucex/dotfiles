#!/bin/fish

# Any screen off -> restore everything from hyprland.lua (and drop a leftover Sunshine display)
if hyprctl monitors all -j | jq -e 'any(.[]; .disabled)' >/dev/null
    hyprctl reload
    if hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null
        sleep 1
        hyprctl output remove HEADLESS-1
    end
    exit
end

# All on -> turn off every physical screen
for m in (hyprctl monitors -j | jq -r '.[] | select(.name != "HEADLESS-1") | .name')
    hyprctl eval "hl.monitor({ output = \"$m\", disabled = true })"
end
