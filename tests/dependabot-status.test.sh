#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

_gh_response=""
_gh_return=0

gh() {
    case "$1" in
        api)
            echo "$_gh_response"
            return "$_gh_return"
            ;;
    esac
    return 1
}

print_warning() { echo "WARNING:$1"; }
print_info() { echo "INFO:$1"; }
t() { echo "$1"; }

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/dependabot-status.sh"

alerts='[{"number":1,"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}},"security_advisory":{"severity":"high"}}]'

_gh_return=1
output="$(enrich_alerts_with_dependabot_status "$alerts" test-org test-repo)"
assert_contains "$output" '"name":"foo"' "graphql failure returns original"

_gh_return=0
_gh_response='{"data":{"repository":{"vulnerabilityAlerts":{"nodes":[{"number":1,"dependabotUpdate":{"error":{"errorType":"TIMEOUT"}},"pullRequest":null}]}}}}'
output="$(enrich_alerts_with_dependabot_status "$alerts" test-org test-repo)"
assert_contains "$output" '"is_blocked": true' "errored alert is blocked"
assert_contains "$output" '"blocked_reason": "TIMEOUT"' "blocked reason set"
assert_contains "$output" '"is_auto_fixable": false' "errored not auto fixable"

_gh_response='{"data":{"repository":{"vulnerabilityAlerts":{"nodes":[{"number":1,"dependabotUpdate":{"error":null,"pullRequest":{"url":"https://github.com/test/pr/1","state":"OPEN"}}}]}}}}'
output="$(enrich_alerts_with_dependabot_status "$alerts" test-org test-repo)"
assert_contains "$output" '"has_dependabot_pr": true' "has dependabot pr"
assert_contains "$output" '"dependabot_pr_url": "https://github.com/test/pr/1"' "pr url set"
assert_contains "$output" '"is_blocked": false' "non-errored not blocked"

_gh_response='{"data":{"repository":{"vulnerabilityAlerts":{"nodes":[]}}}}'
output="$(enrich_alerts_with_dependabot_status "$alerts" test-org test-repo)"
assert_contains "$output" '"is_blocked": false' "clean alerts not blocked"
assert_contains "$output" '"has_dependabot_pr": false' "no prs"

mixed_alerts='[
  {"number":1,"dependency":{"package":{"name":"foo"}},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.0"}}},
  {"number":2,"dependency":{"package":{"name":"bar"}},"security_vulnerability":{"first_patched_version":{"identifier":"2.0.0"}}}
]'
_gh_response='{"data":{"repository":{"vulnerabilityAlerts":{"nodes":[{"number":1,"dependabotUpdate":{"error":{"errorType":"TIMEOUT"}},"pullRequest":null},{"number":2,"dependabotUpdate":{"error":null,"pullRequest":{"url":"https://github.com/test/pr/2","state":"OPEN"}}}]}}}}'
output="$(enrich_alerts_with_dependabot_status "$mixed_alerts" test-org test-repo)"
assert_contains "$output" '"is_blocked": true' "mixed errored blocked"
assert_contains "$output" '"blocked_reason": "TIMEOUT"' "mixed blocked reason"
assert_contains "$output" '"has_dependabot_pr": true' "mixed has pr"
assert_contains "$output" '"repo_has_dependabot_pr": true' "mixed repo has pr"

single_alert='[{"number":5,"dependency":{"package":{"name":"baz"}},"security_vulnerability":{"first_patched_version":{"identifier":"3.0.0"}}}]'
_gh_response='{"data":{"repository":{"vulnerabilityAlerts":{"nodes":[{"number":5,"dependabotUpdate":{"error":null,"pullRequest":{"url":"https://github.com/test/pr/5","state":"CLOSED"}}}]}}}}'
output="$(enrich_alerts_with_dependabot_status "$single_alert" test-org test-repo)"
assert_contains "$output" '"is_blocked": false' "closed pr not blocked"
assert_contains "$output" '"has_dependabot_pr": false' "closed pr not has"

printf 'OK\n'
