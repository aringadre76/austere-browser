# Austere Browser

A privacy-first, memory-efficient Chromium fork with aggressive bloat removal.

Austere Browser is built on top of Ungoogled-Chromium with extensive component stripping and memory optimization. It removes dozens of unused features to create the leanest possible Chromium-based browser.

## Features

### Stripped Components (Build-time)

The following components are completely removed at build time:

| Component | Why Removed |
|-----------|-------------|
| Safe Browsing | Network calls, database overhead |
| Sync/Signin/GAIA | Google account integration |
| Translate | Background service, ML models |
| Speech API | Audio processing overhead |
| Live Caption | ML models, audio processing |
| Screen AI | Accessibility ML overhead |
| History Clusters | ML processing, storage |
| Remoting | Chrome Remote Desktop |
| Media Router | Chromecast discovery |
| mDNS/Service Discovery | Network scanning |
| GCM | Google Cloud Messaging |
| Reporting API | Telemetry |
| VR/AR/XR | 3D processing |
| Reading List | Storage, sync |
| Side Panel | UI overhead |
| Widevine DRM | Netflix/streaming DRM |
| Feed/Discover | News feed |
| Lens | Image search |
| TensorFlow Lite | ML runtime |
| Background Mode | Process persistence |
| Hangout Services | Google Meet |
| NaCl | Native Client |

### Stripped UI Elements

| Element | Why Removed |
|---------|-----------|
| NTP Footer | Unnecessary UI |
| User Education Nags | Tutorial popups |
| Update Bubbles | Notification overhead |
| FedCM Bubble | Google auth UI |
| Safety Hub | Safe Browsing UI |
| Lens Overlay | Image search UI |
| Touch-to-Fill | Mobile UI on desktop |
| Outdated Upgrade Bubble | Nag UI |
| Default Browser Infobar | Annoying prompts |

### Stripped Services

| Service | Why Removed |
|---------|-----------|
| Optimization Guide | ML-based hints |
| Privacy Sandbox (Topics, FLEDGE, Attribution) | Ad tracking |
| Interest Groups | Ad targeting |
| First Party Sets | Cookie tracking |
| Origin Trials | Experimental features |
| Commerce/Shopping | Price tracking |
| DIPS | Bounce tracking |
| Enterprise Connectors | Corporate telemetry |

### Memory Optimization

- **Customizable Memory Management Levels** (user-configurable in settings):
  - **Super Aggressive** (default): 15-second tab discard threshold - Maximum memory savings
  - **Aggressive**: 30-second threshold - High memory savings
  - **Medium**: 45-second threshold - Moderate memory savings
  - **Light**: 2-hour threshold - Minimal memory savings
  - **None**: Disabled - No automatic memory management
- Infinite tab freezing (frozen tabs stay frozen)
- Memory Saver Mode enabled by default (Super Aggressive)
- Reduced renderer process limit (8 vs 42)
- V8 heap limits (128MB vs 2GB)
- Disk cache limited to 50MB
- All preloading disabled

**To change memory management level**: Go to `chrome://settings/performance` or use the Performance settings in the browser menu.

### Performance Enhancements

- Parallel downloading (5 connections per file)
- Increased max connections per host (15 vs 6)
- QUIC/HTTP3 enabled
- Optimized socket pools

### Privacy Enhancements

- All telemetry disabled
- All Google APIs disabled
- Third-party cookies blocked
- WebRTC IP leak protection
- Referrer stripping
- No sync/signin possible
- DuckDuckGo as default search

### UI Enhancements

- Tab memory usage tooltips (hover over tabs to see memory usage)
- Memory savings display for frozen/discarded tabs
- High memory usage indicators

## System Requirements

### Build Requirements

- Linux x86_64
- 25GB disk space for source
- 50GB disk space for build artifacts
- 8GB RAM minimum (16GB recommended)
- 4+ CPU cores
- Build time: 2-6 hours

### Build Dependencies

```bash
sudo apt install git python3 python3-setuptools curl tar xz-utils \
    ninja-build clang lld llvm libcups2-dev libpulse-dev libasound2-dev \
    libpci-dev libudev-dev libdrm-dev libgbm-dev libxkbcommon-dev \
    libwayland-dev libgtk-3-dev libdbus-1-dev libffi-dev \
    libglib2.0-dev libnss3-dev libnspr4-dev
```

For Arch Linux:

```bash
sudo pacman -S git python python-setuptools curl tar xz ninja clang lld llvm \
    cups libpulse alsa-lib pciutils systemd libdrm mesa libxkbcommon \
    wayland gtk3 dbus libffi glib2 nss nspr
```

## Building

### Quick Build

```bash
./build/build.sh full
```

### Step-by-Step Build

```bash
./build/fetch.sh
./build/apply_patches.sh
./build/build.sh build
```

### Build Options

```bash
./build/build.sh full    # Complete build from scratch
./build/build.sh build   # Build only (source must exist)
./build/build.sh gn      # Regenerate GN flags only
JOBS=4 ./build/build.sh build  # Control parallel jobs
```

