#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SPECIFIC_REPO=""
WORKSPACE_DIR=""
MODE="check"
total_repos=0
repos_with_alerts=0
total_alerts=0
total_fixable=0; total_breaking=0; total_unfixable=0; total_blocked=0
repos_fixed=0

git() {
    case "$1" in
        remote) echo "https://github.com/test-org/test-repo.git"; return 0 ;;
    esac
    return 0
}

fetch_open_alerts() {
    echo '[{"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}},"security_advisory":{"severity":"high"}}]'
}

enrich_alerts_with_versions() { echo "$1"; }
enrich_alerts_with_dependabot_status() { echo "$1"; }
calculate_alert_metrics() { echo "1 0 0 0"; }
detect_package_manager() { echo "pnpm"; }
find_monorepo_subdirs() { echo ""; }
print_warning() { echo "WARNING:$1"; }
print_info() { echo "INFO:$1"; }
print_success() { echo "SUCCESS:$1"; }
print_separator() { echo "separator"; }
t() { echo "$1"; }

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/lib/formatters.sh"
source "$SCRIPT_DIR/lib/alert-lists.sh"
source "$SCRIPT_DIR/lib/summaries.sh"
source "$SCRIPT_DIR/lib/check-mode.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/repository-processing.sh"

rc() { repos_with_alerts=0; total_alerts=0; total_fixable=0; total_breaking=0; total_unfixable=0; total_blocked=0; }

mkdir -p /tmp/tw/specific/.git
SPECIFIC_REPO="specific"; WORKSPACE_DIR="/tmp/tw"
output="$(process_repositories || true)"
assert_contains "$output" "separator" "repo header"
rm -rf /tmp/tw

mkdir -p /tmp/tw/nogit
SPECIFIC_REPO="nogit"; WORKSPACE_DIR="/tmp/tw"
output="$(process_repositories || true)"
assert_contains "$output" "WARNING:" "missing .git"
rm -rf /tmp/tw

mkdir -p /tmp/tw/a/.git /tmp/tw/b/.git
SPECIFIC_REPO=""; WORKSPACE_DIR="/tmp/tw"; rc
output="$(process_repositories || true)"
assert_contains "$output" "Repository:" "multi repo"
rm -rf /tmp/tw

mkdir -p /tmp/tw/empty/.git
SPECIFIC_REPO=""; WORKSPACE_DIR="/tmp/tw"; rc
fetch_open_alerts() { echo "[]"; }
output="$(process_repositories || true)"
assert_contains "$output" "No alerts" "no alerts"
rm -rf /tmp/tw

mkdir -p /tmp/tw/fix/.git
SPECIFIC_REPO=""; WORKSPACE_DIR="/tmp/tw"; rc; MODE="fix"
fetch_open_alerts() {
    echo '[{"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}},"security_advisory":{"severity":"high"}}]'
}
run_fix_mode() { echo "fix:called"; }
output="$(process_repositories || true)"
assert_contains "$output" "fix:called" "fix mode"
rm -rf /tmp/tw

mkdir -p /tmp/tw/mono/.git
SPECIFIC_REPO="mono"; WORKSPACE_DIR="/tmp/tw"; rc; MODE="check"
_n=0
detect_package_manager() { _n=$((_n + 1)); [ "$_n" -le 1 ] && echo "unknown" || echo "pnpm"; }
find_monorepo_subdirs() { echo "/tmp/tw/mono"; }
output="$(process_repositories || true)"
assert_contains "$output" "separator" "monorepo"
rm -rf /tmp/tw

printf 'OK\n'
