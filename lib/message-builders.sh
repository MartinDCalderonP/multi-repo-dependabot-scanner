#!/bin/bash

get_pm_display_name() {
    local pm=$1
    case $pm in
        "pnpm") echo "pnpm" ;;
        "yarn") echo "Yarn" ;;
        "npm") echo "npm" ;;
        *) echo "unknown" ;;
    esac
}

get_pm_fix_description() {
    local pm=$1
    case $pm in
        "pnpm") echo "Applied \`pnpm audit fix\` to resolve vulnerabilities" ;;
        "yarn") echo "Added Yarn resolutions for transitive dependencies" ;;
        "npm") echo "Applied \`npm audit fix\` to resolve vulnerabilities" ;;
    esac
}

build_fix_title() {
    local package_names=$1
    
    if [ -n "$package_names" ]; then
        echo "fix: update $package_names"
    else
        echo "fix: update vulnerable dependencies"
    fi
}

build_package_list() {
    local package_names=$1
    
    if [ -n "$package_names" ]; then
        printf "\n\n## Updated packages\n"
        echo "$package_names" | tr ',' '\n' | sed 's/^/- /' | sed 's/^ - /- /'
    fi
}

build_branch_name() {
    local package_names=$1
    local branch_suffix=$(date +%Y%m%d)
    local branch_name="fix/dependabot-alerts-$branch_suffix"
    
    if [ -n "$package_names" ]; then
        local packages_slug=$(echo "$package_names" | tr ',' '-' | tr -d ' ' | cut -c1-50)
        branch_name="fix/dependabot-$packages_slug-$branch_suffix"
    fi
    
    echo "$branch_name"
}
