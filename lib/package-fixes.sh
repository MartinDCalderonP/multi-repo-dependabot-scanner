#!/bin/bash

apply_fixes() {
    local pm=$1
    local alerts_json=$2
    
    fix_vulnerabilities "$pm" "$alerts_json"
    apply_yarn_resolutions "$pm" "$alerts_json"
    
    if has_uncommitted_changes; then
        print_success "Se aplicaron correcciones automáticas"
    else
        print_warning "No se pudieron aplicar correcciones automáticas (pueden ser dependencias indirectas sin override)"
    fi
}

apply_yarn_resolutions() {
    local pm=$1
    local alerts_json=$2
    
    [ "$pm" != "yarn" ] && return
    
    echo ""
    print_info "🔍 Verificando alertas restantes..."
    
    echo "$alerts_json" | jq -c '.[]' | while read -r alert; do
        local package_name=$(echo "$alert" | jq -r '.dependency.package.name')
        local patched_version=$(echo "$alert" | jq -r '.security_vulnerability.first_patched_version.identifier // empty')
        local patched_major=$(echo "$patched_version" | cut -d'.' -f1)
        
        if [ -n "$patched_version" ] && [ "$patched_major" -lt 2 ] 2>/dev/null; then
            echo -e "   ${CYAN}Agregando resolution para $package_name...${NC}"
            add_yarn_resolutions "$package_name" "$patched_version"
        fi
    done
    
    if has_uncommitted_changes; then
        echo ""
        print_info "Reinstalando con resolutions..."
        yarn install 2>/dev/null
    fi
}
