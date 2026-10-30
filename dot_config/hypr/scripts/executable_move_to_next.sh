#!/bin/bash

# 1. Find the highest existing workspace ID across all monitors
max_ws=$(hyprctl workspaces -j | jq 'map(.id) | max')

# 2. Add 1 to create a fresh empty workspace ID
next_ws=$((max_ws + 1))

# 3. Move the active window to this new workspace
hyprctl dispatch movetoworkspace $next_ws
