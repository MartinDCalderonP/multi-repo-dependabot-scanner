#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/formatters.sh"

assert_contains() {
    local haystack=$1
    local needle=$2
    local label=$3

    case "$haystack" in
        *"$needle"*) : ;;
        *) printf 'Assertion failed for %s\nMissing: %s\n' "$label" "$needle" >&2; exit 1 ;;
    esac
}

badge_output="$(print_severity_badge high 'Issue found')"
assert_contains "$badge_output" "[HIGH]" "high badge"

alert_output="$(display_alert '⚠' medium 'Issue found' 'foo' '1.2.3')"
assert_contains "$alert_output" "foo → v1.2.3" "version formatting"

printf 'OK\n'
