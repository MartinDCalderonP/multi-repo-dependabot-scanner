#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/message-builders.sh"
source "$SCRIPT_DIR/lib/fix-workflow.sh"

has_uncommitted_changes() {
    return 1
}

get_default_branch() {
    echo "main"
}

cleanup_pnpm_files() {
    return 0
}

git() {
    if [ "$1" = "pull" ]; then
        return 0
    fi

    return 0
}

assert_equals() {
    local expected=$1
    local actual=$2
    local label=$3

    if [ "$expected" != "$actual" ]; then
        printf 'Assertion failed for %s\nExpected: %s\nActual:   %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    fi
}

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

printf 'OK\n'