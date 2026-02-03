#!/bin/bash

prepare_fix_workflow() {
    local alerts_json=$1
    
    if has_uncommitted_changes; then
        print_warning "Hay cambios sin commitear. Saltando..." >&2
        return 1
    fi
    
    local default_branch=$(get_default_branch)
    print_info "📥 Sincronizando con remoto ($default_branch)..." >&2
    git pull --rebase origin "$default_branch" >&2 || print_warning "No se pudo hacer pull (puede no tener remoto configurado)" >&2
    
    local package_names=$(echo "$alerts_json" | jq -r 'map(select(.is_auto_fixable == true)) | .[].dependency.package.name' | sort -u | tr '\n' ', ' | sed 's/,$//')
    
    echo "$package_names"
}

finalize_fix_workflow() {
    local alerts_count=$1
    local branch_name=$2
    local package_names=$3
    
    if has_uncommitted_changes; then
        handle_commit_workflow "$alerts_count" "$branch_name" "$package_names"
    else
        checkout_main_branch
        delete_branch "$branch_name"
        print_warning "No se pudieron aplicar correcciones automáticas"
    fi
}
