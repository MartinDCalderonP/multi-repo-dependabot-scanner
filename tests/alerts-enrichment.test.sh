#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

get_installed_version() {
    case "$2" in
        foo) echo "1.2.3" ;;
        bar) echo "0.4.2" ;;
        baz) echo "2.1.0" ;;
        tinylib) echo "0.4.3" ;;
    esac
}

source "$SCRIPT_DIR/lib/version-utils.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/alerts.sh"

alerts_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.2.4"}},"security_advisory":{"severity":"high"}},
  {"dependency":{"package":{"name":"bar"}},"security_vulnerability":{"first_patched_version":{"identifier":"0.4.3"}},"security_advisory":{"severity":"medium"}},
  {"dependency":{"package":{"name":"baz"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"security_advisory":{"severity":"critical"}},
    {"dependency":{"package":{"name":"qux"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"security_advisory":{"severity":"low"},"is_blocked":true,"blocked_reason":"security_update_not_possible"}
]'

enriched="$(enrich_alerts_with_versions "$alerts_json" pnpm)"
assert_equals "1.2.3" "$(printf '%s' "$enriched" | jq -r '.[0].installed_version')" "installed version foo"
assert_equals "0.4.2" "$(printf '%s' "$enriched" | jq -r '.[1].installed_version')" "installed version bar"

assert_equals "true" "$(printf '%s' "$enriched" | jq -r '.[0].is_auto_fixable')" "foo is auto fixable (1.2.3→1.2.4)"
assert_equals "false" "$(printf '%s' "$enriched" | jq -r '.[0].is_breaking')" "foo not breaking"
assert_equals "true" "$(printf '%s' "$enriched" | jq -r '.[1].is_auto_fixable')" "bar is auto fixable (0.4.2→0.4.3)"
assert_equals "false" "$(printf '%s' "$enriched" | jq -r '.[1].is_breaking')" "bar not breaking"
assert_equals "false" "$(printf '%s' "$enriched" | jq -r '.[2].is_auto_fixable')" "baz not auto fixable (null patch)"
assert_equals "false" "$(printf '%s' "$enriched" | jq -r '.[2].is_breaking')" "baz not breaking (null patch)"
assert_equals "1" "$(printf '%s' "$enriched" | jq -r '.[0].patched_major')" "foo patched major"
assert_equals "1" "$(printf '%s' "$enriched" | jq -r '.[0].current_major')" "foo current major"

zero_x_json='[
  {"dependency":{"package":{"name":"tinylib"}},"security_vulnerability":{"first_patched_version":{"identifier":"0.4.2"}},"security_advisory":{"severity":"medium"}}
]'
zero_enriched="$(enrich_alerts_with_versions "$zero_x_json" pnpm)"
assert_equals "true" "$(printf '%s' "$zero_enriched" | jq -r '.[0].is_auto_fixable')" "0.x auto fixable (0.4.3→0.4.2)"
assert_equals "false" "$(printf '%s' "$zero_enriched" | jq -r '.[0].is_breaking')" "0.x not breaking"

zero_break_json='[
  {"dependency":{"package":{"name":"tinylib"}},"security_vulnerability":{"first_patched_version":{"identifier":"0.5.0"}},"security_advisory":{"severity":"high"}}
]'
zero_break_enriched="$(enrich_alerts_with_versions "$zero_break_json" pnpm)"
assert_equals "false" "$(printf '%s' "$zero_break_enriched" | jq -r '.[0].is_auto_fixable')" "0.x not auto fixable (0.4.2→0.5.0)"
assert_equals "true" "$(printf '%s' "$zero_break_enriched" | jq -r '.[0].is_breaking')" "0.x breaking"

missing_ver_json='[
  {"dependency":{"package":{"name":"unknown_pkg"}},"security_vulnerability":{"first_patched_version":{"identifier":"3.0.0"}},"security_advisory":{"severity":"high"}}
]'
missing_enriched="$(enrich_alerts_with_versions "$missing_ver_json" pnpm)"
assert_equals "null" "$(printf '%s' "$missing_enriched" | jq -r '.[0].installed_version')" "missing version is null"
assert_equals "2" "$(printf '%s' "$missing_enriched" | jq -r '.[0].current_major')" "missing version current_major = patched_major-1"
assert_equals "false" "$(printf '%s' "$missing_enriched" | jq -r '.[0].is_auto_fixable')" "missing version not auto fixable (major -1)"
assert_equals "true" "$(printf '%s' "$missing_enriched" | jq -r '.[0].is_breaking')" "missing version is breaking"

printf 'OK\n'
