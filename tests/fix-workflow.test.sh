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
source "$SCRIPT_DIR/tests/fix-workflow.helpers.sh"

cat > pnpm-lock.yaml <<'EOF'
importers:
  .:
    dependencies:
      js-yaml:
        specifier: ^4.1.1
        version: 4.1.1
packages:
  /js-yaml@4.1.1:
    resolution: {integrity: sha512-test}
EOF

trap 'rm -f pnpm-lock.yaml' EXIT

  pnpm_install_output='dependencies:
  - next 16.2.3
  + next 16.2.10
  '

  expected_pnpm_updates=$'next\t16.2.3\t16.2.10'
  actual_pnpm_updates=$(extract_pnpm_update_details "$pnpm_install_output")

  assert_equals "$expected_pnpm_updates" "$actual_pnpm_updates" "pnpm update details"

  assert_equals "4.1.1" "$(get_pnpm_installed_version "js-yaml")" "pnpm installed version"

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

assert_equals "shell-quote" "$FIX_PACKAGE_NAMES" "package names"
assert_equals $'shell-quote\t1.8.3\t1.8.4' "$PACKAGE_VERSION_DETAILS" "package version details"
assert_equals "- shell-quote: 1.8.3 -> 1.8.4" "$(build_package_list "$PACKAGE_VERSION_DETAILS" | tail -n 1)" "package list output"

package_list_output=$(build_package_list "$PACKAGE_VERSION_DETAILS" false)
assert_equals "- shell-quote: 1.8.3 -> 1.8.4" "$(printf '%s\n' "$package_list_output" | tail -n 1)" "package list with explicit versions"

reversed_package_details=$'js-yaml\t4.3.0\t4.2.0'
reversed_package_output=$(build_package_list "$reversed_package_details" false)
assert_equals "- js-yaml: 4.2.0 -> 4.3.0" "$(printf '%s\n' "$reversed_package_output" | tail -n 1)" "normalized package list output"

update_list_output=$(build_package_list "$actual_pnpm_updates" false)
assert_equals "- next: 16.2.3 -> 16.2.10" "$(printf '%s\n' "$update_list_output" | tail -n 1)" "update list with explicit versions"

PACKAGE_UPDATE_DETAILS=""
pr_output=$(create_pull_request 1 "shell-quote" "pnpm")

case "$pr_output" in
  *"1.8.3 -> 1.8.4"*)
    :
    ;;
  *)
    printf 'Assertion failed for pr body versions\nExpected explicit installed/patched versions\n' >&2
    exit 1
    ;;
esac

printf 'OK\n'