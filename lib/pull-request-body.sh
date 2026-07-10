#!/bin/bash

build_pull_request_body() {
    local auto_fixable=$1
    local package_list=$2
    local pm=$3
    local update_list=$4

    local alert_word=$(pluralize "$auto_fixable" "alert")
    local changes_line1=$(get_pm_fix_description "$pm")
    local changes_line2="- Updated vulnerable packages to patched versions"
    local body="Automated fixes for Dependabot security alerts.$package_list"

    if [ -n "$update_list" ]; then
        body="$body

## Applied changes
$update_list"
    fi

    printf '%s

## Changes
%s
%s

## Security
Resolves %s open Dependabot security %s.' \
        "$body" \
        "$changes_line1" \
        "$changes_line2" \
        "$auto_fixable" \
        "$alert_word"
}