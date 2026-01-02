#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build_src"
SRC_DIR="${BUILD_DIR}/src"
OUT_DIR="${SRC_DIR}/out/Austere"
OUTPUT_DIR="${PROJECT_ROOT}/output"
PACKAGE_DIR="${PROJECT_ROOT}/package"

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
    mkdir -p "${dest}/lib"
    mkdir -p "${dest}/locales"
    mkdir -p "${dest}/resources"
}

copy_browser_files() {
    print_status "Copying browser files..."

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}"

    cp "${OUT_DIR}/chrome" "${dest}/lib/austere-browser"
    cp "${OUT_DIR}/chrome_sandbox" "${dest}/lib/"
    cp "${OUT_DIR}/chrome_crashpad_handler" "${dest}/lib/" 2>/dev/null || true

    cp "${OUT_DIR}/"*.pak "${dest}/lib/"
    cp "${OUT_DIR}/"*.bin "${dest}/lib/" 2>/dev/null || true
    cp "${OUT_DIR}/"*.dat "${dest}/lib/" 2>/dev/null || true

    cp -r "${OUT_DIR}/locales/"* "${dest}/locales/"

    if [[ -d "${OUT_DIR}/resources" ]]; then
        cp -r "${OUT_DIR}/resources/"* "${dest}/resources/"
    fi

    cp "${PROJECT_ROOT}/configs/austere_flags.txt" "${dest}/"
    cp "${PROJECT_ROOT}/configs/policies.json" "${dest}/"
}

create_launcher() {
    print_status "Creating launcher script..."

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}"

    cat > "${dest}/bin/austere-browser" << 'LAUNCHER'
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="${INSTALL_DIR}/lib"

export LD_LIBRARY_PATH="${LIB_DIR}:${LD_LIBRARY_PATH:-}"

FLAGS_FILE="${INSTALL_DIR}/austere_flags.txt"
if [[ -f "$FLAGS_FILE" ]]; then
    mapfile -t FLAGS < "$FLAGS_FILE"
else
    FLAGS=()
fi

exec "${LIB_DIR}/austere-browser" "${FLAGS[@]}" "$@"
LAUNCHER

    chmod +x "${dest}/bin/austere-browser"
}

create_desktop_entry() {
    print_status "Creating desktop entry..."

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}"

    mkdir -p "${dest}/share/applications"

    cat > "${dest}/share/applications/austere-browser.desktop" << 'DESKTOP'
[Desktop Entry]
Version=1.0
Name=Austere Browser
GenericName=Web Browser
Comment=Privacy-focused, memory-efficient web browser
Exec=austere-browser %U
Terminal=false
Type=Application
Icon=austere-browser
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=Austere
DESKTOP
}

set_permissions() {
    print_status "Setting permissions..."

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}"

    chmod 4755 "${dest}/lib/chrome_sandbox"
    chmod +x "${dest}/lib/austere-browser"
    chmod +x "${dest}/bin/austere-browser"
}

create_install_script() {
    print_status "Creating install script..."

    local dest="${PACKAGE_DIR}/${PACKAGE_NAME}"

    cat > "${dest}/install.sh" << 'INSTALL'
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="${1:-/usr/local}"

echo "Installing Austere Browser to ${INSTALL_PREFIX}..."

install -d "${INSTALL_PREFIX}/lib/austere-browser"
install -d "${INSTALL_PREFIX}/bin"
install -d "${INSTALL_PREFIX}/share/applications"

cp -r "${SCRIPT_DIR}/lib/"* "${INSTALL_PREFIX}/lib/austere-browser/"
cp -r "${SCRIPT_DIR}/locales" "${INSTALL_PREFIX}/lib/austere-browser/"
cp -r "${SCRIPT_DIR}/resources" "${INSTALL_PREFIX}/lib/austere-browser/" 2>/dev/null || true
cp "${SCRIPT_DIR}/austere_flags.txt" "${INSTALL_PREFIX}/lib/austere-browser/"
cp "${SCRIPT_DIR}/policies.json" "${INSTALL_PREFIX}/lib/austere-browser/"

cat > "${INSTALL_PREFIX}/bin/austere-browser" << 'EOF'
#!/bin/bash
LIB_DIR="/usr/local/lib/austere-browser"
if [[ "$0" == /usr/* ]]; then
    LIB_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")/lib/austere-browser"
fi
FLAGS_FILE="${LIB_DIR}/austere_flags.txt"
if [[ -f "$FLAGS_FILE" ]]; then
    mapfile -t FLAGS < "$FLAGS_FILE"
else
    FLAGS=()
fi
exec "${LIB_DIR}/austere-browser" "${FLAGS[@]}" "$@"
EOF
chmod +x "${INSTALL_PREFIX}/bin/austere-browser"

cp "${SCRIPT_DIR}/share/applications/austere-browser.desktop" "${INSTALL_PREFIX}/share/applications/"

chown root:root "${INSTALL_PREFIX}/lib/austere-browser/chrome_sandbox"
chmod 4755 "${INSTALL_PREFIX}/lib/austere-browser/chrome_sandbox"

echo "Installation complete!"
echo "Run 'austere-browser' to start the browser."
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

    if [[ ! -d "$OUT_DIR" ]]; then
        print_error "Build output not found at $OUT_DIR"
        print_error "Run build.sh first."
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
