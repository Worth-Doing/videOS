#!/usr/bin/env bash
set -euo pipefail

echo "=== videOS Dependency Check ==="

check_vlc() {
    local locations=(
        "/Applications/VLC.app/Contents/MacOS/lib/libvlc.dylib"
        "/opt/homebrew/lib/libvlc.dylib"
        "/usr/local/lib/libvlc.dylib"
    )
    for loc in "${locations[@]}"; do
        if [ -f "$loc" ]; then
            echo "[OK] libvlc found: $loc"
            return 0
        fi
    done
    return 1
}

check_swift() {
    if command -v swift &> /dev/null; then
        local version
        version=$(swift --version 2>&1 | head -1)
        echo "[OK] Swift: $version"
        return 0
    fi
    return 1
}

if ! check_swift; then
    echo "[MISSING] Swift toolchain not found"
    echo "  Install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

if ! check_vlc; then
    echo "[MISSING] libVLC not found"
    echo ""
    echo "Install VLC via one of:"
    echo "  1. brew install --cask vlc    (recommended — installs VLC.app)"
    echo "  2. brew install vlc           (installs libvlc headers + dylib)"
    echo "  3. Download from https://www.videolan.org/vlc/download-macosx.html"
    echo ""
    read -rp "Install VLC.app via Homebrew now? [Y/n] " answer
    if [[ "${answer:-Y}" =~ ^[Yy]$ ]]; then
        brew install --cask vlc
        echo "[OK] VLC installed"
    else
        echo "Please install VLC manually and re-run."
        exit 1
    fi
fi

vlc_lib_path=""
for loc in "/Applications/VLC.app/Contents/MacOS/lib" "/opt/homebrew/lib" "/usr/local/lib"; do
    if [ -f "$loc/libvlc.dylib" ]; then
        vlc_lib_path="$loc"
        break
    fi
done

if [ -n "$vlc_lib_path" ]; then
    echo ""
    echo "=== VLC Library Info ==="
    ls -la "$vlc_lib_path"/libvlc*.dylib 2>/dev/null || true
    echo ""
    echo "VLC_LIB_PATH=$vlc_lib_path"
fi

echo ""
echo "=== All dependencies satisfied ==="
echo "Run 'make build' to compile videOS"
