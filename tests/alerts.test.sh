#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

get_installed_version() {
    case "$2" in
        foo) echo "1.2.3" ;;
        bar) echo "0.4.2" ;;
        baz) echo "2.1.0" ;;
    esac
}

source "$SCRIPT_DIR/lib/version-utils.sh"
source "$SCRIPT_DIR/lib/alerts.sh"

assert_equals() {
    local expected=$1
    local actual=$2
    local label=$3

    [ "$expected" = "$actual" ] || { printf 'Assertion failed for %s\nExpected: %s\nActual:   %s\n' "$label" "$expected" "$actual" >&2; exit 1; }
}

alerts_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.2.4"}},"security_advisory":{"severity":"high"}},
  {"dependency":{"package":{"name":"bar"}},"security_vulnerability":{"first_patched_version":{"identifier":"0.4.3"}},"security_advisory":{"severity":"medium"}},
  {"dependency":{"package":{"name":"baz"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"security_advisory":{"severity":"critical"}},
    {"dependency":{"package":{"name":"qux"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"security_advisory":{"severity":"low"},"is_blocked":true,"blocked_reason":"security_update_not_possible"}
]'

enriched="$(enrich_alerts_with_versions "$alerts_json" pnpm)"
assert_equals "1.2.3" "$(printf '%s' "$enriched" | jq -r '.[0].installed_version')" "installed version foo"
assert_equals "0.4.2" "$(printf '%s' "$enriched" | jq -r '.[1].installed_version')" "installed version bar"

metrics="$(calculate_alert_metrics "$enriched" 4)"
assert_equals "2 0 1 1" "$metrics" "alert metrics"

reasons="$(get_fix_reason_counts "$enriched")"
assert_equals "0 0 1" "$reasons" "fix reason counts"

severity="$(get_severity_counts "$enriched")"
assert_equals "1 1 1 1" "$severity" "severity counts"

printf 'OK\n'