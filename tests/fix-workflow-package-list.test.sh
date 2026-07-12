#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/version-utils.sh"
source "$SCRIPT_DIR/lib/pnpm-fixes.sh"
source "$SCRIPT_DIR/lib/message-builders.sh"
source "$SCRIPT_DIR/lib/pull-request-body.sh"
source "$SCRIPT_DIR/lib/package-managers.sh"
source "$SCRIPT_DIR/lib/git-operations.sh"
source "$SCRIPT_DIR/lib/fix-workflow.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/tests/fix-workflow.helpers.sh"

pnpm_install_output='dependencies:
- next 16.2.3
+ next 16.2.10
'

expected_pnpm_updates=$'next\t16.2.3\t16.2.10'
actual_pnpm_updates=$(extract_pnpm_update_details "$pnpm_install_output")

package_list_output=$(build_package_list "$actual_pnpm_updates" false)
assert_equals "- next: 16.2.3 -> 16.2.10" "$(printf '%s\n' "$package_list_output" | tail -n 1)" "update list with explicit versions"

reversed_package_details=$'js-yaml\t4.3.0\t4.2.0'
reversed_package_output=$(build_package_list "$reversed_package_details" false)
assert_equals "- js-yaml: 4.2.0 -> 4.3.0" "$(printf '%s\n' "$reversed_package_output" | tail -n 1)" "normalized package list output"

package_list_explicit=$(build_package_list "$expected_pnpm_updates" false)
assert_equals "- next: 16.2.3 -> 16.2.10" "$(printf '%s\n' "$package_list_explicit" | tail -n 1)" "package list with explicit versions"

alerts_json='[
  {
    "dependency": {
      "package": {
        "name": "shell-quote"
      }
    },
    "installed_version": "1.8.3",
    "is_blocked": false,
    "security_vulnerability": {
      "first_patched_version": {
        "identifier": "1.8.4"
      }
    }
  }
]'

prepare_fix_workflow "$alerts_json"
PACKAGE_UPDATE_DETAILS=""
pr_output=$(create_pull_request 1 "shell-quote" "pnpm")

case "$pr_output" in
  *"1.8.3 -> 1.8.4"*) ;;
  *)
    printf 'Assertion failed for pr body versions\nExpected explicit installed/patched versions\n' >&2
    exit 1
    ;;
esac

two_packages_json='[
  {"dependency":{"package":{"name":"foo"}},"installed_version":"1.0.0","is_blocked":false,"security_vulnerability":{"first_patched_version":{"identifier":"1.0.1"}}},
  {"dependency":{"package":{"name":"bar"}},"installed_version":"2.0.0","is_blocked":false,"security_vulnerability":{"first_patched_version":{"identifier":"2.0.1"}}}
]'
prepare_fix_workflow "$two_packages_json"
assert_contains "$FIX_PACKAGE_NAMES" "foo" "multi package foo"
assert_contains "$FIX_PACKAGE_NAMES" "bar" "multi package bar"

blocked_json='[
  {"dependency":{"package":{"name":"foo"}},"installed_version":"1.0.0","is_blocked":false,"security_vulnerability":{"first_patched_version":{"identifier":"1.0.1"}}},
  {"dependency":{"package":{"name":"bar"}},"installed_version":"2.0.0","is_blocked":true,"blocked_reason":"dependabot_timed_out","security_vulnerability":{"first_patched_version":{"identifier":"2.0.1"}}}
]'
prepare_fix_workflow "$blocked_json"
assert_contains "$FIX_PACKAGE_NAMES" "foo" "blocked alert excluded"
assert_not_contains "$FIX_PACKAGE_NAMES" "bar" "blocked bar excluded"

has_uncommitted_changes() { return 0; }
result=0
prepare_fix_workflow "$alerts_json" || result=$?
assert_equals "1" "$result" "prepare returns 1 on uncommitted"

printf 'OK\n'
