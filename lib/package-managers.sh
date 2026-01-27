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

fix_vulnerabilities() {
    local pm=$1
    
    case $pm in
        "pnpm")
            print_info "   Ejecutando: pnpm audit --fix"
            pnpm audit --fix 2>/dev/null
            print_info "   Ejecutando: pnpm install"
            pnpm install 2>/dev/null
            ;;
        "yarn")
            print_info "   Ejecutando: yarn audit fix"
            yarn audit fix 2>/dev/null
            ;;
        "npm")
            print_info "   Ejecutando: npm audit fix"
            npm audit fix 2>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

add_yarn_resolutions() {
    local package_name=$1
    local patched_version=$2
    
    if [ -f "package.json" ]; then
        jq --arg pkg "$package_name" --arg ver "$patched_version" \
           '.resolutions = (.resolutions // {}) | .resolutions[$pkg] = $ver' \
           package.json > package.json.tmp && mv package.json.tmp package.json
        
        print_success "   Resolution agregada para $package_name@$patched_version"
        return 0
    fi
    return 1
}
