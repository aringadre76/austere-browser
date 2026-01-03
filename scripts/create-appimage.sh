#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${PROJECT_ROOT}/output"
BUILD_DIR="${PROJECT_ROOT}/build_src"
APPIMAGE_DIR="${PROJECT_ROOT}/appimage_build"

VERSION=$(./scripts/get-version.sh)
APPIMAGE_NAME="austere-browser-${VERSION}-x86_64.AppImage"

print_status() {
    echo "==> $1"
}

print_error() {
    echo "ERROR: $1" >&2
}

if [ ! -d "$OUTPUT_DIR" ] || [ ! -f "$OUTPUT_DIR/austere-browser" ]; then
    print_error "Browser not built. Please build first with: ./build/build.sh build"
    exit 1
fi

print_status "Creating AppImage for Austere Browser ${VERSION}..."

rm -rf "${APPIMAGE_DIR}"
mkdir -p "${APPIMAGE_DIR}/austere-browser.AppDir"

APP_DIR="${APPIMAGE_DIR}/austere-browser.AppDir"

print_status "Setting up AppDir structure..."
mkdir -p "${APP_DIR}/usr/bin"
mkdir -p "${APP_DIR}/usr/share/austere-browser"
mkdir -p "${APP_DIR}/usr/share/applications"
mkdir -p "${APP_DIR}/usr/share/icons/hicolor/256x256/apps"

print_status "Copying browser files..."
cp -r "${OUTPUT_DIR}"/* "${APP_DIR}/usr/share/austere-browser/"

print_status "Creating AppRun launcher..."
cat > "${APP_DIR}/AppRun" << 'APPRUN'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/share/austere-browser:${LD_LIBRARY_PATH}"

LIB_DIR="${HERE}/usr/share/austere-browser"
FLAGS_FILE="${LIB_DIR}/austere_flags.txt"

flags=()
if [ -f "$FLAGS_FILE" ]; then
    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$line" ] && ! echo "$line" | grep -q '^#'; then
            flags+=("$line")
        fi
    done < "$FLAGS_FILE"
fi

exec "${LIB_DIR}/austere-browser" "${flags[@]}" "$@"
APPRUN
chmod +x "${APP_DIR}/AppRun"

print_status "Creating desktop entry..."
cat > "${APP_DIR}/austere-browser.desktop" << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Austere Browser
Comment=Fast, private, and minimal web browser
Exec=AppRun %U
Icon=austere-browser
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/svg+xml;
StartupNotify=true
DESKTOP

print_status "Creating icon (placeholder)..."
if command -v convert > /dev/null 2>&1; then
    convert -size 256x256 xc:transparent -font Arial -pointsize 72 -fill black -gravity center -annotate +0+0 "AB" "${APP_DIR}/usr/share/icons/hicolor/256x256/apps/austere-browser.png" 2>/dev/null || true
fi

if [ ! -f "${APP_DIR}/usr/share/icons/hicolor/256x256/apps/austere-browser.png" ]; then
    mkdir -p "${APP_DIR}/usr/share/icons/hicolor/256x256/apps"
    touch "${APP_DIR}/usr/share/icons/hicolor/256x256/apps/austere-browser.png"
fi

print_status "Downloading AppImageTool..."
APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
APPIMAGETOOL="${APPIMAGE_DIR}/appimagetool.AppImage"

if [ ! -f "$APPIMAGETOOL" ]; then
    curl -L -o "$APPIMAGETOOL" "$APPIMAGETOOL_URL" || {
        print_error "Failed to download AppImageTool"
        print_error "You can download it manually from: $APPIMAGETOOL_URL"
        exit 1
    }
    chmod +x "$APPIMAGETOOL"
fi

print_status "Creating AppImage..."
cd "${APPIMAGE_DIR}"
"$APPIMAGETOOL" "${APP_DIR}" "${APPIMAGE_NAME}" || {
    print_error "AppImageTool failed. You may need to install dependencies:"
    print_error "  sudo apt-get install libfuse2"
    exit 1
}

mv "${APPIMAGE_NAME}" "${PROJECT_ROOT}/"

print_status "AppImage created: ${PROJECT_ROOT}/${APPIMAGE_NAME}"
print_status ""
print_status "To make it executable:"
print_status "  chmod +x ${APPIMAGE_NAME}"
print_status ""
print_status "To run it:"
print_status "  ./${APPIMAGE_NAME}"

