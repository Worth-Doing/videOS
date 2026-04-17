#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-debug}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

VLC_LIB_PATH=""
for loc in "/Applications/VLC.app/Contents/MacOS/lib" "/opt/homebrew/lib" "/usr/local/lib"; do
    if [ -f "$loc/libvlc.dylib" ]; then
        VLC_LIB_PATH="$loc"
        break
    fi
done

if [ -z "$VLC_LIB_PATH" ]; then
    echo "ERROR: libvlc.dylib not found. Run 'make deps' first."
    exit 1
fi

echo "Building videOS ($CONFIG) with libVLC from: $VLC_LIB_PATH"

SWIFT_FLAGS="-Xlinker -L$VLC_LIB_PATH -Xlinker -rpath -Xlinker $VLC_LIB_PATH"

if [ "$CONFIG" = "release" ]; then
    swift build -c release $SWIFT_FLAGS
else
    swift build $SWIFT_FLAGS
fi

echo "Build complete: .build/$CONFIG/videOS"
