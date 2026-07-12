#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FIX_PACKAGE_NAMES="foo,bar"

detect_package_manager() { echo "pnpm"; }
find_monorepo_subdirs() { echo ""; }
get_fix_reason_counts() { echo "1 0 0"; }
prepare_fix_workflow() { return 0; }
create_fix_branch() { echo "fix/branch"; }
finalize_fix_workflow() { echo "finalize:called:$1:$2:$3:$4"; }
apply_fixes() { echo "apply_fixes:called:$1"; }
has_uncommitted_changes() { return 1; }
_checkout_called=""
checkout_main_branch() { _checkout_called="yes"; }
delete_branch() { _checkout_called="deleted:$1"; }
print_warning() { echo "WARNING:$1"; }
print_info() { echo "INFO:$1"; }
print_success() { echo "SUCCESS:$1"; }
t() { echo "$1"; }

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/fix-mode.sh"

no_fix_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"security_advisory":{"severity":"medium"},"is_blocked":true,"blocked_reason":"security_update_not_possible"}
]'
output="$(run_fix_mode "$no_fix_json" 1 0 || true)"
assert_contains "$output" "WARNING:" "no fix candidates warning"

alerts_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}},"security_advisory":{"severity":"high"},"is_auto_fixable":true}
]'
output="$(run_fix_mode "$alerts_json" 1 1 || true)"
assert_contains "$output" "finalize:called:" "finalize called"
assert_contains "$output" "apply_fixes:called:" "apply_fixes called"

detect_package_manager() { echo "unknown"; }
find_monorepo_subdirs() { echo ""; }
output="$(run_fix_mode "$alerts_json" 1 1 || true)"
assert_contains "$output" "WARNING:" "no PM detected warning"

detect_package_manager() { echo "unknown"; }
subdir1=$(mktemp -d)
subdir2=$(mktemp -d)
find_monorepo_subdirs() { printf '%s\n%s\n' "$subdir1" "$subdir2"; }
_orig_detect=1
is_monorepo_subdir() { [ "$PWD" = "$subdir1" ] || [ "$PWD" = "$subdir2" ]; }
detect_package_manager() {
    if is_monorepo_subdir; then
        echo "pnpm"
    else
        echo "unknown"
    fi
}
output="$(run_fix_mode "$alerts_json" 1 1 || true)"
assert_contains "$output" "finalize:called:" "monorepo finalize"
assert_contains "$output" "apply_fixes:called:" "monorepo apply_fixes"
rm -rf "$subdir1" "$subdir2"

all_blocked_json='[
  {"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"is_blocked":true,"blocked_reason":"manual_review_needed"},
  {"dependency":{"package":{"name":"bar"}},"security_vulnerability":{"first_patched_version":{"identifier":null}},"is_blocked":true,"blocked_reason":"dependabot_timed_out"}
]'
get_fix_reason_counts() { echo "1 1 0"; }
detect_package_manager() { echo "pnpm"; }
find_monorepo_subdirs() { echo ""; }
output="$(run_fix_mode "$all_blocked_json" 2 0 || true)"
assert_contains "$output" "WARNING:" "blocked warning"
assert_contains "$output" "INFO:" "timed out info"

printf 'OK\n'
