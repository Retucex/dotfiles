#!/bin/fish

# Match the Moonlight client's requested mode (fallback if unset)
set -q SUNSHINE_CLIENT_WIDTH; or set SUNSHINE_CLIENT_WIDTH 1920
set -q SUNSHINE_CLIENT_HEIGHT; or set SUNSHINE_CLIENT_HEIGHT 1200
set -q SUNSHINE_CLIENT_FPS; or set SUNSHINE_CLIENT_FPS 60

# Reuse the output if it survived a previous session (monitors left off)
if not hyprctl monitors all -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null
    hyprctl output create headless HEADLESS-1
end
hyprctl eval "hl.monitor({ output = \"HEADLESS-1\", mode = \"{$SUNSHINE_CLIENT_WIDTH}x{$SUNSHINE_CLIENT_HEIGHT}@{$SUNSHINE_CLIENT_FPS}\", position = \"auto\", scale = 1 })"

if not hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null
    exit 1
end

hyprctl dispatch 'hl.dsp.focus({ monitor = "HEADLESS-1" })'
