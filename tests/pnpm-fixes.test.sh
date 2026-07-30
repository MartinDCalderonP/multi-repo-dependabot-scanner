#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_info() { echo "INFO:$1"; }
print_success() { echo "SUCCESS:$1"; }
print_warning() { echo "WARNING:$1"; }
t() { echo "$1"; }

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/pnpm-fixes.sh"
source "$SCRIPT_DIR/lib/package-fixes.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

input='  - foo 1.0.0
  + foo 1.0.1
  - bar 2.0.0
  + bar 2.0.1'
result="$(extract_pnpm_update_details "$input")"
assert_contains "$result" "foo" "foo update extracted"
assert_contains "$result" "1.0.0" "old foo version"
assert_contains "$result" "1.0.1" "new foo version"
assert_contains "$result" "bar" "bar update extracted"

input='  - baz 1.0.0'
result="$(extract_pnpm_update_details "$input")"
assert_equals "" "$result" "removed only no output"

input='  + baz 2.0.0'
result="$(extract_pnpm_update_details "$input")"
assert_equals "" "$result" "added only no output"

input='  unchanged 1.0.0'
result="$(extract_pnpm_update_details "$input")"
assert_equals "" "$result" "no change no output"

cd "$tmpdir"
echo "/foo@1.0.0:" > pnpm-lock.yaml
echo "  foo: 1.0.0" >> pnpm-lock.yaml
result="$(get_pnpm_lockfile_version foo)"
assert_equals "1.0.0" "$result" "lockfile version extracted"

echo "/@scope/pkg@3.2.1:" > pnpm-lock.yaml
result="$(get_pnpm_lockfile_version "@scope/pkg")"
assert_equals "3.2.1" "$result" "scoped lockfile version"

rm -f pnpm-lock.yaml
result="$(get_pnpm_lockfile_version foo || true)"
assert_equals "" "$result" "no lockfile empty"

echo "/foo@1.0.0:" > pnpm-lock.yaml
pnpm() {
    case "$*" in
        why*) printf '  foo@1.0.0\n'; return 0 ;;
        *) return 1 ;;
    esac
}
result="$(get_pnpm_installed_version foo)"
assert_equals "1.0.0" "$result" "lockfile version used"

rm -f pnpm-lock.yaml
pnpm() {
    case "$*" in
        why*) printf '  foo@2.5.0\n'; return 0 ;;
        *) return 1 ;;
    esac
}
result="$(get_pnpm_installed_version foo)"
assert_equals "2.5.0" "$result" "pnpm why version"

rm -f pnpm-lock.yaml
pnpm() {
    case "$*" in
        why*) echo "error" >&2; return 1 ;;
        list*) printf '[{"name":"root","dependencies":{"bar":{"name":"bar","version":"3.7.0"}}}]\n'; return 0 ;;
        *) return 1 ;;
    esac
}
result="$(get_pnpm_installed_version bar)"
assert_equals "3.7.0" "$result" "pnpm list fallback"

pnpm() { echo "PNPM_CALL:$*"; }
PACKAGE_UPDATE_DETAILS=""
alerts='[{"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}}}]'
fix_pnpm_vulnerabilities "$alerts"
assert_contains "$PACKAGE_UPDATE_DETAILS" "" "update details set"

alerts='[]'
result=0
fix_pnpm_vulnerabilities "$alerts" || result=$?
assert_equals "0" "$result" "empty alerts returns 0"

printf 'OK\n'
