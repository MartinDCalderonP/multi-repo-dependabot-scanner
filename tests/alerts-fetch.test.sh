#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

_gql_response='{"data":{"repository":{"vulnerabilityAlerts":{"nodes":[{"number":1,"securityAdvisory":{"severity":"HIGH","summary":"Test vuln"},"securityVulnerability":{"package":{"name":"foo"},"firstPatchedVersion":{"identifier":"1.0.1"}}},{"number":2,"securityAdvisory":{"severity":"MODERATE","summary":"Another vuln"},"securityVulnerability":{"package":{"name":"bar"},"firstPatchedVersion":null}}]}}}}'

gh() {
    case "$1" in
        api)
            case "${2:-}" in
                graphql) echo "$_gql_response"; return 0 ;;
                /repos*) echo "[]"; return 0 ;;
            esac
            ;;
    esac
    return 0
}

source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/alerts-fetch.sh"

output="$(fetch_open_alerts_graphql test-org test-repo)"
assert_contains "$output" '"name":"foo"' "package name foo"
assert_contains "$output" '"name":"bar"' "package name bar"
assert_contains "$output" '"severity":"high"' "severity normalized"
assert_contains "$output" '"severity":"medium"' "moderate normalized to medium"
assert_contains "$output" '"summary":"Test vuln"' "summary preserved"

output="$(fetch_open_alerts test-org test-repo)"
assert_contains "$output" '"name":"foo"' "fallback to REST"

_gql_response="error"
output="$(fetch_open_alerts test-org test-repo)"
assert_contains "$output" "[]" "REST fallback on GraphQL failure"

_gql_response='{"data":{"repository":{"vulnerabilityAlerts":{"nodes":[{"number":1,"securityAdvisory":{"severity":"CRITICAL","summary":"Critical vuln"},"securityVulnerability":{"package":{"name":"critical-pkg"},"firstPatchedVersion":{"identifier":"2.0.0"}}}]}}}}'
output="$(fetch_open_alerts_graphql test-org test-repo)"
assert_contains "$output" '"severity":"critical"' "critical severity normalized"
assert_contains "$output" '"name":"critical-pkg"' "critical package name"

_gql_response='{"data":{"repository":{"vulnerabilityAlerts":{"nodes":[{"number":1,"securityAdvisory":{"severity":"LOW","summary":"Low vuln"},"securityVulnerability":{"package":{"name":"low-pkg"},"firstPatchedVersion":null}}]}}}}'
output="$(fetch_open_alerts_graphql test-org test-repo)"
assert_contains "$output" '"severity":"low"' "low severity preserved"
assert_contains "$output" '"first_patched_version":null' "null patched version"

_gh_rest_response='[{"number":10,"dependency":{"package":{"name":"rest-pkg"}},"security_advisory":{"severity":"high","summary":"REST alert"},"security_vulnerability":{"first_patched_version":{"identifier":"1.0.1"}}}]'
_gh_rest_return=0
gh() {
    case "$1" in
        api)
            case "${2:-}" in
                graphql) return 1 ;;
                /repos*)
                    echo "$_gh_rest_response"
                    return "$_gh_rest_return"
                    ;;
            esac
            ;;
    esac
    return 1
}
output="$(fetch_open_alerts test-org test-repo)"
assert_contains "$output" '"name":"rest-pkg"' "REST fallback returns real data"

gh() {
    case "$1" in
        api) return 1 ;;
    esac
    return 1
}
output="$(fetch_open_alerts test-org test-repo)"
assert_contains "$output" "[]" "both GraphQL and REST failure returns empty"

printf 'OK\n'
