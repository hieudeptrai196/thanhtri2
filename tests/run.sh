#!/bin/sh
# Runs all headless gameplay tests. Usage: tests/run.sh [filter]
#   filter matches "file::test_name", e.g. tests/run.sh test_enemies
# Set GODOT if the Godot binary is not at the default path.
GODOT="${GODOT:-/Users/mac/Downloads/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.." || exit 1

# Refresh the script class cache so newly added class_name scripts resolve.
"$GODOT" --headless --path . --import >/dev/null 2>&1

# --fixed-fps runs frames as fast as possible with a constant 1/60 s step.
exec "$GODOT" --headless --path . --fixed-fps 60 -s res://tests/run_tests.gd -- "$@"
