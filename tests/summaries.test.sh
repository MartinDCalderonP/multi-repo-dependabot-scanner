#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/summaries.sh"

summary_output="$(display_final_summary 3 2 5 2 1 1 check 0 1)"
assert_contains "$summary_output" "Total repositories: 3" "summary total repos"
assert_contains "$summary_output" "Total alerts: 5" "summary total alerts"
assert_contains "$summary_output" "Blocked by Dependabot" "summary blocked"

fix_output="$(display_final_summary 5 4 10 8 1 1 fix 3 0)"
assert_contains "$fix_output" "Total repositories: 5" "fix mode total repos"
assert_contains "$fix_output" "Updated repositories: 3" "fix mode repos fixed"

both_output="$(display_final_summary 4 3 8 5 2 1 both 2 0)"
assert_contains "$both_output" "Auto-fixable" "both mode has check stats"
assert_contains "$both_output" "Updated repositories: 2" "both mode repos fixed"

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
