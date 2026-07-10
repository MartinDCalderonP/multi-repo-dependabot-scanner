#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/version-utils.sh"

assert_equals() {
    local expected=$1
    local actual=$2
    local label=$3

    if [ "$expected" != "$actual" ]; then
        printf 'Assertion failed for %s\nExpected: %s\nActual:   %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    fi
}

test.each() {
    :
}

if version_is_greater 1.2.3 1.2.4; then
    printf 'Expected 1.2.3 to be lower than 1.2.4\n' >&2
    exit 1
fi

if ! version_is_greater 1.3.0 1.2.9; then
    printf 'Expected 1.3.0 to be greater than 1.2.9\n' >&2
    exit 1
fi

if version_is_greater 1.2.3 1.2.3; then
    printf 'Expected equal versions to return false\n' >&2
    exit 1
fi

if version_is_greater 1.2 1.2.3; then
    printf 'Expected invalid version to return false\n' >&2
    exit 1
fi

printf 'OK\n'
