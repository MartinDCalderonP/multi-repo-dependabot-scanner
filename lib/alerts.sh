#!/bin/bash

calculate_alert_metrics() {
    local alerts_json=$1
    local alerts_count=$2
    
    local fixable=$(echo "$alerts_json" | jq '[.[] | select(.security_vulnerability.first_patched_version.identifier != null)] | length' 2>/dev/null)
    
    local breaking=$(echo "$alerts_json" | jq '[.[] | select(.security_vulnerability.first_patched_version.identifier != null) | 
        (.security_vulnerability.first_patched_version.identifier | capture("^(?<major>[0-9]+)") | .major | tonumber) as $patched_major |
        select($patched_major >= 2)
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
