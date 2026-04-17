#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

BINARY=".build/debug/videOS"

if [ ! -f "$BINARY" ]; then
    echo "Binary not found, building..."
    bash scripts/build.sh debug
fi

VLC_LIB_PATH=""
for loc in "/Applications/VLC.app/Contents/MacOS/lib" "/opt/homebrew/lib" "/usr/local/lib"; do
    if [ -f "$loc/libvlc.dylib" ]; then
        VLC_LIB_PATH="$loc"
        break
    fi
done

export DYLD_LIBRARY_PATH="${VLC_LIB_PATH}:${DYLD_LIBRARY_PATH:-}"
export VLC_PLUGIN_PATH="${VLC_LIB_PATH}/../plugins"

echo "Launching videOS..."
exec "$BINARY" "$@"
