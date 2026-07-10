#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/i18n.sh"

assert_equals() {
    local expected=$1
    local actual=$2
    local label=$3

    if [ "$expected" != "$actual" ]; then
        printf 'Assertion failed for %s\nExpected: %s\nActual:   %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    fi
}

assert_equals "alert" "$(pluralize 1 alert)" "singular pluralize"
assert_equals "alerts" "$(pluralize 2 alert)" "plural pluralize"

pnpm_lock="$SCRIPT_DIR/pnpm-lock.yaml"
pnpm_workspace="$SCRIPT_DIR/pnpm-workspace.yaml"
trap 'rm -f "$pnpm_lock" "$pnpm_workspace"' EXIT
: > "$pnpm_lock"
: > "$pnpm_workspace"
cleanup_output="$(cleanup_pnpm_files 'test context' 2>&1)"
case "$cleanup_output" in
    *"Removed test context: pnpm-lock.yaml pnpm-workspace.yaml"*) : ;;
    *) printf 'Unexpected cleanup output: %s\n' "$cleanup_output" >&2; exit 1 ;;
esac

printf 'OK\n'
