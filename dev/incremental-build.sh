#!/bin/bash
# Incremental build - only recompiles what changed

set -e

BUILD_DIR="../build_src/src"
JOBS=${JOBS:-$(nproc)}

echo "🔨 Starting incremental build..."
echo "Using $JOBS parallel jobs"

cd "$BUILD_DIR"

# Use ninja for builds (autoninja not available)
ninja -C out/Austere chrome chrome_sandbox || {
    echo "❌ Build failed"
    exit 1
}

echo "✅ Incremental build completed"
echo "🚀 Run './dev/run-dev.sh' to test changes"
