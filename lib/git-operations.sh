#!/bin/bash

get_default_branch() {
    local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    
    if [ -n "$default_branch" ]; then
        echo "$default_branch"
        return
    fi
    
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    elif git show-ref --verify --quiet refs/heads/develop; then
        echo "develop"
    else
        git branch --show-current
    fi
}

create_fix_branch() {
    local package_names=$1
    local branch_name=$(build_branch_name "$package_names")
    git checkout -b "$branch_name" 2>/dev/null || git checkout "$branch_name"
    echo "$branch_name"
}

commit_fixes() {
    local auto_fixable=$1
    local package_names=$2
    
    git add -A
    
    if git diff --cached --quiet; then
        print_warning "$(t no_staged_changes)"
        return 1
    fi
    
    git commit -m "$(build_fix_title "$package_names")

- Applied automatic fixes with audit fix
- Added resolutions for transitive dependencies
- Updated vulnerable packages to patched versions

Resolves Dependabot security alerts"
}

push_branch() {
    local branch_name=$1
    git push -u origin "$branch_name"
}

create_pull_request() {
    local auto_fixable=$1
    local package_names=$2
    local pm=$3
    local default_branch=$(get_default_branch)
    
    local pr_title=$(build_fix_title "$package_names")
    local package_list=$(build_package_list "$PACKAGE_VERSION_DETAILS")
    local update_list=$(build_package_list "$PACKAGE_UPDATE_DETAILS" false)
    local body=$(build_pull_request_body "$auto_fixable" "$package_list" "$pm" "$update_list")

    local pr_url=$(gh pr create --title "$pr_title" \
               --body "$body" \
               --base "$default_branch" 2>&1)
    
    if [[ $pr_url == https://* ]]; then
        created_pr_urls+=("$pr_url")
    fi
    
    echo "$pr_url"
}

checkout_main_branch() {
    local default_branch=$(get_default_branch)
    git checkout "$default_branch" 2>/dev/null
}

discard_changes() {
    git checkout . 2>/dev/null
    git clean -fd 2>/dev/null
}

delete_branch() {
    local branch_name=$1
    git branch -D "$branch_name" >/dev/null 2>&1
}
