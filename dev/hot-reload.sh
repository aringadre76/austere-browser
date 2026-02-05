#!/bin/bash
# Hot reload for CSS/JS changes during development

WATCH_DIR="$(pwd)/css"
BUILD_CSS_DIR="../build_src/chromium-143.0.7499.169/chrome/browser/resources/austere"

echo "🔥 Starting CSS hot reload watcher..."
echo "Watching: $WATCH_DIR"
echo "Target: $BUILD_CSS_DIR"

# Create target directory if it doesn't exist
mkdir -p "$BUILD_CSS_DIR"

# Copy initial CSS files
cp -r "$WATCH_DIR"/* "$BUILD_CSS_DIR/" 2>/dev/null || true

# Watch for changes and auto-copy
inotifywait -m -r -e modify,create,delete --format '%w%f' "$WATCH_DIR" | while read file; do
    echo "📝 Changed: $file"
    cp "$file" "$BUILD_CSS_DIR/"
    echo "✅ File copied to build directory"
    echo "💡 Restart browser to see changes"
done
