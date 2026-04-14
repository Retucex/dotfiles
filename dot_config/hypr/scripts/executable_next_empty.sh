#!/bin/bash

# 1. Find the highest existing workspace ID across all monitors
max_ws=$(hyprctl workspaces -j | jq 'map(.id) | max')

# 2. Add 1 to create a fresh empty workspace ID
next_ws=$((max_ws + 1))

# 3. Switch to it on the current monitor
hyprctl dispatch workspace $next_ws
