#!/bin/bash

enrich_alerts_with_dependabot_status() {
    local alerts_json=$1
    local owner=$2
    local repo=$3

    local graphql_query='query($owner: String!, $repo: String!) {
        repository(owner: $owner, name: $repo) {
            vulnerabilityAlerts(first: 100, states: [OPEN]) {
                nodes { number dependabotUpdate { error { errorType } pullRequest { url state } } }
            }
        }
    }'

    local gql_response
    gql_response=$(gh api graphql \
        -f query="$graphql_query" \
        -f owner="$owner" \
        -f repo="$repo" 2>/dev/null) || { echo "$alerts_json"; return; }

    local errored_numbers
    errored_numbers=$(echo "$gql_response" | jq '[
        .data.repository.vulnerabilityAlerts.nodes[] |
        select(.dependabotUpdate.error != null) | .number | tostring
    ]' 2>/dev/null)

    local repo_has_open_dependabot_pr
    repo_has_open_dependabot_pr=$(echo "$gql_response" | jq '([
        .data.repository.vulnerabilityAlerts.nodes[] |
        select(.dependabotUpdate.pullRequest != null and .dependabotUpdate.pullRequest.state == "OPEN")
    ] | length) > 0' 2>/dev/null)

    echo "$alerts_json" | jq --argjson errored "$errored_numbers" \
        --argjson repo_has_open_pr "$repo_has_open_dependabot_pr" \
        --argjson pr_map "$(echo "$gql_response" | jq '[
            .data.repository.vulnerabilityAlerts.nodes[] |
            select(.dependabotUpdate.pullRequest != null and .dependabotUpdate.pullRequest.state == "OPEN") |
            {key: (.number | tostring), value: .dependabotUpdate.pullRequest.url}
        ] | from_entries' 2>/dev/null)" \
        --argjson errored_map "$(echo "$gql_response" | jq '[
            .data.repository.vulnerabilityAlerts.nodes[] |
            select(.dependabotUpdate.error != null) |
            {key: (.number | tostring), value: .dependabotUpdate.error.errorType}
        ] | from_entries' 2>/dev/null)" \
        'map(
        if (.number | tostring) as $n | $errored | index($n) != null then
            . + {
                is_auto_fixable: false,
                is_breaking: false,
                is_blocked: true,
                blocked_reason: $errored_map[.number | tostring],
                has_dependabot_pr: (($pr_map[.number | tostring] // null) != null),
                dependabot_pr_url: ($pr_map[.number | tostring] // null),
                repo_has_dependabot_pr: $repo_has_open_pr
            }
        else
            . + {
                is_blocked: false,
                has_dependabot_pr: (($pr_map[.number | tostring] // null) != null),
                dependabot_pr_url: ($pr_map[.number | tostring] // null),
                repo_has_dependabot_pr: $repo_has_open_pr
            }
        end
    )'
}
