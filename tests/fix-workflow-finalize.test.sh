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

has_uncommitted_changes() { return 1; }
_checkout_called=""
_checkout_main_branch() { _checkout_called="yes"; }
_checkout_delete_branch() { _checkout_called="deleted:$1"; }
checkout_main_branch() { _checkout_called="yes"; }
delete_branch() { _checkout_called="deleted:$1"; }
handle_commit_workflow() { echo "handle_commit:called"; }
print_warning() { echo "STUB_WARNING: $1"; }

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

has_uncommitted_changes() { return 0; }
finalize_fix_workflow 2 "fix/test" "foo" pnpm
assert_contains "$_checkout_called" "" "no checkout with changes"

has_uncommitted_changes() { return 1; }
_checkout_called=""
finalize_fix_workflow 2 "fix/test" "foo" pnpm
assert_contains "$_checkout_called" "deleted:fix/test" "branch deleted without changes"

printf 'OK\n'
