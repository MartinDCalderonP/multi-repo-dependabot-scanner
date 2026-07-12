#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

git() { return 0; }
commit_fixes() { echo "commit_fixes:called"; return 0; }
push_branch() { echo "push_branch:called"; return 0; }
create_pull_request() { echo "https://github.com/test/pr/1"; return 0; }
checkout_main_branch() { echo "checkout_main_branch:called"; return 0; }

print_warning() { echo "WARNING:$1"; }
print_info() { echo "INFO:$1"; }
print_success() { echo "SUCCESS:$1"; }
t() { echo "$1"; }

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/commit-workflow.sh"

repos_fixed=0
output="$(handle_commit_workflow 2 'fix/branch' 'foo,bar' pnpm)"
assert_contains "$output" "SUCCESS:" "updates applied"
assert_contains "$output" "commit_fixes:called" "commit_fixes called"
assert_contains "$output" "checkout_main_branch:called" "checkout called"
assert_contains "$output" "https://github.com/test/pr/1" "PR created"

output="$(execute_full_workflow 2 'fix/branch' 'foo,bar' pnpm)"
assert_contains "$output" "commit_fixes:called" "commit_fixes in full workflow"
assert_contains "$output" "SUCCESS:" "commit success"
assert_contains "$output" "push_branch:called" "push called"
assert_contains "$output" "checkout_main_branch:called" "checkout at end"

commit_fixes() { return 1; }
output="$(execute_full_workflow 2 'fix/branch' 'foo,bar' pnpm 2>&1 || true)"
assert_contains "$output" "checkout_main_branch:called" "checkout on commit failure"
assert_not_contains "$output" "push_branch:called" "no push on commit failure"

commit_fixes() { return 0; }
push_branch() { return 1; }
output="$(execute_full_workflow 2 'fix/branch' 'foo,bar' pnpm 2>&1 || true)"
assert_contains "$output" "WARNING:" "push failure warning"

push_branch() { return 0; }
create_pull_request() { return 1; }
output="$(execute_full_workflow 2 'fix/branch' 'foo,bar' pnpm 2>&1 || true)"
assert_contains "$output" "WARNING:" "PR failure warning"

printf 'OK\n'
