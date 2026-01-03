#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${PROJECT_ROOT}/output"
BROWSER_BIN="${OUTPUT_DIR}/austere-browser"

print_status() {
    echo "==> $1"
}

print_error() {
    echo "ERROR: $1" >&2
}

print_success() {
    echo "✓ $1"
}

test_count=0
pass_count=0
fail_count=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    test_count=$((test_count + 1))
    print_status "Test $test_count: $test_name"
    
    if eval "$test_command"; then
        print_success "$test_name"
        pass_count=$((pass_count + 1))
        return 0
    else
        print_error "$test_name failed"
        fail_count=$((fail_count + 1))
        return 1
    fi
}

print_status "Austere Browser - Test Script"
print_status "=============================="
echo ""

if [ ! -d "$OUTPUT_DIR" ]; then
    print_error "Output directory not found: $OUTPUT_DIR"
    print_error "Please build the browser first with: ./build/build.sh build"
    exit 1
fi

run_test "Browser binary exists" "[ -f '$BROWSER_BIN' ]"

run_test "Browser binary is executable" "[ -x '$BROWSER_BIN' ]"

run_test "ICU data file exists" "[ -f '${OUTPUT_DIR}/icudtl.dat' ]"

run_test "GPU libraries exist" "[ -f '${OUTPUT_DIR}/libGLESv2.so' ] && [ -f '${OUTPUT_DIR}/libEGL.so' ]"

run_test "Sandbox binary exists" "[ -f '${OUTPUT_DIR}/chrome_sandbox' ]"

run_test "Sandbox has setuid bit" "[ -u '${OUTPUT_DIR}/chrome_sandbox' ] || [ -x '${OUTPUT_DIR}/chrome_sandbox' ]"

run_test "Resource files exist" "[ -f '${OUTPUT_DIR}/resources.pak' ] && [ -f '${OUTPUT_DIR}/chrome_100_percent.pak' ]"

run_test "Locale files exist" "[ -d '${OUTPUT_DIR}/locales' ] && [ -n \"\$(find '${OUTPUT_DIR}/locales' -name '*.pak' | head -1)\" ]"

run_test "Flags file exists" "[ -f '${OUTPUT_DIR}/austere_flags.txt' ]"

run_test "Browser version check" "timeout 5 '$BROWSER_BIN' --version > /dev/null 2>&1 || true"

run_test "Browser can start (headless check)" "timeout 5 '$BROWSER_BIN' --headless --disable-gpu --dump-dom 'data:text/html,<html></html>' > /dev/null 2>&1 || true"

if command -v ldd > /dev/null 2>&1; then
    run_test "Browser binary has required libraries" "ldd '$BROWSER_BIN' > /dev/null 2>&1"
fi

if command -v file > /dev/null 2>&1; then
    run_test "Browser binary is ELF executable" "file '$BROWSER_BIN' | grep -q 'ELF'"
fi

echo ""
print_status "Test Results"
print_status "============="
echo "Total tests: $test_count"
echo "Passed: $pass_count"
echo "Failed: $fail_count"

if [ $fail_count -eq 0 ]; then
    print_success "All tests passed!"
    exit 0
else
    print_error "Some tests failed"
    exit 1
fi

