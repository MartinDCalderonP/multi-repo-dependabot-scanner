#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/version-utils.sh"
source "$SCRIPT_DIR/lib/message-builders.sh"

assert_equals() {
    local expected=$1
    local actual=$2
    local label=$3

    if [ "$expected" != "$actual" ]; then
        printf 'Assertion failed for %s\nExpected: %s\nActual:   %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    fi
}

assert_equals "pnpm" "$(get_pm_display_name pnpm)" "pnpm display"
assert_equals "Yarn" "$(get_pm_display_name yarn)" "yarn display"
assert_equals "Applied \`npm audit fix\` to resolve vulnerabilities" "$(get_pm_fix_description npm)" "npm description"
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

printf 'OK\n'
