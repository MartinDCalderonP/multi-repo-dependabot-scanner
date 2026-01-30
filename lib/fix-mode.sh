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
        local subdirs=$(find_monorepo_subdirs)
        
        if [ -n "$subdirs" ]; then
            print_info "📦 Detectado monorepo con subdirectorios"
            echo "$subdirs" | while IFS= read -r subdir; do
                echo ""
                print_info "📂 Procesando $subdir..."
                cd "$subdir" || continue
                run_fix_mode_in_directory "$alerts_json" "$alerts_count" "$auto_fixable"
                cd - > /dev/null
            done
            return
        else
            print_warning "No se detectó gestor de paquetes"
            return
        fi
    fi
    
    run_fix_mode_in_directory "$alerts_json" "$alerts_count" "$auto_fixable"
}

run_fix_mode_in_directory() {
    local alerts_json=$1
    local alerts_count=$2
    local auto_fixable=$3
    
    local pm=$(detect_package_manager)
    
    if [ "$pm" = "unknown" ]; then
        print_warning "No se detectó gestor de paquetes en este directorio"
        return
    fi
    
    echo -e "Gestor de paquetes: ${GREEN}$pm${NC}"
    
    if has_uncommitted_changes; then
        print_warning "Hay cambios sin commitear. Saltando..."
        return
    fi
    
    local default_branch=$(get_default_branch)
    print_info "📥 Sincronizando con remoto ($default_branch)..."
    git pull --rebase origin "$default_branch" 2>/dev/null || print_warning "No se pudo hacer pull (puede no tener remoto configurado)"
    
    local package_names=$(echo "$alerts_json" | jq -r 'map(select(.is_auto_fixable == true)) | .[].dependency.package.name' | sort -u | tr '\n' ', ' | sed 's/,$//')
    
    local branch_name=$(create_fix_branch "$package_names")
    
    echo ""
    print_info "🔧 Intentando reparar vulnerabilidades auto-resolvibles..."
    echo ""
    
    apply_fixes "$pm" "$alerts_json"
    
    if has_uncommitted_changes; then
        handle_commit_workflow "$alerts_count" "$branch_name" "$package_names"
    else
        checkout_main_branch
        git branch -D "$branch_name" 2>/dev/null
        print_warning "No se pudieron aplicar correcciones automáticas"
    fi
}
