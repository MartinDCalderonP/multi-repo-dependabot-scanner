#!/bin/bash

run_fix_mode() {
    local alerts_json=$1
    local alerts_count=$2
    local auto_fixable=$3
    
    if [ "$auto_fixable" -eq 0 ]; then
        print_warning "No hay alertas auto-resolvibles. Saltando..."
        return
    fi
    
    local pm=$(detect_package_manager)
    
    if [ "$pm" = "unknown" ]; then
        print_warning "No se detectó gestor de paquetes"
        return
    fi
    
    echo -e "Gestor de paquetes: ${GREEN}$pm${NC}"
    
    if has_uncommitted_changes; then
        print_warning "Hay cambios sin commitear. Saltando..."
        return
    fi
    
    print_info "📥 Sincronizando con remoto..."
    git pull --rebase 2>/dev/null || print_warning "No se pudo hacer pull (puede no tener remoto configurado)"
    
    echo ""
    print_info "🔧 Intentando reparar vulnerabilidades auto-resolvibles..."
    echo ""
    
    apply_fixes "$pm" "$alerts_json"
    
    if has_uncommitted_changes; then
        handle_commit_workflow "$alerts_count"
    fi
}

apply_fixes() {
    local pm=$1
    local alerts_json=$2
    
    fix_vulnerabilities "$pm"
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
