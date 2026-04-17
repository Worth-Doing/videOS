#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

APP_NAME="videOS"
BUNDLE_DIR=".build/${APP_NAME}.app"
CONTENTS="${BUNDLE_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"
FRAMEWORKS="${CONTENTS}/Frameworks"

BINARY=".build/release/videOS"
if [ ! -f "$BINARY" ]; then
    echo "Release binary not found, building..."
    bash scripts/build.sh release
fi

echo "=== Packaging ${APP_NAME}.app ==="

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS" "$RESOURCES" "$FRAMEWORKS"

cp "$BINARY" "$MACOS/${APP_NAME}"

cp Resources/Info.plist "$CONTENTS/Info.plist"

if [ -f Resources/icon.icns ]; then
    cp Resources/icon.icns "$RESOURCES/${APP_NAME}.icns"
fi

if [ -f Resources/videOS.entitlements ]; then
    cp Resources/videOS.entitlements "$RESOURCES/"
fi

VLC_LIB_PATH=""
for loc in "/Applications/VLC.app/Contents/MacOS/lib" "/opt/homebrew/lib" "/usr/local/lib"; do
    if [ -f "$loc/libvlc.dylib" ]; then
        VLC_LIB_PATH="$loc"
        break
    fi
done

if [ -n "$VLC_LIB_PATH" ]; then
    echo "Bundling libVLC from: $VLC_LIB_PATH"
    cp "$VLC_LIB_PATH"/libvlc.dylib "$FRAMEWORKS/"
    cp "$VLC_LIB_PATH"/libvlccore.dylib "$FRAMEWORKS/" 2>/dev/null || true

    VLC_PLUGIN_PATH="$(dirname "$VLC_LIB_PATH")/plugins"
    if [ -d "$VLC_PLUGIN_PATH" ]; then
        echo "Bundling VLC plugins..."
        cp -R "$VLC_PLUGIN_PATH" "$RESOURCES/plugins"
    fi

    echo "Fixing dylib rpaths..."
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS/${APP_NAME}" 2>/dev/null || true

    for dylib in "$FRAMEWORKS"/*.dylib; do
        install_name_tool -id "@rpath/$(basename "$dylib")" "$dylib" 2>/dev/null || true
    done

    install_name_tool -change "$VLC_LIB_PATH/libvlc.dylib" "@rpath/libvlc.dylib" "$MACOS/${APP_NAME}" 2>/dev/null || true
    install_name_tool -change "$VLC_LIB_PATH/libvlccore.dylib" "@rpath/libvlccore.dylib" "$MACOS/${APP_NAME}" 2>/dev/null || true
fi

echo ""
echo "=== Bundle Contents ==="
find "$BUNDLE_DIR" -type f | head -30
echo ""

BUNDLE_SIZE=$(du -sh "$BUNDLE_DIR" | cut -f1)
echo "=== ${APP_NAME}.app created (${BUNDLE_SIZE}) ==="
echo "Location: $(pwd)/${BUNDLE_DIR}"
echo ""
echo "To run: open ${BUNDLE_DIR}"
echo "To sign: codesign --deep --force --sign - ${BUNDLE_DIR}"
