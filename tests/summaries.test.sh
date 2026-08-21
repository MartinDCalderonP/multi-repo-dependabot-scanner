#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/time-utils.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/summaries.sh"

test_format_duration_cases() {
    local -a cases=(
        "0:0s"
        "45:45s"
        "59:59s"
        "60:1m"
        "187:3m 7s"
        "3600:1h"
        "3725:1h 2m 5s"
    )
    local case_item
    local total_seconds
    local expected

    for case_item in "${cases[@]}"; do
        total_seconds="${case_item%%:*}"
        expected="${case_item#*:}"
        assert_equals "$(format_duration "$total_seconds")" "$expected" \
            "format_duration $total_seconds"
    done
}

test_format_duration_cases

current_epoch=$(date +%s)

summary_output="$(display_final_summary 3 2 5 2 1 1 check 0 1 "$current_epoch")"
assert_contains "$summary_output" "Total repositories: 3" "summary total repos"
assert_contains "$summary_output" "Total alerts: 5" "summary total alerts"
assert_contains "$summary_output" "Blocked by Dependabot" "summary blocked"
assert_contains "$summary_output" "Finished at:" "summary finished at label"
assert_contains "$summary_output" "(duration:" "summary duration label"

fix_output="$(display_final_summary 5 4 10 8 1 1 fix 3 0 "$current_epoch")"
assert_contains "$fix_output" "Total repositories: 5" "fix mode total repos"
assert_contains "$fix_output" "Updated repositories: 3" "fix mode repos fixed"
assert_contains "$fix_output" "Finished at:" "fix mode finished at label"

both_output="$(display_final_summary 4 3 8 5 2 1 both 2 0 "$current_epoch")"
assert_contains "$both_output" "Auto-fixable" "both mode has check stats"
assert_contains "$both_output" "Updated repositories: 2" "both mode repos fixed"
assert_contains "$both_output" "Finished at:" "both mode finished at label"

repo_output="$(display_repo_header 'test-org' 'test-repo' 5)"
assert_contains "$repo_output" "test-org" "repo owner"
assert_contains "$repo_output" "test-repo" "repo name"
assert_contains "$repo_output" "5" "alerts count"

sev_output="$(display_severity_summary 2 3 4 1 5 1 2 3)"
assert_contains "$sev_output" "2" "critical count"
assert_contains "$sev_output" "3" "high count"
assert_contains "$sev_output" "4" "medium count"
assert_contains "$sev_output" "1" "low count"
assert_contains "$sev_output" "5" "auto fixable count"
assert_contains "$sev_output" "1 require manual review" "manual review count"
assert_contains "$sev_output" "3 blocked by Dependabot" "blocked count"
assert_contains "$sev_output" "2 without patched version" "unfixable count"

printf 'OK\n'
