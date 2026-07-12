#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_success() { echo "SUCCESS:$1"; }
t() { echo "$1"; }

source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/lib/yarn-fixes.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"

echo '{}' > package.json
output="$(add_yarn_resolutions "foo" "1.0.0" || true)"
assert_equals "0" "$?" "add_yarn_resolutions returns 0"
result="$(jq -r '.resolutions.foo' package.json)"
assert_equals "1.0.0" "$result" "resolution added"

output="$(add_yarn_resolutions "bar" "2.0.0" || true)"
result="$(jq -r '.resolutions.bar' package.json)"
assert_equals "2.0.0" "$result" "second resolution added"
result="$(jq -r '.resolutions.foo' package.json)"
assert_equals "1.0.0" "$result" "first resolution preserved"

echo '{"resolutions":{"existing":"3.0.0"}}' > package.json
output="$(add_yarn_resolutions "new" "4.0.0" || true)"
result="$(jq -r '.resolutions.new' package.json)"
assert_equals "4.0.0" "$result" "new resolution added"
result="$(jq -r '.resolutions.existing' package.json)"
assert_equals "3.0.0" "$result" "existing resolution preserved"

rm -f package.json
result=0
add_yarn_resolutions "foo" "1.0.0" || result=$?
assert_equals "1" "$result" "no package.json returns 1"

printf 'OK\n'
