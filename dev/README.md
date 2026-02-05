# Austere Browser Development Environment

This directory contains tools and scripts to make developing Austere Browser much faster.

## Quick Start

1. **Apply a patch for testing:**
   ```bash
   ./quick-test-patch.sh ui/001-new-tab-design.patch
   ```

2. **Build only the changes:**
   ```bash
   ./incremental-build.sh
   ```

3. **Run the development version:**
   ```bash
   ./run-dev.sh
   ```

## Development Scripts

### `./quick-test-patch.sh <patch-file>`
Quickly apply a single patch without affecting the main patch series.

### `./incremental-build.sh`
Build only the changed files (much faster than full rebuild).

### `./run-dev.sh`
Run the browser in development mode with debugging enabled.

### `./hot-reload.sh`
Watch CSS/JS files for changes and auto-copy to build directory.

### `./test-feature.sh <feature-name> [url]`
Test a new feature with an isolated profile and logging.

### `./create-patch.sh <feature-name>`
Generate a patch file from current changes in the build directory.

## Directory Structure

```
dev/
├── patches-temp/     # Working copies of patches for modification
├── css/              # CSS files for hot reload
├── js/               # JavaScript files for hot reload
├── assets/           # Browser assets and icons
├── runtime/          # Runtime data for testing
│   ├── user-data/    # Main development profile
│   ├── extensions/   # Development extensions
│   └── test-profiles/ # Isolated profiles for feature testing
├── logs/             # Development logs
└── test-builds/      # Incremental build outputs
```

## Development Tips

1. **Use component builds:** Enable `is_component_build=true` in dev flags for faster compiles.

2. **Incremental builds:** Only rebuild what changed with `./incremental-build.sh`.

3. **Isolate testing:** Use `./test-feature.sh` to test features without affecting your main profile.

4. **Hot reload:** Modify CSS/JS files in `dev/css/` and they'll be auto-copied.

5. **Debug logging:** Development mode includes verbose logging for troubleshooting.

## Performance vs. Development

- **Development builds** have debugging enabled and are slower
- **Production builds** use `flags.gn` and are optimized for performance
- Switch between them by using different GN flags files
