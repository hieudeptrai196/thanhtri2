#!/bin/sh
# Starts a host and a client as two headless processes and checks they end up in one run.
GODOT="${GODOT:-/Users/mac/Downloads/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.." || exit 1
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . -s res://tools/net_smoke.gd -- host 2>&1 | grep -E 'OK|FAIL|ERROR' &
HOST=$!
"$GODOT" --headless --path . -s res://tools/net_smoke.gd -- client 2>&1 | grep -E 'OK|FAIL|ERROR'
wait $HOST
