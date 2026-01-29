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
    local alerts_json=$2
    
    local packages=$(echo "$alerts_json" | jq -r 'map(select(.security_vulnerability.first_patched_version.identifier != null)) | map(. + {
        current_major: (.security_vulnerability.vulnerable_version_range | split(",")[-1] | capture("[<>=]*\\s*(?<major>[0-9]+)") | .major | tonumber),
        patched_major: (.security_vulnerability.first_patched_version.identifier | capture("^(?<major>[0-9]+)") | .major | tonumber)
    }) | map(select(.patched_major <= .current_major)) | .[].dependency.package.name' | tr '\n' ' ')
    
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
