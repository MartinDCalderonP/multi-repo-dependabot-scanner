#!/bin/bash

enrich_alerts_with_dependabot_status() {
    local alerts_json=$1
    local owner=$2
    local repo=$3

    local graphql_query='query($owner: String!, $repo: String!) {
        repository(owner: $owner, name: $repo) {
            vulnerabilityAlerts(first: 100, states: [OPEN]) {
                nodes { number dependabotUpdate { error { errorType } } }
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

    [ -z "$errored_numbers" ] || [ "$errored_numbers" = "[]" ] && { echo "$alerts_json"; return; }

    echo "$alerts_json" | jq --argjson errored "$errored_numbers" \
        --argjson errored_map "$(echo "$gql_response" | jq '[
            .data.repository.vulnerabilityAlerts.nodes[] |
            select(.dependabotUpdate.error != null) |
            {key: (.number | tostring), value: .dependabotUpdate.error.errorType}
        ] | from_entries' 2>/dev/null)" \
        'map(
        if (.number | tostring) as $n | $errored | index($n) != null then
            . + {is_auto_fixable: false, is_breaking: false, is_blocked: true, blocked_reason: $errored_map[.number | tostring]}
        else
            . + {is_blocked: false}
        end
    )'
}
