#!/bin/bash

set -euo pipefail

count_executable_lines() {
    local file_path=$1

    LC_ALL=C awk '
        BEGIN { in_continuation = 0 }
        /^[[:space:]]*$/ { in_continuation = 0; next }
        /^[[:space:]]*#/ { in_continuation = 0; next }
        /^[[:space:]]*(fi|done|esac|else|elif|;;|\}|[[:alnum:]_]+\(\)[[:space:]]*\{|function[[:space:]]+[[:alnum:]_]+[[:space:]]*\{)[[:space:]]*$/ { in_continuation = 0; next }
        /^[[:space:]]*done[[:space:]]+<<</ { in_continuation = 0; next }
        in_continuation == 1 {
            if (/\\[[:space:]]*$/) { next }
            in_continuation = 0
            next
        }
        /\\[[:space:]]*$/ { count += 1; in_continuation = 1; next }
        { count += 1 }
        END { print count + 0 }
    ' "$file_path"
}

coverage_percent() {
    local covered_lines=$1
    local executable_lines=$2

    LC_ALL=C awk -v covered="$covered_lines" -v total="$executable_lines" '
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

    LC_ALL=C SOURCE_FILE_LIST="$source_list" awk '
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