#!/bin/bash

SECONDS_PER_MINUTE=60
SECONDS_PER_HOUR=3600

format_duration() {
    local total_seconds=$1
    local hours=$((total_seconds / SECONDS_PER_HOUR))
    local minutes=$(((total_seconds % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE))
    local seconds=$((total_seconds % SECONDS_PER_MINUTE))
    local parts=()

    [ "$hours" -gt 0 ] && parts+=("${hours}h")
    [ "$minutes" -gt 0 ] && parts+=("${minutes}m")
    if [ ${#parts[@]} -eq 0 ] || [ "$seconds" -gt 0 ]; then
        parts+=("${seconds}s")
    fi

    local IFS=' '
    echo "${parts[*]}"
}

display_finished_at() {
    local scan_start_epoch=$1
    local finished_time finished_date elapsed_seconds
    read -r finished_time finished_date <<< "$(date '+%H:%M:%S %d-%m-%Y')"
    elapsed_seconds=$(( $(date +%s) - scan_start_epoch ))

    printf "$(t summary_finished_at)\n" "$finished_time" "$finished_date" "$(format_duration "$elapsed_seconds")"
}
