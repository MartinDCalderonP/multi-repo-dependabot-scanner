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
    display_alerts_by_version_comparison "$1" "gt" "⚠"
}

display_unfixable_alerts() {
    local alerts_json=$1
    
    local count=$(echo "$alerts_json" | jq -r 'map(select(.security_vulnerability.first_patched_version.identifier == null)) | length')
    
    if [ "$count" -eq 0 ]; then
        return
    fi
    
    while IFS='|' read -r severity summary package; do
        display_alert "✗" "$severity" "$summary" "$package" "No disponible"
    done < <(echo "$alerts_json" | jq -r 'map(select(.security_vulnerability.first_patched_version.identifier == null)) | map(. + {severity_order: (if .security_advisory.severity == "critical" then 0 elif .security_advisory.severity == "high" then 1 elif .security_advisory.severity == "medium" then 2 else 3 end)}) | sort_by(.severity_order) | .[] | "\(.security_advisory.severity)|\(.security_advisory.summary)|\(.dependency.package.name)"')
}
