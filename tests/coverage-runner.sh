#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/tests/coverage-helpers.sh"

list_source_files() {
    printf '%s\n' "$SCRIPT_DIR/dependabot-manager.sh" "$SCRIPT_DIR"/lib/*.sh
}

run_traced_tests() {
    local trace_file=$1
    local test_failed=0

    : > "$trace_file"

    local test_file
    for test_file in "$SCRIPT_DIR"/tests/*.test.sh; do
        case "$test_file" in
            *coverage.test.sh|*coverage-helpers.test.sh) continue ;;
        esac

        if ! LC_ALL=C PS4='+${BASH_SOURCE}:${LINENO}: ' bash -x "$test_file" >/dev/null 2>>"$trace_file"; then
            test_failed=1
        fi
    done

    return "$test_failed"
}

print_report() {
    local trace_file=$1
    shift

    local source_file
    local executable_lines=0

    for source_file in "$@"; do
        local lines
        lines="$(count_executable_lines "$source_file")"
        executable_lines=$((executable_lines + lines))
    done

    local covered_lines
    covered_lines="$(extract_covered_lines "$trace_file" "$@" | awk 'NF { count += 1 } END { print count + 0 }')"

    local percent
    percent="$(coverage_percent "$covered_lines" "$executable_lines")"

    printf 'Coverage: %s%% (%s/%s lines)\n' "$percent" "$covered_lines" "$executable_lines"
}

main() {
    local trace_file
    local source_files=()
    local source_file

    while IFS= read -r source_file; do
        source_files+=("$source_file")
    done < <(list_source_files)

    trace_file="${COVERAGE_TRACE_FILE:-}"

    if [ -z "$trace_file" ]; then
        COVERAGE_TEMP_TRACE_FILE="$(mktemp)"
        trap 'rm -f "${COVERAGE_TEMP_TRACE_FILE:-}"' EXIT
        run_traced_tests "$COVERAGE_TEMP_TRACE_FILE"
        trace_file="$COVERAGE_TEMP_TRACE_FILE"
    fi

    print_report "$trace_file" "${source_files[@]}"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi