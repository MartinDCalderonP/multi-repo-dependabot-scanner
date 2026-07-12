#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_info() { return 0; }
print_success() { return 0; }
print_warning() { return 0; }
print_error() { return 0; }
get_github_token() { echo "dummy_token"; }
get_org() { echo "test-org"; }
WORKSPACE_DIR="/tmp/test-workspace"
REPOS=()

source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/dependabot-manager.sh"

process_repositories() {
    total_repos=2
    repos_with_alerts=1
    total_alerts=3
    total_fixable=2
    total_breaking=1
    total_unfixable=1
    total_blocked=0
}

display_final_summary() {
    echo "repos=$1 alerts=$3 fix=$4 mode=$7"
}

MODE="check"
SPECIFIC_REPO=""
created_pr_urls=()
total_repos=0 repos_with_alerts=0 total_alerts=0
total_fixable=0 total_breaking=0 total_unfixable=0
total_blocked=0 repos_fixed=0

output="$(main)"
assert_contains "$output" "repos=2" "process_repositories called"
assert_contains "$output" "mode=check" "check mode"

SPECIFIC_REPO="my-org/my-repo"
created_pr_urls=()
total_repos=0 repos_with_alerts=0 total_alerts=0
total_fixable=0 total_breaking=0 total_unfixable=0
total_blocked=0 repos_fixed=0

output="$(main)"
assert_contains "$output" "my-org/my-repo" "shows repo name"

created_pr_urls=("https://github.com/org/repo/pull/1" "https://github.com/org/repo/pull/2")
SPECIFIC_REPO=""
total_repos=0 repos_with_alerts=0 total_alerts=0
total_fixable=0 total_breaking=0 total_unfixable=0
total_blocked=0 repos_fixed=0
output="$(main)"
assert_contains "$output" "pull/1" "first PR URL"
assert_contains "$output" "pull/2" "second PR URL"

created_pr_urls=()
SPECIFIC_REPO=""
total_repos=0 repos_with_alerts=0 total_alerts=0
total_fixable=0 total_breaking=0 total_unfixable=0
total_blocked=0 repos_fixed=0
output="$(main)"
assert_not_contains "$output" "pr_list_title" "no PR list when empty"

printf 'OK\n'
