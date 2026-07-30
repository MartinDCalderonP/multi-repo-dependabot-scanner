#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_warning() { echo "WARNING:$1"; }
print_info() { echo "INFO:$1"; }
print_success() { echo "SUCCESS:$1"; }
t() { echo "$1"; }

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/package-fixes.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"

cat > pnpm-workspace.yaml << 'EOF'
pnpm:
  overrides:
    elliptic: 6.6.2
    lodash: 1.0.0
EOF

PACKAGE_VERSION_DETAILS=$'elliptic\t6.5.7\t6.6.1'
fix_pnpm_overrides "$PACKAGE_VERSION_DETAILS"

content=$(cat pnpm-workspace.yaml)
assert_contains "$content" "elliptic: 6.6.1" "elliptic override corrected"
assert_contains "$content" "lodash: 1.0.0" "lodash unchanged"

cat > pnpm-workspace.yaml << 'EOF'
pnpm:
  overrides:
    foo: 1.0.0
EOF

PACKAGE_VERSION_DETAILS=$'unknown_pkg\t1.0.0\t2.0.0'
fix_pnpm_overrides "$PACKAGE_VERSION_DETAILS"

content=$(cat pnpm-workspace.yaml)
assert_contains "$content" "foo: 1.0.0" "unrelated pkg unchanged"

rm -f pnpm-workspace.yaml

PACKAGE_VERSION_DETAILS=$'elliptic\t6.5.7\t6.6.1'
fix_pnpm_overrides "$PACKAGE_VERSION_DETAILS"

if [ -f pnpm-workspace.yaml ]; then
    printf 'Assertion failed for no workspace file\nExpected: no file created\n' >&2
    exit 1
fi

printf 'OK\n'
