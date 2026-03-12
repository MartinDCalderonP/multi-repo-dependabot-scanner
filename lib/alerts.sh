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
        installed_version: ($versions[.dependency.package.name] // null),
        patched_major: (if .security_vulnerability.first_patched_version.identifier then 
            (.security_vulnerability.first_patched_version.identifier | capture("^(?<major>[0-9]+)") | .major | tonumber) 
        else null end),
        patched_minor: (if .security_vulnerability.first_patched_version.identifier then
            (.security_vulnerability.first_patched_version.identifier | capture("^[0-9]+\\.(?<minor>[0-9]+)") | .minor | tonumber)
        else null end),
        current_major: (
            if .security_vulnerability.first_patched_version.identifier then
                ((.security_vulnerability.first_patched_version.identifier | capture("^(?<major>[0-9]+)") | .major | tonumber) as $patched_major |
                if ($versions[.dependency.package.name] // "") != "" then
                    (($versions[.dependency.package.name]) | capture("^(?<major>[0-9]+)") | .major | tonumber)
                else
                    $patched_major - 1
                end)
            else null end
        ),
        current_minor: (
            if ($versions[.dependency.package.name] // "") != "" then
                ($versions[.dependency.package.name] | capture("^[0-9]+\\.(?<minor>[0-9]+)") | .minor | tonumber)
            else null end
        )
    } | . + {
        is_auto_fixable: (
            .patched_major != null and (
                if .current_major == 0 and .patched_major == 0 then
                    (.patched_minor != null and .current_minor != null and .patched_minor <= .current_minor)
                else
                    .patched_major <= .current_major
                end
            )
        ),
        is_breaking: (
            .patched_major != null and (
                if .current_major == 0 and .patched_major == 0 then
                    (.patched_minor != null and .current_minor != null and .patched_minor > .current_minor)
                else
                    .patched_major > .current_major
                end
            )
        )
    })'
}

calculate_alert_metrics() {
    local alerts_json=$1
    local alerts_count=$2

    local unfixable=$(echo "$alerts_json" | jq '[.[] | select(.security_vulnerability.first_patched_version.identifier == null)] | length' 2>/dev/null)
    local breaking=$(echo "$alerts_json" | jq '[.[] | select(.is_breaking == true)] | length' 2>/dev/null)
    local auto_fixable=$(echo "$alerts_json" | jq '[.[] | select(.is_auto_fixable == true)] | length' 2>/dev/null)
    local blocked=$(echo "$alerts_json" | jq '[.[] | select(.is_blocked == true)] | length' 2>/dev/null)

    echo "$auto_fixable $breaking $unfixable $blocked"
}

get_severity_counts() {
    local alerts_json=$1
    
    local critical=$(echo "$alerts_json" | jq '[.[] | select(.security_advisory.severity == "critical")] | length' 2>/dev/null)
    local high=$(echo "$alerts_json" | jq '[.[] | select(.security_advisory.severity == "high")] | length' 2>/dev/null)
    local medium=$(echo "$alerts_json" | jq '[.[] | select(.security_advisory.severity == "medium")] | length' 2>/dev/null)
    local low=$(echo "$alerts_json" | jq '[.[] | select(.security_advisory.severity == "low")] | length' 2>/dev/null)
    
    echo "$critical $high $medium $low"
}
