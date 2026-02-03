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
            run_fix_mode_monorepo "$alerts_json" "$auto_fixable" "$subdirs"
            return
        else
            print_warning "No se detectó gestor de paquetes"
            return
        fi
    fi
    
    run_fix_mode_single "$alerts_json" "$auto_fixable" "$pm"
}

run_fix_mode_monorepo() {
    local alerts_json=$1
    local auto_fixable=$2
    local subdirs=$3
    
    local package_names=$(prepare_fix_workflow "$alerts_json")
    [ $? -ne 0 ] && return
    
    local branch_name=$(create_fix_branch "$package_names")
    
    echo ""
    print_info "🔧 Intentando reparar vulnerabilidades en todos los subdirectorios..."
    echo ""
    
    local last_pm="unknown"
    while IFS= read -r subdir; do
        echo ""
        print_info "📂 Procesando $subdir..."
        cd "$subdir" || continue
        
        local pm=$(detect_package_manager)
        if [ "$pm" != "unknown" ]; then
            printf "Gestor de paquetes: ${GREEN}%s${NC}\n" "$pm"
            apply_fixes "$pm" "$alerts_json"
            last_pm="$pm"
        fi
        
        cd - > /dev/null
    done < <(echo "$subdirs")
    
    finalize_fix_workflow "$auto_fixable" "$branch_name" "$package_names" "$last_pm"
}

run_fix_mode_single() {
    local alerts_json=$1
    local auto_fixable=$2
    local pm=$3
    
    printf "Gestor de paquetes: ${GREEN}%s${NC}\n" "$pm"
    
    local package_names=$(prepare_fix_workflow "$alerts_json")
    [ $? -ne 0 ] && return
    
    local branch_name=$(create_fix_branch "$package_names")
    
    echo ""
    print_info "🔧 Intentando reparar vulnerabilidades auto-resolvibles..."
    echo ""
    
    apply_fixes "$pm" "$alerts_json"
    
    finalize_fix_workflow "$auto_fixable" "$branch_name" "$package_names" "$pm"
}
