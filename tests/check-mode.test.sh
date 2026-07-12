#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

get_severity_counts() { echo "1 2 3 4"; }

display_severity_summary() {
    printf 'severity:%s:%s:%s:%s:%s:%s:%s:%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
}

display_auto_fixable_alerts() { echo "auto_fixable:$1"; }

display_breaking_alerts() { echo "breaking:$1"; }

display_blocked_alerts() { echo "blocked:$1"; }

display_unfixable_alerts() { echo "unfixable:$1"; }

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/check-mode.sh"

alerts_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}},"security_advisory":{"severity":"high"},"is_auto_fixable":true},
  {"dependency":{"package":{"name":"bar"}},"security_vulnerability":{"first_patched_version":{"identifier":"2.0.0"}},"security_advisory":{"severity":"critical"},"is_breaking":true},
  {"dependency":{"package":{"name":"baz"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"security_advisory":{"severity":"medium"},"is_blocked":true,"blocked_reason":"security_update_not_possible"}
]'

output="$(display_check_mode "$alerts_json" 1 1 1 1)"

assert_contains "$output" "severity:1:2:3:4:1:1:1:1" "severity summary"
assert_contains "$output" "auto_fixable:" "auto fixable section shown"
assert_contains "$output" "breaking:" "breaking section shown"
assert_contains "$output" "blocked:" "blocked section shown"
assert_contains "$output" "unfixable:" "unfixable section shown"

zero_output="$(display_check_mode "$alerts_json" 0 0 0 0)"
assert_not_contains "$zero_output" "auto_fixable:" "auto fixable hidden when 0"
assert_not_contains "$zero_output" "breaking:" "breaking hidden when 0"
assert_not_contains "$zero_output" "blocked:" "blocked hidden when 0"
assert_not_contains "$zero_output" "unfixable:" "unfixable hidden when 0"

printf 'OK\n'
