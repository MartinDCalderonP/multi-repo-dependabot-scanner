#!/bin/bash

detect_package_manager() {
    if [ -f "pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "yarn.lock" ]; then
        echo "yarn"
    elif [ -f "package-lock.json" ]; then
        echo "npm"
    else
        echo "unknown"
    fi
}

find_monorepo_subdirs() {
    find . -maxdepth 2 -name "package.json" -not -path "*/node_modules/*" -exec dirname {} \; 2>/dev/null | grep -v "^\.$"
}

get_installed_version() {
    local pm=$1
    local package_name=$2
    
    local version=""
    case $pm in
        "pnpm")
            version=$(pnpm why "$package_name" 2>&1 | grep -oE "$package_name [0-9]+\.[0-9]+\.[0-9]+" | head -1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")
            ;;
        "yarn")
            if [ -f "yarn.lock" ]; then
                version=$(grep -A 1 "\"$package_name@npm:" yarn.lock 2>/dev/null | grep "version:" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
            fi
            if [ -z "$version" ]; then
                version=$(yarn info "$package_name" 2>/dev/null | grep -E "Version:|@npm:" | head -1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
            fi
            if [ -z "$version" ]; then
                version=$(yarn list --pattern "$package_name" --depth=0 2>/dev/null | grep -oE "$package_name@[0-9]+\.[0-9]+\.[0-9]+" | head -1 | cut -d'@' -f2)
            fi
            ;;
        "npm")
            version=$(npm list "$package_name" --depth=Infinity 2>&1 | grep -oE "$package_name@[0-9]+\.[0-9]+\.[0-9]+" | head -1 | cut -d'@' -f2)
            ;;
    esac
    
    echo "$version"
}

fix_vulnerabilities() {
    local pm=$1
    local alerts_json=$2
    
    local packages=$(echo "$alerts_json" | jq -r 'map(select(.is_auto_fixable == true or (.is_blocked == true and .blocked_reason != "dependabot_timed_out" and .security_vulnerability.first_patched_version.identifier != null))) | .[].dependency.package.name' | tr '\n' ' ')
    
    if [ -z "$packages" ]; then
        return 0
    fi
    
    case $pm in
        "pnpm")
            print_info "$(t running_pnpm_install)"
            pnpm install 2>/dev/null
            print_info "$(t running_pnpm_audit)"
            pnpm audit --fix 2>/dev/null
            print_info "$(printf "$(t updating_packages)" "$packages")"
            pnpm update $packages 2>/dev/null
            print_info "$(t running_pnpm_install)"
            pnpm install 2>/dev/null
            ;;
        "yarn")
            print_info "$(t applying_resolutions)"
            local success=false
            while IFS= read -r alert; do
                local pkg=$(echo "$alert" | jq -r '.dependency.package.name')
                local version=$(echo "$alert" | jq -r '.security_vulnerability.first_patched_version.identifier')
                if add_yarn_resolutions "$pkg" "$version"; then
                    success=true
                fi
            done < <(echo "$alerts_json" | jq -c 'map(select(.is_auto_fixable == true or (.is_blocked == true and .blocked_reason != "dependabot_timed_out" and .security_vulnerability.first_patched_version.identifier != null))) | .[]')
            
            if [ "$success" = true ]; then
                print_info "$(t running_yarn_install)"
                yarn install 2>/dev/null
            fi
            ;;
        "npm")
            print_info "$(t running_npm_audit)"
            npm audit fix --force 2>/dev/null
            print_info "$(printf "$(t updating_packages)" "$packages")"
            npm update $packages 2>/dev/null
            print_info "$(t running_npm_install)"
            npm install 2>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}
