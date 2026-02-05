#!/bin/bash
# Test new browser features quickly

FEATURE_NAME="$1"
TEST_URL="$2"

if [ -z "$FEATURE_NAME" ]; then
    echo "Usage: $0 <feature-name> [test-url]"
    echo "Example: $0 new-tab-design https://example.com"
    exit 1
fi

TEST_URL=${TEST_URL:-"https://example.com"}

echo "🧪 Testing feature: $FEATURE_NAME"
echo "📊 Test URL: $TEST_URL"

# Create isolated profile for this test
TEST_PROFILE="$(pwd)/runtime/test-profiles/$FEATURE_NAME"
mkdir -p "$TEST_PROFILE"

# Run browser with isolated profile and logging
CHROME_BIN="../output/chrome"

TEST_FLAGS="
--user-data-dir=$TEST_PROFILE
--enable-logging
--log-level=0
--vmodule=*=1
--no-first-run
--no-default-browser-check
--disable-web-security
"

"$CHROME_BIN" $TEST_FLAGS "$TEST_URL"

echo "✅ Test completed for feature: $FEATURE_NAME"
echo "📋 Logs available in: $TEST_PROFILE/debug.log"
