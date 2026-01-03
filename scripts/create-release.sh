#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_status() {
    echo "==> $1"
}

print_error() {
    echo "ERROR: $1" >&2
}

if [ $# -lt 1 ]; then
    CURRENT_VERSION=$(./scripts/get-version.sh)
    print_error "Usage: $0 <version> [tag_name]"
    print_error "Example: $0 1.0.0 v1.0.0"
    print_error "Current version: ${CURRENT_VERSION}"
    exit 1
fi

VERSION="$1"
TAG_NAME="${2:-v${VERSION}}"

if [ -z "$VERSION" ]; then
    VERSION=$(./scripts/get-version.sh)
    print_status "No version specified, using current version: ${VERSION}"
fi

print_status "Creating release for version ${VERSION} (tag: ${TAG_NAME})"

if [ ! -d "${PROJECT_ROOT}/output" ] || [ ! -f "${PROJECT_ROOT}/output/austere-browser" ]; then
    print_error "Browser not built. Please build first with: ./build/build.sh build"
    exit 1
fi

print_status "Creating package..."
export AUSTERE_VERSION="${VERSION}"
cd "${PROJECT_ROOT}"
./scripts/package.sh

print_status "Creating release archive..."
cd "${PROJECT_ROOT}/package"
ARCHIVE_NAME="austere-browser-${VERSION}-linux-x64.tar.gz"
tar -czf "../${ARCHIVE_NAME}" austere-browser-*
cd "${PROJECT_ROOT}"

print_status "Creating checksum..."
sha256sum "${ARCHIVE_NAME}" > "${ARCHIVE_NAME%.tar.gz}.sha256"

print_status "Release files created:"
ls -lh "${ARCHIVE_NAME}" "${ARCHIVE_NAME%.tar.gz}.sha256"

print_status ""
print_status "To create a GitHub release:"
print_status "1. Create a tag: git tag -a ${TAG_NAME} -m 'Release ${VERSION}'"
print_status "2. Push the tag: git push origin ${TAG_NAME}"
print_status "3. Or use GitHub CLI: gh release create ${TAG_NAME} ${ARCHIVE_NAME} ${ARCHIVE_NAME%.tar.gz}.sha256 --title 'Austere Browser ${VERSION}'"
