#!/bin/bash

calculate_alert_metrics() {
    local alerts_json=$1
    local alerts_count=$2
    
    local fixable=$(echo "$alerts_json" | jq '[.[] | select(.security_vulnerability.first_patched_version.identifier != null)] | length' 2>/dev/null)
    
    local breaking=$(echo "$alerts_json" | jq '[.[] | 
        select(.security_vulnerability.first_patched_version.identifier != null) |
        (.security_vulnerability.vulnerable_version_range | split(",")[-1] | capture("[<>=]*\\s*(?<current_major>[0-9]+)") | .current_major | tonumber) as $current_major |
        (.security_vulnerability.first_patched_version.identifier | capture("^(?<patched_major>[0-9]+)") | .patched_major | tonumber) as $patched_major |
        select($patched_major > $current_major)
    ] | length' 2>/dev/null)
    
    local auto_fixable=$((fixable - breaking))
    local unfixable=$((alerts_count - fixable))
    
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
