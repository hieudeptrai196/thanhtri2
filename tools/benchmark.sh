#!/bin/sh
# Frame-rate benchmark with growing enemy counts (opens a window). Usage: tools/benchmark.sh [WxH]
GODOT="${GODOT:-/Users/mac/Downloads/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.." || exit 1
"$GODOT" --headless --path . --import >/dev/null 2>&1
exec "$GODOT" --path . --resolution "${1:-1600x900}" -s res://tools/benchmark.gd
