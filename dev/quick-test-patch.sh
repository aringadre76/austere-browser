#!/bin/bash
# Quick patch testing without full rebuild

PATCH_FILE="$1"
PATCH_NAME=$(basename "$PATCH_FILE")

if [ -z "$PATCH_FILE" ]; then
    echo "Usage: $0 <patch-file>"
    exit 1
fi

echo "🔧 Testing patch: $PATCH_NAME"

# Apply patch to build directory
cd "$(dirname "$0")/../build_src/chromium-143.0.7499.169"
patch -p1 < "../dev/patches-temp/$PATCH_NAME" || {
    echo "❌ Patch failed to apply"
    exit 1
}

echo "✅ Patch applied successfully"
echo "💡 Run './dev/incremental-build.sh' to compile changes"
