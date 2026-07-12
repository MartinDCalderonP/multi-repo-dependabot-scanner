#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/version-utils.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"

test_cases=(
    "1.2.3 1.2.4 false 1.2.3 lower than 1.2.4"
    "1.3.0 1.2.9 true 1.3.0 greater than 1.2.9"
    "1.2.3 1.2.3 false equal versions return false"
    "1.2 1.2.3 false invalid version return false"
    "2.0.0 1.9.9 true 2.0.0 greater than 1.9.9"
    "1.10.0 1.9.0 true 1.10.0 greater than 1.9.0"
    "10.0.0 9.99.99 true 10.0.0 greater than 9.99.99"
    "'' 1.0.0 false empty version return false"
    "1.0.0 '' false empty version return false"
    "0.2.0 0.1.0 true 0.2.0 greater than 0.1.0"
    "0.1.0 0.2.0 false 0.1.0 not greater than 0.2.0"
    "1.0.0 2.0.0 false 1.0.0 not greater than 2.0.0"
    "1.5.0 1.6.0 false 1.5.0 not greater than 1.6.0"
)

for case_line in "${test_cases[@]}"; do
    read -r va vb expected label <<< "$case_line"

    if [ "$expected" = "true" ]; then
        if ! version_is_greater "$va" "$vb"; then
            printf 'Expected %s to be greater than %s (%s)\n' "$va" "$vb" "$label" >&2
            exit 1
        fi
    else
        if version_is_greater "$va" "$vb"; then
            printf 'Expected %s to not be greater than %s (%s)\n' "$va" "$vb" "$label" >&2
            exit 1
        fi
    fi
done

printf 'OK\n'
