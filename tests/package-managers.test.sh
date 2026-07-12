#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

get_pnpm_installed_version() { echo "1.0.0"; }
fix_pnpm_vulnerabilities() { echo "fix_pnpm_called"; }
_add_yarn_calls_file="$(mktemp)"
npm_calls_file="$(mktemp)"
yarn_install_file="$(mktemp)"

add_yarn_resolutions() { echo "$1:$2" >> "$_add_yarn_calls_file"; return 0; }
yarn() { echo "called" >> "$yarn_install_file"; }
npm() { echo "$@" >> "$npm_calls_file"; }
print_info() { echo "INFO:$1"; }
t() { echo "$1"; }

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/package-managers.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir" "$_add_yarn_calls_file" "$npm_calls_file" "$yarn_install_file"' EXIT
cd "$tmpdir"

: > pnpm-lock.yaml
assert_equals "pnpm" "$(detect_package_manager)" "pnpm"
rm -f pnpm-lock.yaml && : > yarn.lock
assert_equals "yarn" "$(detect_package_manager)" "yarn"
rm -f yarn.lock && : > package-lock.json
assert_equals "npm" "$(detect_package_manager)" "npm"
rm -f package-lock.json
assert_equals "unknown" "$(detect_package_manager)" "unknown"

mkdir -p sub && : > sub/package.json && : > package.json
assert_contains "$(find_monorepo_subdirs)" "sub" "monorepo"

assert_equals "1.0.0" "$(get_installed_version pnpm foo)" "pnpm ver"

rm -f yarn.lock && : > yarn.lock
yarn() { printf 'foo@1.2.3\n'; }
assert_contains "$(get_installed_version yarn foo)" "1.2.3" "yarn lock"

yarn() { printf 'Version: 4.5.6\n'; }
assert_contains "$(get_installed_version yarn foo)" "4.5.6" "yarn info"

rm -f yarn.lock
yarn() { printf 'foo@7.8.9\n'; }
assert_contains "$(get_installed_version yarn foo)" "7.8.9" "yarn list"

yarn() { echo ""; }
npm() { printf 'bar@2.3.4\n'; }
assert_contains "$(get_installed_version npm bar)" "2.3.4" "npm ver"
assert_equals "" "$(get_installed_version unknown foo)" "unknown pm"

alerts='[{"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}}}]'

output="$(fix_vulnerabilities pnpm '[]' || true)"
assert_equals "" "$output" "empty alerts"
output="$(fix_vulnerabilities pnpm "$alerts" || true)"
assert_contains "$output" "fix_pnpm_called" "pnpm fix"

: > "$_add_yarn_calls_file" && : > "$yarn_install_file"
yarn() { echo "called" >> "$yarn_install_file"; }
add_yarn_resolutions() { echo "$1:$2" >> "$_add_yarn_calls_file"; return 0; }
output="$(fix_vulnerabilities yarn "$alerts" || true)"
assert_contains "$output" "INFO:" "yarn fix"
calls="$(cat "$_add_yarn_calls_file")"
assert_contains "$calls" "foo:1.0.0" "yarn resolution"
yarn_count="$(wc -l < "$yarn_install_file" | tr -d ' ')"
assert_contains "$yarn_count" "1" "yarn install called"

: > "$npm_calls_file"
npm() { echo "$@" >> "$npm_calls_file"; }
output="$(fix_vulnerabilities npm "$alerts" || true)"
assert_contains "$output" "INFO:" "npm fix"
npm_calls="$(cat "$npm_calls_file")"
assert_contains "$npm_calls" "audit" "npm audit"

result=0
fix_vulnerabilities "unknown" "$alerts" || result=$?
assert_equals "1" "$result" "unknown pm err"

printf 'OK\n'
