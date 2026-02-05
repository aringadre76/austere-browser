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

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Check if browser is built
if [ ! -d "${PROJECT_ROOT}/output" ] || [ ! -f "${PROJECT_ROOT}/output/austere-browser" ]; then
    print_error "Browser not built. Please build first with: ./build/build.sh build"
    exit 1
fi

print_status "Creating package..."
export AUSTERE_VERSION="${VERSION}"
cd "${PROJECT_ROOT}"
./scripts/package.sh

print_status "Creating release archives..."

PLATFORM="linux-x86_64"

print_status "Creating tarball..."
cd "${PROJECT_ROOT}/package"
ARCHIVE_NAME="austere-browser-${VERSION}-${PLATFORM}.tar.gz"
tar -czf "../${ARCHIVE_NAME}" austere-browser-*
cd "${PROJECT_ROOT}"

print_status "Creating AppImage..."
APPIMAGE_NAME="austere-browser-${VERSION}-x86_64.AppImage"
if ./scripts/create-appimage.sh 2>/dev/null && [ -f "${APPIMAGE_NAME}" ]; then
    print_status "AppImage created: ${APPIMAGE_NAME}"
else
    print_status "AppImage creation skipped (dependencies may be missing - need libfuse2)"
    APPIMAGE_NAME=""
fi

print_status "Creating checksums..."
CHECKSUM_NAME="austere-browser-${VERSION}-${PLATFORM}.sha256"
sha256sum "${ARCHIVE_NAME}" > "${CHECKSUM_NAME}"
if [ -n "${APPIMAGE_NAME}" ] && [ -f "${APPIMAGE_NAME}" ]; then
    sha256sum "${APPIMAGE_NAME}" >> "${CHECKSUM_NAME}"
fi

print_status "Release files created:"
ls -lh "${ARCHIVE_NAME}" "${CHECKSUM_NAME}"
if [ -n "${APPIMAGE_NAME}" ] && [ -f "${APPIMAGE_NAME}" ]; then
    ls -lh "${APPIMAGE_NAME}"
fi

print_status ""
print_status "Creating GitHub release..."

# Check if tag exists
if git rev-parse "${TAG_NAME}" >/dev/null 2>&1; then
    print_status "Tag ${TAG_NAME} already exists"
    if [ "$(git rev-parse ${TAG_NAME})" != "$(git rev-parse HEAD)" ]; then
        print_error "Tag ${TAG_NAME} points to a different commit. Use a different version or delete the tag."
        exit 1
    fi
else
    print_status "Creating git tag: ${TAG_NAME}"
    git tag -a "${TAG_NAME}" -m "Release ${VERSION}" || {
        print_error "Failed to create tag. Make sure you're on the correct branch and have commits."
        exit 1
    }
fi

# Check if GitHub CLI is available
if ! command -v gh >/dev/null 2>&1; then
    print_error "GitHub CLI (gh) not found. Please install it or upload manually:"
    print_status "1. Push the tag: git push origin ${TAG_NAME}"
    print_status "2. Upload files manually at: https://github.com/aringadre76/austere-browser/releases/new"
    exit 1
fi

# Check if authenticated
if ! gh auth status >/dev/null 2>&1; then
    print_error "Not authenticated with GitHub. Run: gh auth login"
    print_status "Then push the tag: git push origin ${TAG_NAME}"
    exit 1
fi

# Create or update release
print_status "Creating/updating GitHub release..."
RELEASE_NOTES="Release ${VERSION} for Linux x86_64

**Downloads:**
- **AppImage** (Recommended): No installation needed, just run it
- **Tarball**: Extract and run \`./install.sh\`
- **Checksum**: Verify download integrity
- **Source code**: Build from source (zip and tar.gz)

**Features:**
- Tab memory tooltips (hover over tabs to see memory usage)
- Customizable memory management levels (None, Light, Medium, Aggressive, Super Aggressive)
- Privacy-focused and memory-efficient Chromium build"

if gh release view "${TAG_NAME}" >/dev/null 2>&1; then
    print_status "Release already exists, updating..."
    gh release edit "${TAG_NAME}" --notes "${RELEASE_NOTES}" 2>&1 || true
else
    print_status "Creating new release..."
    gh release create "${TAG_NAME}" \
        --title "Austere Browser ${VERSION}" \
        --notes "${RELEASE_NOTES}" \
        --draft=false 2>&1 || {
        print_error "Failed to create release. Make sure the tag is pushed: git push origin ${TAG_NAME}"
        exit 1
    }
fi

# Upload all assets
print_status "Uploading assets to GitHub release..."
UPLOAD_FILES=("${ARCHIVE_NAME}" "${CHECKSUM_NAME}")
if [ -n "${APPIMAGE_NAME}" ] && [ -f "${APPIMAGE_NAME}" ]; then
    UPLOAD_FILES+=("${APPIMAGE_NAME}")
fi

for file in "${UPLOAD_FILES[@]}"; do
    if [ -f "${file}" ]; then
        print_status "Uploading ${file}..."
        gh release upload "${TAG_NAME}" "${file}" --clobber 2>&1 || {
            print_error "Failed to upload ${file}"
        }
    fi
done

# Push tag if not already pushed
if ! git ls-remote --tags origin | grep -q "refs/tags/${TAG_NAME}"; then
    print_status "Pushing tag to GitHub..."
    git push origin "${TAG_NAME}" 2>&1 || {
        print_error "Failed to push tag. Push manually: git push origin ${TAG_NAME}"
    }
fi

print_status ""
print_status "✅ Release created successfully!"
print_status ""
print_status "Release URL: https://github.com/aringadre76/austere-browser/releases/tag/${TAG_NAME}"
print_status ""
print_status "Assets uploaded:"
for file in "${UPLOAD_FILES[@]}"; do
    if [ -f "${file}" ]; then
        ls -lh "${file}" | awk '{print "  - " $9 " (" $5 ")"}'
    fi
done
print_status "  - Source code (zip) - Auto-generated by GitHub"
print_status "  - Source code (tar.gz) - Auto-generated by GitHub"
