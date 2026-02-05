#!/bin/bash
# Run development version with custom profile

set -e

CHROME_BIN="../austere-browser-1.0.1-x86_64.AppImage"
USER_DATA_DIR="$(pwd)/runtime/user-data"
EXTENSIONS_DIR="$(pwd)/runtime/extensions"

# Create user data directory if it doesn't exist
mkdir -p "$USER_DATA_DIR"

echo "🚀 Starting Austere Browser (Development Mode)"

# Development flags
DEV_FLAGS="
--user-data-dir=$USER_DATA_DIR
--disable-web-security
--disable-features=TranslateUI
--enable-features=VaapiVideoDecoder
--no-first-run
--no-default-browser-check
--disable-background-timer-throttling
--disable-backgrounding-occluded-windows
--disable-renderer-backgrounding
--disable-extensions-file-access-check
--load-extension=$EXTENSIONS_DIR
--enable-logging
--log-level=0
--vmodule=*=1
"

"$CHROME_BIN" $DEV_FLAGS "$@"
