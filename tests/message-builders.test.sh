#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/version-utils.sh"
source "$SCRIPT_DIR/lib/message-builders.sh"

assert_equals "pnpm" "$(get_pm_display_name pnpm)" "pnpm display"
assert_equals "Yarn" "$(get_pm_display_name yarn)" "yarn display"
assert_equals "npm" "$(get_pm_display_name npm)" "npm display"
assert_equals "unknown" "$(get_pm_display_name docker)" "unknown display"
assert_equals "Applied \`npm audit fix\` to resolve vulnerabilities" "$(get_pm_fix_description npm)" "npm description"
assert_equals "Added Yarn resolutions for transitive dependencies" "$(get_pm_fix_description yarn)" "yarn description"
assert_equals "Applied \`pnpm audit --fix override\` to resolve vulnerabilities" "$(get_pm_fix_description pnpm)" "pnpm description"
assert_equals "fix: update foo, bar" "$(build_fix_title 'foo,bar')" "fix title"
assert_equals "fix: update vulnerable dependencies" "$(build_fix_title '')" "default fix title"

package_details=$'foo\t1.2.0\t1.2.3\nbar\t2.0.0\t1.9.9'
package_list_output="$(build_package_list "$package_details" false)"
assert_equals $'- foo: 1.2.0 -> 1.2.3\n- bar: 1.9.9 -> 2.0.0' "$package_list_output" "package list"

merged_output="$(merge_package_details $'foo\t1.0.0\t1.0.1' $'foo\t1.0.0\t1.0.2\nbar\t2.0.0\t2.0.1')"
assert_equals $'foo\t1.0.0\t1.0.1\nbar\t2.0.0\t2.0.1' "$merged_output" "merged packages"

branch_name="$(build_branch_name 'foo, bar')"
case "$branch_name" in
    fix/dependabot-foo-bar-*) : ;;
    *) printf 'Unexpected branch name: %s\n' "$branch_name" >&2; exit 1 ;;
esac

empty_list="$(build_package_list '' false)"
assert_equals "" "$empty_list" "empty package list"

heading_list="$(build_package_list "$package_details" true)"
case "$heading_list" in
    *"Updated packages"*) : ;;
    *) printf 'FAIL: heading missing\n' >&2; exit 1 ;;
esac

empty_branch="$(build_branch_name '')"
case "$empty_branch" in
    fix/dependabot-alerts-*) : ;;
    *) printf 'FAIL: empty branch should use default prefix: %s\n' "$empty_branch" >&2; exit 1 ;;
esac

printf 'OK\n'
