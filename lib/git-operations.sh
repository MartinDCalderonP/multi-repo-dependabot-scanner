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
    local alerts_count=$1
    local package_names=$2
    
    git add package.json 2>/dev/null
    git add pnpm-lock.yaml 2>/dev/null
    git add pnpm-workspace.yaml 2>/dev/null
    git add yarn.lock 2>/dev/null
    git add package-lock.json 2>/dev/null
    
    if git diff --cached --quiet; then
        print_warning "No hay cambios staged para commitear"
        return 1
    fi
    
    local commit_title=$(build_fix_title "$package_names")
    
    git commit -m "$commit_title

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
    local alerts_count=$1
    local package_names=$2
    local default_branch=$(get_default_branch)
    
    local pr_title=$(build_fix_title "$package_names")
    local package_list=$(build_package_list "$package_names")
    
    gh pr create --title "$pr_title" \
               --body "Automated fixes for Dependabot security alerts.$package_list
## Changes
- Applied \`audit fix\` to resolve vulnerabilities
- Added Yarn resolutions for transitive dependencies
- Updated vulnerable packages to patched versions

## Security
Resolves $alerts_count open Dependabot security alerts." \
               --base "$default_branch"
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

has_uncommitted_changes() {
    ! git diff-index --quiet HEAD -- 2>/dev/null
}
