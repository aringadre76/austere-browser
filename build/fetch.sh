#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build_src"

UNGOOGLED_REPO="https://github.com/ungoogled-software/ungoogled-chromium"
CHROMIUM_VERSION=""

print_status() {
    echo "==> $1"
}

print_error() {
    echo "ERROR: $1" >&2
}

check_dependencies() {
    print_status "Checking dependencies..."
    local deps=("git" "python3" "curl" "tar" "xz")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "$dep is required but not installed"
            exit 1
        fi
    done
}

fetch_ungoogled() {
    print_status "Fetching Ungoogled-Chromium repository..."

    if [[ -d "${BUILD_DIR}/ungoogled-chromium" ]]; then
        print_status "Updating existing Ungoogled-Chromium..."
        cd "${BUILD_DIR}/ungoogled-chromium"
        git fetch --all
        git pull
    else
        mkdir -p "$BUILD_DIR"
        cd "$BUILD_DIR"
        git clone "$UNGOOGLED_REPO"
    fi

    cd "${BUILD_DIR}/ungoogled-chromium"

    if [[ -z "$CHROMIUM_VERSION" ]]; then
        CHROMIUM_VERSION=$(cat chromium_version.txt 2>/dev/null || echo "")
        if [[ -z "$CHROMIUM_VERSION" ]]; then
            CHROMIUM_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/-.*//')
        fi
    fi

    print_status "Target Chromium version: $CHROMIUM_VERSION"
    echo "$CHROMIUM_VERSION" > "${BUILD_DIR}/chromium_version.txt"
}

fetch_chromium_source() {
    print_status "Fetching Chromium source code..."

    local chromium_tarball="chromium-${CHROMIUM_VERSION}.tar.xz"
    local chromium_url="https://commondatastorage.googleapis.com/chromium-browser-official/${chromium_tarball}"

    if [[ ! -f "${BUILD_DIR}/${chromium_tarball}" ]]; then
        print_status "Downloading Chromium ${CHROMIUM_VERSION}..."
        curl -L -o "${BUILD_DIR}/${chromium_tarball}" "$chromium_url"
    else
        print_status "Chromium tarball already exists, skipping download"
    fi

    if [[ ! -d "${BUILD_DIR}/chromium-${CHROMIUM_VERSION}" ]]; then
        print_status "Extracting Chromium source..."
        cd "$BUILD_DIR"
        tar xf "$chromium_tarball"
    else
        print_status "Chromium source already extracted"
    fi

    ln -sfn "chromium-${CHROMIUM_VERSION}" "${BUILD_DIR}/src"
}

setup_depot_tools() {
    print_status "Setting up depot_tools..."

    if [[ ! -d "${BUILD_DIR}/depot_tools" ]]; then
        cd "$BUILD_DIR"
        git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    fi

    export PATH="${BUILD_DIR}/depot_tools:$PATH"
}

main() {
    print_status "Austere Browser - Fetch Script"
    print_status "==============================="

    check_dependencies
    fetch_ungoogled
    fetch_chromium_source
    setup_depot_tools

    print_status "Fetch complete!"
    print_status "Chromium source: ${BUILD_DIR}/src"
    print_status "Ungoogled patches: ${BUILD_DIR}/ungoogled-chromium"
    print_status ""
    print_status "Next step: Run apply_patches.sh"
}

main "$@"
