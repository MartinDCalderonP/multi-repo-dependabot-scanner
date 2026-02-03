#!/bin/bash

enrich_alerts_with_versions() {
    local alerts_json=$1
    local pm=$2
    
    local packages=$(echo "$alerts_json" | jq -r '.[].dependency.package.name' | sort -u)
    
    local version_map="{"
    local first=true
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        local version=$(get_installed_version "$pm" "$pkg")
        if [ -n "$version" ]; then
            [ "$first" = false ] && version_map+=","
            version_map+="\"$pkg\":\"$version\""
            first=false
        fi
    done <<< "$packages"
    version_map+="}"
    
    echo "$alerts_json" | jq --argjson versions "$version_map" 'map(. + {
        installed_version: ($versions[.dependency.package.name] // empty),
        patched_major: (if .security_vulnerability.first_patched_version.identifier then 
            (.security_vulnerability.first_patched_version.identifier | capture("^(?<major>[0-9]+)") | .major | tonumber) 
        else null end),
        current_major: (
            if .security_vulnerability.first_patched_version.identifier then
                ((.security_vulnerability.first_patched_version.identifier | capture("^(?<major>[0-9]+)") | .major | tonumber) as $patched_major |
                if ($versions[.dependency.package.name] // empty) != "" then
                    (($versions[.dependency.package.name]) | capture("^(?<major>[0-9]+)") | .major | tonumber)
                else
                    $patched_major - 1
                end)
            else null end
        )
    } | . + {
        is_auto_fixable: (.patched_major != null and .patched_major <= .current_major),
        is_breaking: (.patched_major != null and .patched_major > .current_major)
    })'
}

calculate_alert_metrics() {
    local alerts_json=$1
    local alerts_count=$2
    
    local unfixable=$(echo "$alerts_json" | jq '[.[] | select(.security_vulnerability.first_patched_version.identifier == null)] | length' 2>/dev/null)
    local breaking=$(echo "$alerts_json" | jq '[.[] | select(.is_breaking == true)] | length' 2>/dev/null)
    local auto_fixable=$(echo "$alerts_json" | jq '[.[] | select(.is_auto_fixable == true)] | length' 2>/dev/null)
    
    echo "$auto_fixable $breaking $unfixable"
}

get_severity_counts() {
    local alerts_json=$1
    
    local critical=$(echo "$alerts_json" | jq '[.[] | select(.security_advisory.severity == "critical")] | length' 2>/dev/null)
    local high=$(echo "$alerts_json" | jq '[.[] | select(.security_advisory.severity == "high")] | length' 2>/dev/null)
    local medium=$(echo "$alerts_json" | jq '[.[] | select(.security_advisory.severity == "medium")] | length' 2>/dev/null)
    local low=$(echo "$alerts_json" | jq '[.[] | select(.security_advisory.severity == "low")] | length' 2>/dev/null)
    
    echo "$critical $high $medium $low"
}
