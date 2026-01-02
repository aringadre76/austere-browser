#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build_src"
SRC_DIR="${BUILD_DIR}/src"
OUT_DIR="${SRC_DIR}/out/Austere"
CONFIG_DIR="${SCRIPT_DIR}/config"

NPROC=$(nproc 2>/dev/null || echo 4)
JOBS="${JOBS:-$NPROC}"

print_status() {
    echo "==> $1"
}

print_error() {
    echo "ERROR: $1" >&2
}

check_build_deps() {
    print_status "Checking build dependencies..."

    local deps=("python3" "ninja" "clang" "lld")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "$dep is required for building"
            exit 1
        fi
    done

    if ! python3 -c "import pkgutil; exit(0 if pkgutil.find_loader('setuptools') else 1)" 2>/dev/null; then
        print_error "python3-setuptools is required"
        exit 1
    fi
}

setup_environment() {
    print_status "Setting up build environment..."

    export PATH="${HOME}/.cargo/bin:${BUILD_DIR}/depot_tools:$PATH"

    export CC=clang
    export CXX=clang++
    export AR=llvm-ar
    export NM=llvm-nm

    export CFLAGS="-O2 -pipe"
    export CXXFLAGS="-O2 -pipe"
}

generate_gn_flags() {
    print_status "Generating GN build flags..."

    mkdir -p "$OUT_DIR"

    local flags_file="${PROJECT_ROOT}/flags.gn"
    if [[ -f "$flags_file" ]]; then
        cp "$flags_file" "${OUT_DIR}/args.gn"
    else
        python3 "${CONFIG_DIR}/gn_flags.py" > "${OUT_DIR}/args.gn"
    fi

    print_status "GN flags written to ${OUT_DIR}/args.gn"
}

run_gn() {
    print_status "Running GN to generate build files..."

    cd "$SRC_DIR"

    "${BUILD_DIR}/gn_bin/gn" gen "$OUT_DIR" --fail-on-unused-args
}

build_chromium() {
    print_status "Building Austere Browser (this will take a while)..."
    print_status "Using $JOBS parallel jobs"

    cd "$SRC_DIR"

    ninja -C "$OUT_DIR" -j"$JOBS" chrome chrome_sandbox
}

create_output() {
    print_status "Creating output package..."

    local output_dir="${PROJECT_ROOT}/output"
    mkdir -p "$output_dir"

    cp "${OUT_DIR}/chrome" "${output_dir}/austere-browser"
    cp "${OUT_DIR}/chrome_sandbox" "${output_dir}/"
    cp "${OUT_DIR}/chrome_crashpad_handler" "${output_dir}/" 2>/dev/null || true
    cp "${OUT_DIR}/"*.pak "${output_dir}/"
    cp "${OUT_DIR}/"*.bin "${output_dir}/" 2>/dev/null || true
    cp -r "${OUT_DIR}/locales" "${output_dir}/"
    cp -r "${OUT_DIR}/resources" "${output_dir}/" 2>/dev/null || true

    cp "${PROJECT_ROOT}/configs/austere_flags.txt" "${output_dir}/"

    chmod 4755 "${output_dir}/chrome_sandbox"

    print_status "Output created in: $output_dir"
}

full_build() {
    print_status "Austere Browser - Full Build"
    print_status "============================="

    "${SCRIPT_DIR}/fetch.sh"
    "${SCRIPT_DIR}/apply_patches.sh"

    check_build_deps
    setup_environment
    generate_gn_flags
    run_gn
    build_chromium
    create_output

    print_status "Build complete!"
}

build_only() {
    print_status "Austere Browser - Build Only"
    print_status "============================="

    check_build_deps
    setup_environment
    generate_gn_flags
    run_gn
    build_chromium
    create_output

    print_status "Build complete!"
}

show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  full     - Fetch, patch, and build (default)"
    echo "  build    - Build only (source must be fetched and patched)"
    echo "  gn       - Regenerate GN flags only"
    echo "  help     - Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  JOBS     - Number of parallel build jobs (default: $NPROC)"
}

main() {
    local cmd="${1:-full}"

    case "$cmd" in
        full)
            full_build
            ;;
        build)
            build_only
            ;;
        gn)
            setup_environment
            generate_gn_flags
            run_gn
            print_status "GN regeneration complete"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $cmd"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
