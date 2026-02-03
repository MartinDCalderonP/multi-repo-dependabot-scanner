#!/bin/bash

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
