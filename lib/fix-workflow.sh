#!/bin/bash

prepare_fix_workflow() {
    local alerts_json=$1
    
    if has_uncommitted_changes; then
        print_warning "$(t uncommitted_skip)" >&2
        return 1
    fi
    
    local default_branch=$(get_default_branch)
    print_info "$(printf "$(t syncing_remote)" "$default_branch")" >&2
    git pull --rebase origin "$default_branch" >&2 || print_warning "$(t pull_failed)" >&2
    cleanup_pnpm_files "$(t after_pull)"
    
    local package_names=$(echo "$alerts_json" | jq -r 'map(select(.is_auto_fixable == true or (.is_blocked == true and .blocked_reason != "dependabot_timed_out" and .security_vulnerability.first_patched_version.identifier != null))) | .[].dependency.package.name' | sort -u | tr '\n' ', ' | sed 's/,$//')
    
    echo "$package_names"
}

finalize_fix_workflow() {
    local auto_fixable=$1
    local branch_name=$2
    local package_names=$3
    local pm=$4
    
    if has_uncommitted_changes; then
        handle_commit_workflow "$auto_fixable" "$branch_name" "$package_names" "$pm"
    else
        checkout_main_branch
        delete_branch "$branch_name"
        print_warning "$(t fixes_failed)"
    fi
}
