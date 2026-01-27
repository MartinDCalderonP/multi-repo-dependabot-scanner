#!/bin/bash

display_auto_fixable_alerts() {
    local alerts_json=$1
    
    echo "$alerts_json" | jq -r 'map(select(.security_vulnerability.first_patched_version.identifier != null)) | map(. + {
        severity_order: (if .security_advisory.severity == "critical" then 0 elif .security_advisory.severity == "high" then 1 elif .security_advisory.severity == "medium" then 2 else 3 end),
        patched_major: (.security_vulnerability.first_patched_version.identifier | capture("^(?<major>[0-9]+)") | .major | tonumber)
    }) | map(select(.patched_major < 2)) | sort_by(.severity_order) | .[] | "\(.security_advisory.severity)|\(.security_advisory.summary)|\(.dependency.package.name)|\(.security_vulnerability.first_patched_version.identifier)"' | while IFS='|' read -r severity summary package version; do
        display_alert "✓" "$severity" "$summary" "$package" "$version"
    done
}

display_breaking_alerts() {
    local alerts_json=$1
    
    echo "$alerts_json" | jq -r 'map(select(.security_vulnerability.first_patched_version.identifier != null)) | map(. + {
        severity_order: (if .security_advisory.severity == "critical" then 0 elif .security_advisory.severity == "high" then 1 elif .security_advisory.severity == "medium" then 2 else 3 end),
        patched_major: (.security_vulnerability.first_patched_version.identifier | capture("^(?<major>[0-9]+)") | .major | tonumber)
    }) | map(select(.patched_major >= 2)) | sort_by(.severity_order) | .[] | "\(.security_advisory.severity)|\(.security_advisory.summary)|\(.dependency.package.name)|\(.security_vulnerability.first_patched_version.identifier)"' | while IFS='|' read -r severity summary package version; do
        display_alert "⚠" "$severity" "$summary" "$package" "$version"
    done
}

display_unfixable_alerts() {
    local alerts_json=$1
    
    echo "$alerts_json" | jq -r 'map(select(.security_vulnerability.first_patched_version.identifier == null)) | map(. + {severity_order: (if .security_advisory.severity == "critical" then 0 elif .security_advisory.severity == "high" then 1 elif .security_advisory.severity == "medium" then 2 else 3 end)}) | sort_by(.severity_order) | .[] | "\(.security_advisory.severity)|\(.security_advisory.summary)|\(.dependency.package.name)"' | while IFS='|' read -r severity summary package; do
        display_alert "✗" "$severity" "$summary" "$package" ""
    done
}
