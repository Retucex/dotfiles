#!/usr/bin/env bash
# Waybar module: show Unified Remote icon while the server runs (empty output hides the module)
if pgrep -x urserver >/dev/null; then
    printf '{"text": "\U000f0454", "tooltip": "Unified Remote running\\nLeft click: stop\\nRight click: open manager", "class": "running"}\n'
else
    echo '{"text": ""}'
fi
