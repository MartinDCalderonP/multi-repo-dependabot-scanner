#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/i18n.sh"

assert_equals "alert" "$(pluralize 1 alert)" "singular pluralize"
assert_equals "alerts" "$(pluralize 2 alert)" "plural pluralize"
assert_equals "fox" "$(pluralize 1 fox foxen)" "custom plural"
assert_equals "foxen" "$(pluralize 5 fox foxen)" "custom plural count 5"

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

: > "$pnpm_lock"
: > "$pnpm_workspace"
no_ctx_output="$(cleanup_pnpm_files '' 2>&1)"
case "$no_ctx_output" in
    *"Removed: pnpm-lock.yaml pnpm-workspace.yaml"*) : ;;
    *) printf 'Unexpected no-ctx output: %s\n' "$no_ctx_output" >&2; exit 1 ;;
esac

rm -f "$pnpm_lock" "$pnpm_workspace"
result=0
cleanup_pnpm_files 'test' || result=$?
assert_equals "0" "$result" "no files cleanup returns 0"

: > "$pnpm_lock"
only_lock_output="$(cleanup_pnpm_files 'test')"
assert_equals "" "$only_lock_output" "only lockfile no stdout"
rm -f "$pnpm_lock"

success_output="$(print_success 'all good')"
assert_contains "$success_output" "all good" "print_success"

warning_output="$(print_warning 'be careful')"
assert_contains "$warning_output" "be careful" "print_warning"

info_output="$(print_info 'FYI')"
assert_contains "$info_output" "FYI" "print_info"

error_output="$(print_error 'oops')"
assert_contains "$error_output" "oops" "print_error"

separator_output="$(print_separator)"
assert_contains "$separator_output" "═══" "print_separator"

git_dir=$(mktemp -d)
(
    cd "$git_dir"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    assert_equals "1" "$(has_uncommitted_changes && echo 1 || echo 0)" "uncommitted after init"
    echo "file" > test.txt
    git add test.txt
    assert_equals "1" "$(has_uncommitted_changes && echo 1 || echo 0)" "uncommitted after add"
    git commit -q -m "init"
    assert_equals "0" "$(has_uncommitted_changes && echo 1 || echo 0)" "clean after commit"
)
rm -rf "$git_dir"

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile" "$pnpm_lock" "$pnpm_workspace"' EXIT

echo 'y' > "$tmpfile"
exec 3< "$tmpfile"
prompt_yes_no "Continue?" MYVAR 3
exec 3<&-
assert_equals "true" "$MYVAR" "prompt_yes_no y"

echo 'n' > "$tmpfile"
exec 3< "$tmpfile"
prompt_yes_no "Continue?" MYVAR_N 3 || true
exec 3<&-
assert_equals "false" "$MYVAR_N" "prompt_yes_no n"

printf 'bad\ny\n' > "$tmpfile"
exec 3< "$tmpfile"
prompt_yes_no "Continue?" MYVAR_INVALID 3
exec 3<&-
assert_equals "true" "$MYVAR_INVALID" "prompt_yes_no invalid then y"

printf 'OK\n'
