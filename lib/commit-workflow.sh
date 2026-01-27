#!/bin/bash

handle_commit_workflow() {
    local alerts_count=$1
    
    repos_fixed=$((repos_fixed + 1))
    
    echo ""
    print_success "✨ Se realizaron actualizaciones"
    echo ""
    
    prompt_review_changes
    prompt_create_commit "$alerts_count"
}

prompt_review_changes() {
    if prompt_yes_no "¿Revisar cambios?" review; then
        git status
        echo ""
        git diff package.json | head -50
        echo ""
    fi
}

prompt_create_commit() {
    local alerts_count=$1
    
    if prompt_yes_no "¿Crear commit y rama?" create_commit; then
        execute_commit_workflow "$alerts_count"
    else
        discard_changes
        print_warning "Cambios descartados"
    fi
}

execute_commit_workflow() {
    local alerts_count=$1
    local branch_name=$(create_fix_branch)
    
    commit_fixes "$alerts_count"
    print_success "Commit creado en rama $branch_name"
    
    prompt_push "$branch_name" "$alerts_count"
}

prompt_push() {
    local branch_name=$1
    local alerts_count=$2
    
    echo ""
    if prompt_yes_no "¿Hacer push?" do_push; then
        push_branch "$branch_name"
        print_success "Push realizado"
        
        prompt_create_pr "$alerts_count"
    fi
    
    checkout_main_branch
}

prompt_create_pr() {
    local alerts_count=$1
    
    echo ""
    if prompt_yes_no "¿Crear Pull Request?" create_pr; then
        create_pull_request "$alerts_count"
        print_success "Pull Request creado"
    fi
}
