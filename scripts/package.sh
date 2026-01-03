#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${PROJECT_ROOT}/output"
PACKAGE_DIR="${PROJECT_ROOT}/package"
BUILD_DIR="${PROJECT_ROOT}/build_src"

VERSION=$(cat "${BUILD_DIR}/chromium_version.txt" 2>/dev/null || echo "0.0.0")
AUSTERE_VERSION="1.0.0"
PACKAGE_NAME="austere-browser-${AUSTERE_VERSION}-linux-x64"

print_status() {
    echo "==> $1"
}

print_error() {
    echo "ERROR: $1" >&2
}

create_package_structure() {
    print_status "Creating package structure..."

    rm -rf "${PACKAGE_DIR}"
    mkdir -p "${PACKAGE_DIR}/${PACKAGE_NAME}"

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}"

    mkdir -p "${dest}/bin"
    mkdir -p "${dest}/share/austere-browser"
    mkdir -p "${dest}/share/applications"
}

copy_browser_files() {
    print_status "Copying browser files..."

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}/share/austere-browser"

    if [ ! -d "$OUTPUT_DIR" ]; then
        print_error "Output directory not found: $OUTPUT_DIR"
        print_error "Please build the browser first with: ./build/build.sh build"
        exit 1
    fi

    if [ ! -f "$OUTPUT_DIR/austere-browser" ]; then
        print_error "Browser binary not found: $OUTPUT_DIR/austere-browser"
        exit 1
    fi

    cp -r "${OUTPUT_DIR}"/* "${dest}/"
}

create_launcher() {
    print_status "Creating launcher script..."

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}/bin"

    cat > "${dest}/austere-browser" << 'LAUNCHER'
#!/usr/bin/env python3
import os
import sys

lib_dir = os.path.expanduser("~/.local/share/austere-browser")
if not os.path.isdir(lib_dir):
    lib_dir = "/usr/local/share/austere-browser"

os.environ["LD_LIBRARY_PATH"] = f"{lib_dir}:{os.environ.get('LD_LIBRARY_PATH', '')}"

flags_file = os.path.join(lib_dir, "austere_flags.txt")
browser_bin = os.path.join(lib_dir, "austere-browser")

flags = []
if os.path.isfile(flags_file):
    with open(flags_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                flags.append(line)

cmd = [browser_bin] + flags + sys.argv[1:]
os.execv(browser_bin, cmd)
LAUNCHER

    chmod +x "${dest}/austere-browser"
}

create_desktop_entry() {
    print_status "Creating desktop entry..."

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}/share/applications"

    cat > "${dest}/austere-browser.desktop" << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Austere Browser
Comment=Fast, private, and minimal web browser
Exec=austere-browser %U
Icon=application-x-executable
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/svg+xml;
StartupNotify=true
DESKTOP
}

set_permissions() {
    print_status "Setting permissions..."

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}/share/austere-browser"
    local bin_dest="${PACKAGE_DIR}/${PACKAGE_NAME}/bin"

    chmod +x "${dest}/austere-browser"
    chmod 4755 "${dest}/chrome_sandbox" 2>/dev/null || chmod +x "${dest}/chrome_sandbox"
    chmod +x "${bin_dest}/austere-browser"
}

create_install_script() {
    print_status "Creating install script..."

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}"

    cat > "${dest}/install.sh" << 'INSTALL'
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="${1:-/usr/local}"

if [ "$EUID" -ne 0 ] && [ "$INSTALL_PREFIX" = "/usr/local" ]; then
    echo "Installing to user directory instead (requires sudo for system-wide install)"
    INSTALL_PREFIX="$HOME/.local"
fi

echo "Installing Austere Browser to ${INSTALL_PREFIX}..."

BIN_DIR="${INSTALL_PREFIX}/bin"
SHARE_DIR="${INSTALL_PREFIX}/share/austere-browser"
DESKTOP_DIR="${INSTALL_PREFIX}/share/applications"

install -d "${BIN_DIR}"
install -d "${SHARE_DIR}"
install -d "${DESKTOP_DIR}"

cp -r "${SCRIPT_DIR}/share/austere-browser/"* "${SHARE_DIR}/"

cat > "${BIN_DIR}/austere-browser" << 'EOF'
#!/usr/bin/env python3
import os
import sys

lib_dir = os.path.expanduser("~/.local/share/austere-browser")
if not os.path.isdir(lib_dir):
    lib_dir = "/usr/local/share/austere-browser"

os.environ["LD_LIBRARY_PATH"] = f"{lib_dir}:{os.environ.get('LD_LIBRARY_PATH', '')}"

flags_file = os.path.join(lib_dir, "austere_flags.txt")
browser_bin = os.path.join(lib_dir, "austere-browser")

flags = []
if os.path.isfile(flags_file):
    with open(flags_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                flags.append(line)

cmd = [browser_bin] + flags + sys.argv[1:]
os.execv(browser_bin, cmd)
EOF
chmod +x "${BIN_DIR}/austere-browser"

cp "${SCRIPT_DIR}/share/applications/austere-browser.desktop" "${DESKTOP_DIR}/"

chmod +x "${SHARE_DIR}/austere-browser"
chmod 4755 "${SHARE_DIR}/chrome_sandbox" 2>/dev/null || chmod +x "${SHARE_DIR}/chrome_sandbox"

echo "Installation complete!"
echo "You can now run: austere-browser"
echo "Or find it in your application menu as 'Austere Browser'"
INSTALL

    chmod +x "${dest}/install.sh"
}

create_tarball() {
    print_status "Creating tarball..."

    cd "${PACKAGE_DIR}"
    tar -cJf "${PACKAGE_NAME}.tar.xz" "${PACKAGE_NAME}"

    print_status "Package created: ${PACKAGE_DIR}/${PACKAGE_NAME}.tar.xz"
}

show_package_info() {
    print_status "Package Information"
    print_status "==================="
    echo "Name: ${PACKAGE_NAME}"
    echo "Chromium version: ${VERSION}"
    echo "Austere version: ${AUSTERE_VERSION}"
    echo "Package location: ${PACKAGE_DIR}/${PACKAGE_NAME}.tar.xz"
    echo ""
    echo "Installation:"
    echo "  tar xf ${PACKAGE_NAME}.tar.xz"
    echo "  cd ${PACKAGE_NAME}"
    echo "  sudo ./install.sh"
}

main() {
    print_status "Austere Browser - Package Script"
    print_status "================================="

    if [[ ! -d "$OUTPUT_DIR" ]]; then
        print_error "Build output not found at $OUTPUT_DIR"
        print_error "Run build.sh first."
        exit 1
    fi

    if [[ ! -f "$OUTPUT_DIR/austere-browser" ]]; then
        print_error "Browser binary not found: $OUTPUT_DIR/austere-browser"
        exit 1
    fi

    create_package_structure
    copy_browser_files
    create_launcher
    create_desktop_entry
    set_permissions
    create_install_script
    create_tarball
    show_package_info

    print_status "Packaging complete!"
}

main "$@"
