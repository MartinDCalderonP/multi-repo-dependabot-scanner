#!/bin/bash

display_alerts_by_version_comparison() {
    local alerts_json=$1
    local comparison=$2  # "le" for <=, "gt" for >
    local icon=$3
    
    local filter_field
    if [ "$comparison" = "le" ]; then
        filter_field="is_auto_fixable"
    else
        filter_field="is_breaking"
    fi
    
    while IFS='|' read -r severity summary package version; do
        display_alert "$icon" "$severity" "$summary" "$package" "$version"
    done < <(echo "$alerts_json" | jq -r "map(select(.$filter_field == true)) | map(. + {
        severity_order: (if .security_advisory.severity == \"critical\" then 0 elif .security_advisory.severity == \"high\" then 1 elif .security_advisory.severity == \"medium\" then 2 else 3 end)
    }) | sort_by(.severity_order) | .[] | \"\(.security_advisory.severity)|\(.security_advisory.summary)|\(.dependency.package.name)|\(.security_vulnerability.first_patched_version.identifier)\"")
}

display_auto_fixable_alerts() {
    display_alerts_by_version_comparison "$1" "le" "✓"
}

display_breaking_alerts() {
    local alerts_json=$1

    while IFS='|' read -r severity summary package version; do
        display_alert "⚠" "$severity" "$summary" "$package" "$version"
    done < <(echo "$alerts_json" | jq -r 'map(select((.is_breaking == true and .is_blocked != true) or (.is_blocked == true and .blocked_reason != "dependabot_timed_out" and .security_vulnerability.first_patched_version.identifier != null))) | map(. + {
        severity_order: (if .security_advisory.severity == "critical" then 0 elif .security_advisory.severity == "high" then 1 elif .security_advisory.severity == "medium" then 2 else 3 end)
    }) | sort_by(.severity_order) | .[] | "\(.security_advisory.severity)|\(.security_advisory.summary)|\(.dependency.package.name)|\(.security_vulnerability.first_patched_version.identifier)"')
}

display_blocked_alerts() {
    local alerts_json=$1

    local not_possible_count=$(echo "$alerts_json" | jq '[.[] | select(.is_blocked == true and .blocked_reason != "dependabot_timed_out" and .security_vulnerability.first_patched_version.identifier == null)] | length')

    [ "$not_possible_count" -gt 0 ] && echo -e "      ${YELLOW}$(t section_blocked_not_possible)${NC}" && \
        while IFS='|' read -r severity summary package version; do
            display_alert "⊘" "$severity" "$summary" "$package" "$version"
        done < <(echo "$alerts_json" | jq -r 'map(select(.is_blocked == true and .blocked_reason != "dependabot_timed_out" and .security_vulnerability.first_patched_version.identifier == null)) | map(. + {
            severity_order: (if .security_advisory.severity == "critical" then 0 elif .security_advisory.severity == "high" then 1 elif .security_advisory.severity == "medium" then 2 else 3 end)
        }) | sort_by(.severity_order) | .[] | "\(.security_advisory.severity)|\(.security_advisory.summary)|\(.dependency.package.name)|\(.security_vulnerability.first_patched_version.identifier)"')
}

display_unfixable_alerts() {
    local alerts_json=$1
    
    local count=$(echo "$alerts_json" | jq -r 'map(select(.security_vulnerability.first_patched_version.identifier == null and .is_blocked != true)) | length')
    
    if [ "$count" -eq 0 ]; then
        return
    fi
    
    while IFS='|' read -r severity summary package; do
        display_alert "✗" "$severity" "$summary" "$package" "$(t version_unavailable)"
    done < <(echo "$alerts_json" | jq -r 'map(select(.security_vulnerability.first_patched_version.identifier == null and .is_blocked != true)) | map(. + {severity_order: (if .security_advisory.severity == "critical" then 0 elif .security_advisory.severity == "high" then 1 elif .security_advisory.severity == "medium" then 2 else 3 end)}) | sort_by(.severity_order) | .[] | "\(.security_advisory.severity)|\(.security_advisory.summary)|\(.dependency.package.name)"')
}
