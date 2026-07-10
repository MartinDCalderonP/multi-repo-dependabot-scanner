#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

display_alert() {
    printf '%s|%s|%s|%s|%s\n' "$1" "$2" "$3" "$4" "$5"
}

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/lib/alert-lists.sh"

assert_contains() {
    local haystack=$1
    local needle=$2
    local label=$3

    case "$haystack" in
        *"$needle"*) : ;;
        *) printf 'Assertion failed for %s\nMissing: %s\n' "$label" "$needle" >&2; exit 1 ;;
    esac
}

alerts_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}},"security_advisory":{"severity":"high"},"is_auto_fixable":true},
  {"dependency":{"package":{"name":"bar"}},"security_vulnerability":{"first_patched_version":{"identifier":"2.0.0"}},"security_advisory":{"severity":"critical"},"is_breaking":true},
    {"dependency":{"package":{"name":"baz"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"security_advisory":{"severity":"medium"},"is_blocked":true,"blocked_reason":"security_update_not_possible"},
    {"dependency":{"package":{"name":"qux"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"security_advisory":{"severity":"low"}}
]'

auto_output="$(display_auto_fixable_alerts "$alerts_json")"
assert_contains "$auto_output" "foo" "auto fixable alert"

breaking_output="$(display_breaking_alerts "$alerts_json")"
assert_contains "$breaking_output" "bar" "breaking alert"

blocked_output="$(display_blocked_alerts "$alerts_json")"
assert_contains "$blocked_output" "No compatible version available" "blocked heading"

unfixable_output="$(display_unfixable_alerts "$alerts_json")"
assert_contains "$unfixable_output" "qux" "unfixable alert"

printf 'OK\n'