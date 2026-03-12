#!/bin/bash

handle_commit_workflow() {
    local auto_fixable=$1
    local branch_name=$2
    local package_names=$3
    local pm=$4
    
    repos_fixed=$((repos_fixed + 1))
    
    echo ""
    print_success "$(t updates_applied)"
    echo ""
    
    git status
    echo ""
    git diff package.json | head -50
    echo ""
    
    print_info "$(t creating_pr)"
    execute_full_workflow "$auto_fixable" "$branch_name" "$package_names" "$pm"
}

execute_full_workflow() {
    local auto_fixable=$1
    local branch_name=$2
    local package_names=$3
    local pm=$4
    
    if ! commit_fixes "$auto_fixable" "$package_names"; then
        checkout_main_branch
        return 1
    fi
    
    print_success "$(printf "$(t commit_created)" "$branch_name")"
    
    if push_branch "$branch_name"; then
        print_success "$(t push_done)"

        if create_pull_request "$auto_fixable" "$package_names" "$pm"; then
            print_success "$(t pr_created)"
        else
            print_warning "$(t pr_exists)"
        fi
    else
        print_warning "$(t push_failed)"
    fi
    
    checkout_main_branch
}
