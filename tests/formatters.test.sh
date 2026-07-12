#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/formatters.sh"

badge_output="$(print_severity_badge high 'Issue found')"
assert_contains "$badge_output" "[HIGH]" "high badge"

alert_output="$(display_alert '⚠' medium 'Issue found' 'foo' '1.2.3')"
assert_contains "$alert_output" "foo → v1.2.3" "version formatting"

critical_badge="$(print_severity_badge critical 'Critical')"
assert_contains "$critical_badge" "[CRITICAL]" "critical badge"

medium_badge="$(print_severity_badge medium 'Notice')"
assert_contains "$medium_badge" "[MEDIUM]" "medium badge"

low_badge="$(print_severity_badge low 'Info')"
assert_contains "$low_badge" "[LOW]" "low badge"

critical_alert="$(display_alert '⛔' critical 'Bug' 'bar' '2.0.0')"
assert_contains "$critical_alert" "[CRITICAL]" "critical alert badge"
assert_contains "$critical_alert" "bar → v2.0.0" "critical alert version"

high_alert="$(display_alert '⚠' high 'Vuln' 'baz' '1.2.3-beta.1')"
assert_contains "$high_alert" "[HIGH]" "high alert badge"
assert_contains "$high_alert" "baz → v1.2.3-beta.1" "pre-release version"

empty_version_alert="$(display_alert '⚠' high 'Bug' 'pkg' '')"
case "$empty_version_alert" in
    *"→"*) printf 'FAIL: empty version should not have arrow\n' >&2; exit 1 ;;
    *) : ;;
esac

nonsemver_alert="$(display_alert '⚠' high 'Bug' 'pkg' 'beta')"
assert_contains "$nonsemver_alert" "→ beta" "non-semver version no v prefix"

low_alert="$(display_alert 'ℹ' low 'Info' 'qux' '3.0.0')"
assert_contains "$low_alert" "[LOW]" "low alert badge"

printf 'OK\n'
