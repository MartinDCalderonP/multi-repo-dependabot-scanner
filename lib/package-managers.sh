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
            version=$(yarn list --pattern "$package_name" --depth=0 2>/dev/null | grep -oE "$package_name@[0-9]+\.[0-9]+\.[0-9]+" | head -1 | cut -d'@' -f2)
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
    
    local packages=$(echo "$alerts_json" | jq -r 'map(select(.is_auto_fixable == true)) | .[].dependency.package.name' | tr '\n' ' ')
    
    if [ -z "$packages" ]; then
        return 0
    fi
    
    case $pm in
        "pnpm")
            print_info "   Ejecutando: pnpm audit --fix"
            pnpm audit --fix 2>/dev/null
            print_info "   Actualizando paquetes vulnerables: $packages"
            pnpm update $packages 2>/dev/null
            print_info "   Ejecutando: pnpm install"
            pnpm install 2>/dev/null
            ;;
        "yarn")
            print_info "   Yarn no soporta audit fix, usando resolutions..."
            ;;
        "npm")
            print_info "   Ejecutando: npm audit fix --force"
            npm audit fix --force 2>/dev/null
            print_info "   Actualizando paquetes vulnerables: $packages"
            npm update $packages 2>/dev/null
            print_info "   Ejecutando: npm install"
            npm install 2>/dev/null
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
