#!/bin/fish

# Never leave Hyprland without any output
if not hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null
    exit 1
end

for m in (hyprctl monitors -j | jq -r '.[] | select(.name != "HEADLESS-1") | .name')
    hyprctl eval "hl.monitor({ output = \"$m\", disabled = true })"
end

hyprctl dispatch 'hl.dsp.focus({ monitor = "HEADLESS-1" })'
