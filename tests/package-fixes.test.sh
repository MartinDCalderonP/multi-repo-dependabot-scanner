#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_warning() { echo "WARNING:$1"; }
print_info() { echo "INFO:$1"; }
print_success() { echo "SUCCESS:$1"; }
t() { echo "$1"; }

_add_yarn_calls_file="$(mktemp)"
_yarn_install_file="$(mktemp)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/package-fixes.sh"

trap 'rm -f "$_add_yarn_calls_file" "$_yarn_install_file"' EXIT

add_yarn_resolutions() {
    echo "$1:$2" >> "$_add_yarn_calls_file"
    return "${_add_yarn_return:-0}"
}

yarn() { echo "called" >> "$_yarn_install_file"; }

has_uncommitted_changes() { return "${_has_changes:-0}"; }

alerts_json='[{"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}}}]'

_has_changes=0
: > "$_add_yarn_calls_file"
output="$(apply_fixes pnpm "$alerts_json" || true)"
assert_contains "$output" "SUCCESS:" "fixes applied"

_has_changes=1
output="$(apply_fixes pnpm "$alerts_json" || true)"
assert_contains "$output" "WARNING:" "fixes failed no changes"

: > "$_add_yarn_calls_file"
apply_yarn_resolutions npm "$alerts_json" || true
calls="$(cat "$_add_yarn_calls_file")"
assert_contains "$calls" "" "npm skips yarn resolutions"

: > "$_add_yarn_calls_file"
: > "$_yarn_install_file"
_has_changes=0
apply_yarn_resolutions yarn "$alerts_json" || true
calls="$(cat "$_add_yarn_calls_file")"
assert_contains "$calls" "foo:1.0.0" "yarn resolution added"

high_patch='[{"dependency":{"package":{"name":"bar"}},"security_vulnerability":{"first_patched_version":{"identifier":"3.0.0"}}}]'
: > "$_add_yarn_calls_file"
apply_yarn_resolutions yarn "$high_patch" || true
calls="$(cat "$_add_yarn_calls_file")"
assert_contains "$calls" "" "high major patch skipped"

: > "$_add_yarn_calls_file"
: > "$_yarn_install_file"
_has_changes=1
apply_yarn_resolutions yarn "$alerts_json" || true
yarn_count="$(wc -l < "$_yarn_install_file" | tr -d ' ')"
assert_contains "$yarn_count" "0" "yarn install skipped no changes"

_add_yarn_return=1
: > "$_add_yarn_calls_file"
: > "$_yarn_install_file"
_has_changes=1
apply_yarn_resolutions yarn "$alerts_json" || true
calls="$(cat "$_add_yarn_calls_file")"
assert_contains "$calls" "foo:1.0.0" "resolution attempted even on failure"
yarn_count="$(wc -l < "$_yarn_install_file" | tr -d ' ')"
assert_contains "$yarn_count" "0" "yarn install skipped when no changes"

_add_yarn_return=0
: > "$_add_yarn_calls_file"
: > "$_yarn_install_file"
_has_changes=0
apply_yarn_resolutions yarn "$alerts_json" || true
yarn_count="$(wc -l < "$_yarn_install_file" | tr -d ' ')"
assert_contains "$yarn_count" "1" "yarn install called on success with changes"

pnpm_output="$(apply_fixes pnpm "$alerts_json" || true)"
assert_contains "$pnpm_output" "SUCCESS:" "pnpm apply_fixes success"

_has_changes=0
npm_calls_file="$(mktemp)"
npm() { echo "npm:$1" >> "$npm_calls_file"; }
trap 'rm -f "$_add_yarn_calls_file" "$_yarn_install_file" "$npm_calls_file"' EXIT
npm_output="$(apply_fixes npm "$alerts_json" || true)"
assert_contains "$npm_output" "SUCCESS:" "npm apply_fixes success"
npm_count="$(wc -l < "$npm_calls_file" | tr -d ' ')"
assert_equals "0" "$npm_count" "npm not called for yarn resolutions"

printf 'OK\n'
