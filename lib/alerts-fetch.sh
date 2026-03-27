#!/bin/bash

fetch_open_alerts_graphql() {
    local owner=$1
    local repo=$2

    local graphql_query='query($owner: String!, $repo: String!) {
        repository(owner: $owner, name: $repo) {
            vulnerabilityAlerts(first: 100, states: [OPEN]) {
                nodes {
                    number
                    securityAdvisory { severity summary }
                    securityVulnerability {
                        package { name }
                        firstPatchedVersion { identifier }
                    }
                }
            }
        }
    }'

    local gql_response
    gql_response=$(gh api graphql \
        -f query="$graphql_query" \
        -f owner="$owner" \
        -f repo="$repo" 2>/dev/null) || return 1

    echo "$gql_response" | jq -c '[
        .data.repository.vulnerabilityAlerts.nodes[] |
        {
            number: .number,
            dependency: {
                package: {
                    name: .securityVulnerability.package.name
                }
            },
            security_advisory: {
                severity: (.securityAdvisory.severity | ascii_downcase | if . == "moderate" then "medium" else . end),
                summary: .securityAdvisory.summary
            },
            security_vulnerability: {
                first_patched_version: (if .securityVulnerability.firstPatchedVersion == null then null else {identifier: .securityVulnerability.firstPatchedVersion.identifier} end)
            }
        }
    ]' 2>/dev/null || return 1
}

fetch_open_alerts() {
    local owner=$1
    local repo=$2

    local graphql_alerts
    graphql_alerts=$(fetch_open_alerts_graphql "$owner" "$repo")
    [ $? -eq 0 ] && { echo "$graphql_alerts"; return; }

    local rest_alerts
    rest_alerts=$(gh api "/repos/$owner/$repo/dependabot/alerts?state=open&per_page=100" 2>/dev/null) || rest_alerts="[]"

    echo "$rest_alerts"
}
