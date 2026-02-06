#!/bin/bash

handle_commit_workflow() {
    local auto_fixable=$1
    local branch_name=$2
    local package_names=$3
    local pm=$4
    
    repos_fixed=$((repos_fixed + 1))
    
    echo ""
    print_success "✨ Se realizaron actualizaciones"
    echo ""
    
    git status
    echo ""
    git diff package.json | head -50
    echo ""
    
    print_info "🚀 Creando commit, push y PR..."
    execute_full_workflow "$auto_fixable" "$branch_name" "$package_names" "$pm"
}

execute_full_workflow() {
    local auto_fixable=$1
    local branch_name=$2
    local package_names=$3
    local pm=$4
    
    if ! commit_fixes "$auto_fixable" "$package_names"; then
        checkout_main_branch
        return 1
    fi
    
    print_success "Commit creado en rama $branch_name"
    
    if push_branch "$branch_name"; then
        print_success "Push realizado"
        
        if create_pull_request "$auto_fixable" "$package_names" "$pm"; then
            print_success "Pull Request creado"
        else
            print_warning "No se pudo crear el PR (puede que ya exista)"
        fi
    else
        print_warning "No se pudo hacer push"
    fi
    
    checkout_main_branch
}
