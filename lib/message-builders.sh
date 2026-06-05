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
        "pnpm") echo "Applied \`pnpm audit --fix override\` to resolve vulnerabilities" ;;
        "yarn") echo "Added Yarn resolutions for transitive dependencies" ;;
        "npm") echo "Applied \`npm audit fix\` to resolve vulnerabilities" ;;
    esac
}

build_fix_title() {
    local package_names=$1
    
    if [ -n "$package_names" ]; then
        local formatted_package_names=$(echo "$package_names" | sed -E 's/,[[:space:]]*/, /g')
        echo "fix: update $formatted_package_names"
    else
        echo "fix: update vulnerable dependencies"
    fi
}

build_package_list() {
    local package_details=$1
    
    if [ -n "$package_details" ]; then
        printf "\n\n## Updated packages\n"
        while IFS=$'\t' read -r package_name installed_version patched_version; do
            [ -z "$package_name" ] && continue
            [ -z "$installed_version" ] && installed_version="unknown"
            [ -z "$patched_version" ] && patched_version="unknown"
            printf -- '- %s: %s -> %s\n' "$package_name" "$installed_version" "$patched_version"
        done <<< "$package_details"
    fi
}

build_branch_name() {
    local package_names=$1
    local branch_suffix=$(date +%Y%m%d-%H%M%S)
    local branch_name="fix/dependabot-alerts-$branch_suffix"
    
    if [ -n "$package_names" ]; then
        local packages_slug=$(echo "$package_names" | tr ',' '-' | tr -d ' ' | cut -c1-50)
        branch_name="fix/dependabot-$packages_slug-$branch_suffix"
    fi
    
    echo "$branch_name"
}
