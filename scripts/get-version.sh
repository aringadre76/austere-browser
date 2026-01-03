#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="${PROJECT_ROOT}/VERSION"

get_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE" | tr -d '[:space:]'
    elif git describe --tags --abbrev=0 2>/dev/null | grep -q '^v'; then
        git describe --tags --abbrev=0 | sed 's/^v//'
    else
        echo "1.0.0"
    fi
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: $0 [--full]"
    echo ""
    echo "Get the current Austere Browser version."
    echo ""
    echo "Options:"
    echo "  --full    Show version with Chromium version"
    exit 0
fi

VERSION=$(get_version)

if [ "${1:-}" = "--full" ]; then
    BUILD_DIR="${PROJECT_ROOT}/build_src"
    CHROMIUM_VERSION=$(cat "${BUILD_DIR}/chromium_version.txt" 2>/dev/null || echo "unknown")
    echo "Austere Browser: ${VERSION}"
    echo "Chromium: ${CHROMIUM_VERSION}"
else
    echo "${VERSION}"
fi
