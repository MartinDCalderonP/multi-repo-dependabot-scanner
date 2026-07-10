#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

count_executable_lines() {
    local file_path=$1

    awk '
        /^[[:space:]]*$/ { next }
        /^[[:space:]]*#/ { next }
        { count += 1 }
        END { print count + 0 }
    ' "$file_path"
}

coverage_percent() {
    local covered_lines=$1
    local executable_lines=$2

    awk -v covered="$covered_lines" -v total="$executable_lines" '
        BEGIN {
            if (total == 0) {
                print "100.00"
                exit
            }

            printf "%.2f", (covered / total) * 100
        }
    '
}

extract_covered_lines() {
    local trace_file=$1
    shift

    local source_list
    source_list="$(printf '%s\n' "$@")"

    SOURCE_FILE_LIST="$source_list" awk '
        BEGIN {
            source_count = split(ENVIRON["SOURCE_FILE_LIST"], source_files, "\n")

            for (i = 1; i <= source_count; i++) {
                if (source_files[i] != "") {
                    allowed[source_files[i]] = 1
                }
            }
        }

        {
            trace_line = $0
            sub(/^\++/, "", trace_line)

            file_path = trace_line
            sub(/:.*/, "", file_path)

            if (!(file_path in allowed)) {
                next
            }

            line_text = trace_line
            sub(/^[^:]+:/, "", line_text)
            sub(/:.*/, "", line_text)

            if (line_text ~ /^[0-9]+$/) {
                seen[file_path SUBSEP line_text] = 1
            }
        }

        END {
            for (key in seen) {
                print key
            }
        }
    ' "$trace_file"
}

list_source_files() {
    printf '%s\n' "$SCRIPT_DIR/dependabot-manager.sh" "$SCRIPT_DIR"/lib/*.sh
}

run_traced_tests() {
    local trace_file=$1

    : > "$trace_file"

    local test_file
    for test_file in "$SCRIPT_DIR"/tests/*.test.sh; do
        case "$test_file" in
            *coverage.test.sh) continue ;;
        esac

        PS4='+${BASH_SOURCE}:${LINENO}: ' bash -x "$test_file" >/dev/null 2>>"$trace_file"
    done
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

    for source_file in $(list_source_files); do
        source_files+=("$source_file")
    done

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