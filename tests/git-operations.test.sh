#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FIXED_BRANCH_SUFFIX="20250101-120000"
_git_mock_diff_cached_count=0

date() { echo "$FIXED_BRANCH_SUFFIX"; }
gh() { echo "https://github.com/test/repo/pull/1"; }
print_warning() { echo "WARNING:$1"; }
print_info() { echo "INFO:$1"; }
print_success() { echo "SUCCESS:$1"; }
t() { echo "$1"; }

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/version-utils.sh"
source "$SCRIPT_DIR/lib/message-builders.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/pull-request-body.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/tests/git-operations.helpers.sh"
source "$SCRIPT_DIR/lib/git-operations.sh"

build_git_mock "refs/remotes/origin/main"
branch="$(get_default_branch)"
assert_equals "main" "$branch" "default branch"

build_git_mock "" match "main"
main_branch="$(get_default_branch)"
assert_equals "main" "$main_branch" "show-ref fallback to main"

build_git_mock "" match "master"
master_branch="$(get_default_branch)"
assert_equals "master" "$master_branch" "show-ref fallback to master"

build_git_mock "" match "develop"
develop_branch="$(get_default_branch)"
assert_equals "develop" "$develop_branch" "show-ref fallback to develop"

build_git_mock "" fail "" 0 0 "feature-branch"
current_branch="$(get_default_branch)"
assert_equals "feature-branch" "$current_branch" "show-current fallback"

build_git_mock "refs/remotes/origin/main" fail "" 1
new_branch="$(create_fix_branch 'foo,bar')"
assert_contains "$new_branch" "fix/dependabot-foo-bar-" "branch name prefix"

build_git_mock "refs/remotes/origin/main" fail "" 1 1
existing_branch="$(create_fix_branch 'baz')"
assert_contains "$existing_branch" "fix/dependabot-baz-" "existing branch checkout"

build_git_mock "refs/remotes/origin/main"
checkout_main_branch
discard_changes
delete_branch "fix/test-branch"

_git_mock_diff_cached_count=0
output="$(commit_fixes 2 'foo,bar' || true)"
assert_contains "$output" "no_staged_changes" "no staged changes warning"

_git_mock_diff_cached_count=1
output="$(commit_fixes 2 'foo,bar' || true)"

PACKAGE_VERSION_DETAILS=$'foo\t1.0.0\t1.1.0'
PACKAGE_UPDATE_DETAILS=$'foo\t1.0.0\t1.1.0'
created_pr_urls=()
export PACKAGE_VERSION_DETAILS PACKAGE_UPDATE_DETAILS created_pr_urls
output="$(create_pull_request 2 'foo' pnpm || true)"
assert_contains "$output" "https://github.com/test/repo/pull/1" "PR URL"

gh() {
    case "$1" in
        pr) echo "error: could not create PR"; return 1 ;;
    esac
    return 0
}
created_pr_urls=()
export created_pr_urls
output="$(create_pull_request 2 'foo' pnpm || true)"
case "$output" in
    *"pull/"*) printf 'FAIL: non-https PR URL should not be added\n' >&2; exit 1 ;;
    *) : ;;
esac

gh() { echo "https://github.com/test/repo/pull/1"; }
push_branch "fix/test"

printf 'OK\n'
