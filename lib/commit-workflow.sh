#!/bin/bash

handle_commit_workflow() {
    local alerts_count=$1
    local branch_name=$2
    local package_names=$3
    
    repos_fixed=$((repos_fixed + 1))
    
    echo ""
    print_success "✨ Se realizaron actualizaciones"
    echo ""
    
    git status
    echo ""
    git diff package.json | head -50
    echo ""
    
    if prompt_yes_no "¿Crear commit, push y PR?" create_all; then
        execute_full_workflow "$alerts_count" "$branch_name" "$package_names"
    else
        checkout_main_branch
        discard_changes
        delete_branch "$branch_name"
        print_warning "Cambios descartados"
    fi
}

execute_full_workflow() {
    local alerts_count=$1
    local branch_name=$2
    local package_names=$3
    
    if ! commit_fixes "$alerts_count" "$package_names"; then
        checkout_main_branch
        return 1
    fi
    
    print_success "Commit creado en rama $branch_name"
    
    if push_branch "$branch_name"; then
        print_success "Push realizado"
        
        if create_pull_request "$alerts_count" "$package_names"; then
            print_success "Pull Request creado"
        else
            print_warning "No se pudo crear el PR (puede que ya exista)"
        fi
    else
        print_warning "No se pudo hacer push"
    fi
    
    checkout_main_branch
}
