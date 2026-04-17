#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

APP_NAME="videOS"
VERSION="1.0.0"
IDENTITY="Developer ID Application: Simon-Pierre Boucher (3YM54G49SN)"
KEYCHAIN_PROFILE="videOS-notarize"

BINARY=".build/release/videOS"
BUNDLE_DIR=".build/${APP_NAME}.app"
CONTENTS="${BUNDLE_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"
FRAMEWORKS="${CONTENTS}/Frameworks"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH=".build/${DMG_NAME}"
DMG_STAGING=".build/dmg-staging"

VLC_LIB="/Applications/VLC.app/Contents/MacOS/lib"

sign_file() {
    local file="$1"
    local max_retries=3
    local attempt=0
    while [ $attempt -lt $max_retries ]; do
        if codesign --force --options runtime --timestamp --sign "$IDENTITY" "$file" 2>/dev/null; then
            return 0
        fi
        attempt=$((attempt + 1))
        echo "    Retry $attempt for $(basename "$file")..."
        sleep 2
    done
    echo "    WARNING: Failed to sign $(basename "$file") after $max_retries attempts"
    return 1
}

echo "=== Step 1: Creating app bundle ==="
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS" "$RESOURCES" "$FRAMEWORKS"

cp "$BINARY" "$MACOS/${APP_NAME}"
cp Resources/Info.plist "$CONTENTS/Info.plist"
cp Resources/icon.icns "$RESOURCES/${APP_NAME}.icns"

# Bundle yt-dlp
YTDLP_PATH=$(which yt-dlp 2>/dev/null)
if [ -n "$YTDLP_PATH" ]; then
    echo "  Bundling yt-dlp..."
    cp "$YTDLP_PATH" "$MACOS/yt-dlp"
    chmod +x "$MACOS/yt-dlp"
fi

echo "  Bundling libVLC..."
cp "$VLC_LIB/libvlc.dylib" "$FRAMEWORKS/"
cp "$VLC_LIB/libvlc.5.dylib" "$FRAMEWORKS/"
cp "$VLC_LIB/libvlccore.dylib" "$FRAMEWORKS/"
cp "$VLC_LIB/libvlccore.9.dylib" "$FRAMEWORKS/"

VLC_PLUGIN_DIR="/Applications/VLC.app/Contents/MacOS/plugins"
if [ -d "$VLC_PLUGIN_DIR" ]; then
    echo "  Bundling VLC plugins..."
    cp -R "$VLC_PLUGIN_DIR" "$RESOURCES/plugins"
fi

echo "  Fixing rpaths..."
install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS/${APP_NAME}" 2>/dev/null || true

for dylib in "$FRAMEWORKS"/*.dylib; do
    install_name_tool -id "@rpath/$(basename "$dylib")" "$dylib" 2>/dev/null || true
done

install_name_tool -change "$VLC_LIB/libvlc.5.dylib" "@rpath/libvlc.5.dylib" "$MACOS/${APP_NAME}" 2>/dev/null || true
install_name_tool -change "$VLC_LIB/libvlccore.9.dylib" "@rpath/libvlccore.9.dylib" "$MACOS/${APP_NAME}" 2>/dev/null || true
install_name_tool -change "$VLC_LIB/libvlc.dylib" "@rpath/libvlc.dylib" "$MACOS/${APP_NAME}" 2>/dev/null || true
install_name_tool -change "$VLC_LIB/libvlccore.dylib" "@rpath/libvlccore.dylib" "$MACOS/${APP_NAME}" 2>/dev/null || true

for dylib in "$FRAMEWORKS"/*.dylib; do
    install_name_tool -change "$VLC_LIB/libvlccore.9.dylib" "@rpath/libvlccore.9.dylib" "$dylib" 2>/dev/null || true
    install_name_tool -change "$VLC_LIB/libvlccore.dylib" "@rpath/libvlccore.dylib" "$dylib" 2>/dev/null || true
done

echo ""
echo "=== Step 2: Codesigning ==="

echo "  Signing frameworks..."
for dylib in "$FRAMEWORKS"/*.dylib; do
    sign_file "$dylib"
done

# Sign bundled yt-dlp if present
if [ -f "$MACOS/yt-dlp" ]; then
    echo "  Signing yt-dlp..."
    sign_file "$MACOS/yt-dlp"
fi

if [ -d "$RESOURCES/plugins" ]; then
    total=$(find "$RESOURCES/plugins" -name "*.dylib" | wc -l | tr -d ' ')
    count=0
    echo "  Signing $total plugins..."
    find "$RESOURCES/plugins" -name "*.dylib" | while read -r dylib; do
        count=$((count + 1))
        sign_file "$dylib"
        if [ $((count % 50)) -eq 0 ]; then
            echo "    Signed $count/$total plugins..."
        fi
    done
    echo "    All plugins signed"
fi

echo "  Signing binary..."
sign_file "$MACOS/${APP_NAME}"

echo "  Signing app bundle..."
codesign --force --deep --options runtime --timestamp --sign "$IDENTITY" "$BUNDLE_DIR"

echo "  Verifying signature..."
codesign --verify --deep --strict "$BUNDLE_DIR" 2>&1 && echo "  Signature valid" || echo "  WARNING: Verification issues"
echo ""

echo "=== Step 3: Creating DMG ==="
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$BUNDLE_DIR" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_STAGING"

codesign --force --timestamp --sign "$IDENTITY" "$DMG_PATH"
echo "  DMG signed"
echo ""

echo "=== Step 4: Notarizing ==="
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait

echo ""
echo "=== Step 5: Stapling ==="
xcrun stapler staple "$DMG_PATH"

echo ""
echo "=== Complete ==="
echo "DMG: $(pwd)/$DMG_PATH"
ls -lh "$DMG_PATH"
spctl --assess --type open --context context:primary-signature -v "$DMG_PATH" 2>&1 || true
