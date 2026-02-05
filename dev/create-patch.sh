#!/bin/bash
# Generate patches from current changes

FEATURE_NAME="$1"

if [ -z "$FEATURE_NAME" ]; then
    echo "Usage: $0 <feature-name>"
    echo "Example: $0 new-ui-design"
    exit 1
fi

BUILD_DIR="../build_src/chromium-143.0.7499.169"
PATCH_DIR="patches/$(basename "$FEATURE_NAME")"
PATCH_FILE="$PATCH_DIR/001-$(echo "$FEATURE_NAME" | sed 's/[^a-zA-Z0-9]/-/g').patch"

echo "📦 Creating patch for: $FEATURE_NAME"

# Create patch directory
mkdir -p "$PATCH_DIR"

# Generate patch from git diff in build directory
cd "$BUILD_DIR"
git diff --no-prefix HEAD > "../$PATCH_FILE"

# Add patch to series file if not exists
if ! grep -q "$(basename "$PATCH_FILE")" "../../patches/series"; then
    echo "$(basename "$PATCH_FILE")" >> "../../patches/series"
fi

echo "✅ Patch created: $PATCH_FILE"
echo "📋 Added to patches/series"
