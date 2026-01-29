#!/bin/bash

# Generic function to display alerts with version comparison
display_alerts_by_version_comparison() {
    local alerts_json=$1
    local comparison=$2  # "le" for <=, "gt" for >
    local icon=$3
    
    local filter_condition
    if [ "$comparison" = "le" ]; then
        filter_condition="select(.patched_major <= .current_major)"
    else
        filter_condition="select(.patched_major > .current_major)"
    fi
    
    echo "$alerts_json" | jq -r "map(select(.security_vulnerability.first_patched_version.identifier != null)) | map(. + {
        severity_order: (if .security_advisory.severity == \"critical\" then 0 elif .security_advisory.severity == \"high\" then 1 elif .security_advisory.severity == \"medium\" then 2 else 3 end),
        current_major: (.security_vulnerability.vulnerable_version_range | split(\",\")[-1] | capture(\"[<>=]*\\\\s*(?<major>[0-9]+)\") | .major | tonumber),
        patched_major: (.security_vulnerability.first_patched_version.identifier | capture(\"^(?<major>[0-9]+)\") | .major | tonumber)
    }) | map($filter_condition) | sort_by(.severity_order) | .[] | \"\(.security_advisory.severity)|\(.security_advisory.summary)|\(.dependency.package.name)|\(.security_vulnerability.first_patched_version.identifier)\"" | while IFS='|' read -r severity summary package version; do
        display_alert "$icon" "$severity" "$summary" "$package" "$version"
    done
}

display_auto_fixable_alerts() {
    display_alerts_by_version_comparison "$1" "le" "✓"
}

display_breaking_alerts() {
    display_alerts_by_version_comparison "$1" "gt" "⚠"
}

display_unfixable_alerts() {
    local alerts_json=$1
    
    echo "$alerts_json" | jq -r 'map(select(.security_vulnerability.first_patched_version.identifier == null)) | map(. + {severity_order: (if .security_advisory.severity == "critical" then 0 elif .security_advisory.severity == "high" then 1 elif .security_advisory.severity == "medium" then 2 else 3 end)}) | sort_by(.severity_order) | .[] | "\(.security_advisory.severity)|\(.security_advisory.summary)|\(.dependency.package.name)"' | while IFS='|' read -r severity summary package; do
        display_alert "✗" "$severity" "$summary" "$package" ""
    done
}
