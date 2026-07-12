#!/bin/bash

set -euo pipefail

assert_equals() {
    local expected=$1
    local actual=$2
    local label=$3

    if [ "$expected" != "$actual" ]; then
        printf 'Assertion failed for %s\nExpected: %s\nActual:   %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    fi
}

assert_contains() {
    local haystack=$1
    local needle=$2
    local label=$3

    case "$haystack" in
        *"$needle"*) : ;;
        *) printf 'Assertion failed for %s\nMissing: %s\n' "$label" "$needle" >&2; exit 1 ;;
    esac
}

assert_not_contains() {
    local haystack=$1
    local needle=$2
    local label=$3

    case "$haystack" in
        *"$needle"*) printf 'Assertion failed for %s\nUnexpected: %s\n' "$label" "$needle" >&2; exit 1 ;;
        *) : ;;
    esac
}
