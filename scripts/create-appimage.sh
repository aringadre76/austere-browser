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

# Check for packaged version first, then fall back to output
PACKAGE_DIR="${PROJECT_ROOT}/package"
PACKAGE_NAME="austere-browser-${VERSION}-linux-x86_64"

if [ -d "${PACKAGE_DIR}/${PACKAGE_NAME}" ]; then
    print_status "Using packaged browser from ${PACKAGE_DIR}/${PACKAGE_NAME}"
    SOURCE_DIR="${PACKAGE_DIR}/${PACKAGE_NAME}"
elif [ -d "$OUTPUT_DIR" ] && [ -f "$OUTPUT_DIR/austere-browser" ]; then
    print_status "Using output directory"
    SOURCE_DIR="${OUTPUT_DIR}"
else
    print_error "Browser not built or packaged. Please build first with: ./build/build.sh build"
    print_error "Or create package with: ./scripts/package.sh"
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
if [ -d "${PACKAGE_DIR}/${PACKAGE_NAME}" ]; then
    # Use packaged version - copy everything
    cp -r "${PACKAGE_DIR}/${PACKAGE_NAME}"/* "${APP_DIR}/usr/"
    # Move binary to bin
    if [ -f "${APP_DIR}/usr/bin/austere-browser" ]; then
        : # Already in place
    elif [ -f "${APP_DIR}/usr/share/austere-browser/austere-browser" ]; then
        mkdir -p "${APP_DIR}/usr/bin"
        cp "${APP_DIR}/usr/share/austere-browser/austere-browser" "${APP_DIR}/usr/bin/"
    fi
else
    cp -r "${OUTPUT_DIR}"/* "${APP_DIR}/usr/share/austere-browser/"
fi

print_status "Creating AppRun launcher..."
cat > "${APP_DIR}/AppRun" << 'APPRUN'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/share/austere-browser:${LD_LIBRARY_PATH}"

# Try to find the binary
if [ -f "${HERE}/usr/bin/austere-browser" ]; then
    BINARY="${HERE}/usr/bin/austere-browser"
elif [ -f "${HERE}/usr/share/austere-browser/austere-browser" ]; then
    BINARY="${HERE}/usr/share/austere-browser/austere-browser"
else
    echo "Error: austere-browser binary not found" >&2
    exit 1
fi

LIB_DIR="${HERE}/usr/share/austere-browser"
FLAGS_FILE="${LIB_DIR}/configs/austere_flags.txt"

# Use Python wrapper if it exists, otherwise run directly
if [ -f "${HERE}/usr/bin/austere-browser" ] && head -1 "${BINARY}" | grep -q python; then
    exec "${BINARY}" "$@"
else
    flags=()
    if [ -f "$FLAGS_FILE" ]; then
        while IFS= read -r line; do
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$line" ] && ! echo "$line" | grep -q '^#'; then
                flags+=("$line")
            fi
        done < "$FLAGS_FILE"
    fi
    exec "${BINARY}" "${flags[@]}" "$@"
fi
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