## Installation

### Pre-built Releases (Recommended)

Download the latest release from [GitHub Releases](https://github.com/aringadre76/austere-browser/releases):

#### Option 1: AppImage (Recommended - No Installation Required)

```bash
# Download AppImage
wget https://github.com/aringadre76/austere-browser/releases/latest/download/austere-browser-*-x86_64.AppImage

# Make executable
chmod +x austere-browser-*-x86_64.AppImage

# Run directly
./austere-browser-*-x86_64.AppImage
```

**Note:** AppImage requires `libfuse2`. Install with:
- Ubuntu/Debian: `sudo apt-get install libfuse2`
- Fedora: `sudo dnf install fuse-libs`
- Arch: `sudo pacman -S fuse2`

#### Option 2: Tarball (Traditional Installation)

```bash
# Download and extract
wget https://github.com/aringadre76/austere-browser/releases/latest/download/austere-browser-*-linux-x86_64.tar.gz
tar -xzf austere-browser-*-linux-x86_64.tar.gz
cd austere-browser-*-linux-x86_64

# Install system-wide
sudo ./install.sh

# Or install to home directory
./install.sh ~/.local
```

### Building from Source

After building, install the browser:

```bash
./build/install.sh
```

This will install to `~/.local/` by default. For system-wide installation:

```bash
sudo INSTALL_PREFIX=/usr/local ./build/install.sh
```

The browser will be available as `austere-browser` in your PATH and in your application menu.

## Project Structure

```
austere-browser/
├── flags.gn                  # GN build flags (stripped components)
├── build/
│   ├── build.sh              # Main build orchestrator
│   ├── install.sh            # Installation script
│   ├── fetch.sh              # Fetch source code
│   ├── apply_patches.sh      # Apply patches using series file
│   └── config/
│       └── gn_flags.py       # GN flags loader
├── patches/
│   ├── series                # Patch ordering file
│   ├── memory/               # Memory optimization patches
│   │   ├── 001-aggressive-tab-discard.patch
│   │   ├── 002-process-limits.patch
│   │   ├── 003-v8-limits.patch
│   │   ├── 004-cache-preload.patch
│   │   ├── 005-infinite-tab-freezing.patch
│   │   ├── 006-memory-saving-by-default.patch
│   │   ├── 007-parallel-downloading.patch
│   │   └── 008-max-connections-per-host.patch
│   ├── core/                 # Component stripping patches
│   │   ├── 009-strip-bloat.patch
│   │   ├── 010-strip-ui.patch
│   │   └── 011-strip-services.patch
│   ├── privacy/              # Privacy patches
│   │   └── 001-enhanced-privacy.patch
│   ├── ui/                   # UI enhancement patches
│   │   └── 001-tab-memory-tooltip.patch
│   └── branding/             # Optional branding
├── configs/
│   ├── austere_flags.txt     # Runtime flags (80+ flags)
│   └── policies.json         # Browser policies (100+ policies)
└── scripts/
    └── package.sh            # Create distributable package
```

## Memory Comparison

Approximate memory usage with 10 tabs open:

| Browser | Memory Usage | Reduction |
|---------|-------------|-----------|
| Chrome | ~2.5GB | - |
| Firefox | ~1.8GB | 28% |
| Ungoogled-Chromium | ~2.2GB | 12% |
| Austere Browser | ~400MB | 84% |

Note: With aggressive tab freezing, frozen tabs use minimal memory.

## What Still Works

Despite aggressive stripping, the following still work:

- Web browsing (obviously)
- Extensions (from CRX files)
- Downloads (with parallel downloading)
- Printing and PDF viewing
- Video/audio playback (with hardware acceleration)
- DevTools
- WebRTC (with IP protection)
- Bookmarks (local only)
- History (local only)
- Cookies (first-party only by default)
- Tab memory usage monitoring (hover over tabs to see memory)

## What Does NOT Work

The following are intentionally disabled:

- Google Sign-in / Sync
- Translation
- Safe Browsing lookups
- Live Caption / Speech recognition
- Chromecast
- Chrome Remote Desktop
- Password sync (local only)
- Autofill sync (disabled entirely)
- Netflix/DRM content (Widevine removed)
- WebGL (disabled by default, enable with flag)
- Side Panel features
- Reading List
- Google Lens
- Shopping/price tracking

## Enabling Disabled Features

Some features can be re-enabled at runtime:

```bash
austere-browser --enable-webgl
austere-browser --enable-features=TranslateUI
```

For DRM content (Netflix), you need to rebuild with `enable_widevine=true`.

## License

Chromium and Ungoogled-Chromium: BSD 3-Clause
Austere Browser patches: MIT License

## Credits

- [Chromium Project](https://www.chromium.org/)
- [Ungoogled-Chromium](https://github.com/nickelundgreen/nickelundgreen)
- [Helium Browser](https://helium.computer/)
- [Bromite](https://github.com/nickelundgreen/nickelundgreen)
