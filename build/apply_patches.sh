#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build_src"
PATCHES_DIR="${PROJECT_ROOT}/patches"
SRC_DIR="${BUILD_DIR}/src"
UNGOOGLED_DIR="${BUILD_DIR}/ungoogled-chromium"

print_status() {
    echo "==> $1"
}

print_error() {
    echo "ERROR: $1" >&2
}

print_warning() {
    echo "WARNING: $1" >&2
}

apply_ungoogled_patches() {
    print_status "Applying Ungoogled-Chromium patches..."

    if [[ ! -d "$UNGOOGLED_DIR" ]]; then
        print_error "Ungoogled-Chromium not found. Run fetch.sh first."
        exit 1
    fi

    cd "$SRC_DIR"

    if [[ -x "${UNGOOGLED_DIR}/utils/patches.py" ]]; then
        print_status "Using Ungoogled patches.py utility..."
        python3 "${UNGOOGLED_DIR}/utils/patches.py" apply "$SRC_DIR" "${UNGOOGLED_DIR}/patches" || {
            print_warning "Some Ungoogled patches may have failed - continuing anyway"
        }
    else
        local patches_dir="${UNGOOGLED_DIR}/patches"
        if [[ -d "$patches_dir" ]]; then
            for patch_file in "$patches_dir"/*.patch; do
                if [[ -f "$patch_file" ]]; then
                    print_status "Applying: $(basename "$patch_file")"
                    patch -p1 --forward --no-backup-if-mismatch < "$patch_file" 2>/dev/null || true
                fi
            done
        fi
    fi
}

apply_domain_substitution() {
    print_status "Applying domain substitution..."

    if [[ -x "${UNGOOGLED_DIR}/utils/domain_substitution.py" ]]; then
        local sub_list="${UNGOOGLED_DIR}/domain_substitution.list"
        local regex_list="${UNGOOGLED_DIR}/domain_regex.list"

        if [[ -f "$sub_list" && -f "$regex_list" ]]; then
            python3 "${UNGOOGLED_DIR}/utils/domain_substitution.py" apply \
                -r "$regex_list" \
                -f "$sub_list" \
                "$SRC_DIR" || {
                print_warning "Domain substitution had some issues - continuing"
            }
        fi
    fi
}

apply_austere_patches() {
    print_status "Applying Austere Browser patches..."

    local series_file="${PATCHES_DIR}/series"
    local applied=0
    local failed=0

    if [[ -f "$series_file" ]]; then
        print_status "Using patches/series file for patch ordering..."

        while IFS= read -r patch_path || [[ -n "$patch_path" ]]; do
            [[ -z "$patch_path" || "$patch_path" =~ ^# ]] && continue

            local full_path="${PATCHES_DIR}/${patch_path}"
            if [[ -f "$full_path" ]]; then
                print_status "Applying: ${patch_path}"
                cd "$SRC_DIR"
                if patch -p1 --forward --no-backup-if-mismatch < "$full_path" 2>/dev/null; then
                    ((applied++))
                else
                    print_warning "Patch partially applied or skipped: ${patch_path}"
                    ((failed++))
                fi
            else
                print_warning "Patch not found: ${full_path}"
                ((failed++))
            fi
        done < "$series_file"
    else
        print_status "No series file found, applying patches by category..."
        local patch_categories=("memory" "privacy" "core" "branding")

        for category in "${patch_categories[@]}"; do
            local category_dir="${PATCHES_DIR}/${category}"
            if [[ -d "$category_dir" ]]; then
                for patch_file in "$category_dir"/*.patch; do
                    if [[ -f "$patch_file" ]]; then
                        print_status "Applying ${category}: $(basename "$patch_file")"
                        cd "$SRC_DIR"
                        if patch -p1 --forward --no-backup-if-mismatch < "$patch_file" 2>/dev/null; then
                            ((applied++))
                        else
                            print_warning "Patch partially applied: $(basename "$patch_file")"
                            ((failed++))
                        fi
                    fi
                done
            fi
        done
    fi

    print_status "Austere patches: ${applied} applied, ${failed} with warnings"
}

prune_binaries() {
    print_status "Pruning bundled binaries..."

    if [[ -x "${UNGOOGLED_DIR}/utils/prune_binaries.py" ]]; then
        local prune_list="${UNGOOGLED_DIR}/pruning.list"
        if [[ -f "$prune_list" ]]; then
            python3 "${UNGOOGLED_DIR}/utils/prune_binaries.py" "$SRC_DIR" "$prune_list" || {
                print_warning "Some binary pruning may have failed"
            }
        fi
    fi
}

main() {
    print_status "Austere Browser - Patch Application"
    print_status "===================================="

    if [[ ! -d "$SRC_DIR" ]]; then
        print_error "Chromium source not found at $SRC_DIR"
        print_error "Run fetch.sh first."
        exit 1
    fi

    prune_binaries
    apply_ungoogled_patches
    apply_domain_substitution
    apply_austere_patches

    print_status "Patch application complete!"
    print_status ""
    print_status "Next step: Run build.sh"
}

main "$@"
