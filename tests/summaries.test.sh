#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/summaries.sh"

assert_contains() {
    local haystack=$1
    local needle=$2
    local label=$3

    case "$haystack" in
        *"$needle"*) : ;;
        *) printf 'Assertion failed for %s\nMissing: %s\n' "$label" "$needle" >&2; exit 1 ;;
    esac
}

summary_output="$(display_final_summary 3 2 5 2 1 1 check 0 1)"
assert_contains "$summary_output" "Total repositories: 3" "summary total repos"
assert_contains "$summary_output" "Total alerts: 5" "summary total alerts"
assert_contains "$summary_output" "Blocked by Dependabot" "summary blocked"

printf 'OK\n'