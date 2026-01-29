#!/bin/bash

create_fix_branch() {
    local branch_name="fix/dependabot-alerts-$(date +%Y%m%d)"
    git checkout -b "$branch_name" 2>/dev/null || git checkout "$branch_name"
    echo "$branch_name"
}

commit_fixes() {
    local alerts_count=$1
    
    # Add all changes to package files (modified or new)
    git add package.json 2>/dev/null
    git add pnpm-lock.yaml 2>/dev/null
    git add pnpm-workspace.yaml 2>/dev/null
    git add yarn.lock 2>/dev/null
    git add package-lock.json 2>/dev/null
    
    if git diff --cached --quiet; then
        print_warning "No hay cambios staged para commitear"
        return 1
    fi
    
    git commit -m "fix: resolve Dependabot security alerts

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
    
    gh pr create --title "fix: resolve Dependabot security alerts" \
               --body "Automated fixes for Dependabot security alerts.

## Changes
- Applied \`audit fix\` to resolve vulnerabilities
- Added Yarn resolutions for transitive dependencies
- Updated packages to patched versions

## Security
Resolves $alerts_count open Dependabot security alerts." \
               --base main 2>/dev/null || \
    gh pr create --title "fix: resolve Dependabot security alerts" \
               --body "Automated fixes for Dependabot security alerts." \
               --base master 2>/dev/null
}

checkout_main_branch() {
    git checkout main 2>/dev/null || git checkout master 2>/dev/null
}

discard_changes() {
    git checkout . 2>/dev/null
    git clean -fd 2>/dev/null
}

has_uncommitted_changes() {
    ! git diff-index --quiet HEAD -- 2>/dev/null
}
