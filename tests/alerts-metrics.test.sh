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
metrics="$(calculate_alert_metrics "$enriched" 4)"
assert_equals "2 0 1 1" "$metrics" "alert metrics"

reasons="$(get_fix_reason_counts "$enriched")"
assert_equals "0 0 1" "$reasons" "fix reason counts"

severity="$(get_severity_counts "$enriched")"
assert_equals "1 1 1 1" "$severity" "severity counts"

empty_json='[]'
empty_metrics="$(calculate_alert_metrics "$empty_json" 0)"
assert_equals "0 0 0 0" "$empty_metrics" "empty metrics"

empty_severity="$(get_severity_counts "$empty_json")"
assert_equals "0 0 0 0" "$empty_severity" "empty severity"

timed_out_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}},"security_advisory":{"severity":"high"},"is_blocked":true,"blocked_reason":"dependabot_timed_out"}
]'
timed_out_reasons="$(get_fix_reason_counts "$timed_out_json")"
assert_equals "0 1 0" "$timed_out_reasons" "timed out count"

manual_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}},"security_advisory":{"severity":"high"},"is_blocked":true,"blocked_reason":"security_update_not_possible"}
]'
manual_reasons="$(get_fix_reason_counts "$manual_json")"
assert_equals "1 0 0" "$manual_reasons" "manual review count"

no_patch_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"security_advisory":{"severity":"medium"},"is_blocked":true,"blocked_reason":"security_update_not_possible"}
]'
no_patch_reasons="$(get_fix_reason_counts "$no_patch_json")"
assert_equals "0 0 1" "$no_patch_reasons" "blocked without patch"

multi_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"2.0.0"}},"security_advisory":{"severity":"high"}},
  {"dependency":{"package":{"name":"bar"}},"security_vulnerability":{"first_patched_version":{"identifier":"0.4.3"}},"security_advisory":{"severity":"medium"}}
]'
multi_enriched="$(enrich_alerts_with_versions "$multi_json" pnpm)"
multi_metrics="$(calculate_alert_metrics "$multi_enriched" 2)"
assert_equals "1 1 0 0" "$multi_metrics" "multi metrics auto+breaking"

single_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.2.4"}},"security_advisory":{"severity":"critical"}}
]'
single_severity="$(get_severity_counts "$single_json")"
assert_equals "1 0 0 0" "$single_severity" "single critical"

blocked_timed_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}},"security_advisory":{"severity":"high"},"is_blocked":true,"blocked_reason":"dependabot_timed_out"},
  {"dependency":{"package":{"name":"bar"}},"security_vulnerability":{"first_patched_version":{"identifier":"2.0.0"}},"security_advisory":{"severity":"medium"},"is_blocked":true,"blocked_reason":"other_reason"}
]'
bt_enriched="$(enrich_alerts_with_versions "$blocked_timed_json" pnpm)"
bt_metrics="$(calculate_alert_metrics "$bt_enriched" 2)"
assert_equals "0 1 0 0" "$bt_metrics" "blocked timed_out not counted as blocked"

printf 'OK\n'
