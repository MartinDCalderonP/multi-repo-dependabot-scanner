#!/bin/bash

prompt_yes_no() {
    local question=$1
    local var_name=$2
    
    while true; do
        echo -en "${YELLOW}$question (y/n) ${NC}"
        read -r response < /dev/tty
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            eval "$var_name=true"
            return 0
        elif [[ "$response" =~ ^[Nn]$ ]]; then
            eval "$var_name=false"
            return 1
        else
            echo -e "${RED}$(t invalid_yn)${NC}"
        fi
    done
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}$1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_separator() {
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
}

pluralize() {
    local count=$1
    local singular=$2
    local plural=${3:-${singular}s}
    
    if [ "$count" -eq 1 ]; then
        echo "$singular"
    else
        echo "$plural"
    fi
}

has_uncommitted_changes() {
    git diff-index --quiet HEAD -- 2>/dev/null
    [ $? -ne 0 ]
}

cleanup_pnpm_files() {
    local context=${1:-""}
    local removed_files=()

    if [ -f "pnpm-lock.yaml" ]; then
        rm -f "pnpm-lock.yaml"
        removed_files+=("pnpm-lock.yaml")
    fi

    if [ -f "pnpm-workspace.yaml" ]; then
        rm -f "pnpm-workspace.yaml"
        removed_files+=("pnpm-workspace.yaml")
    fi

    if [ ${#removed_files[@]} -gt 0 ]; then
        if [ -n "$context" ]; then
            print_info "$(printf "$(t cleanup_with_ctx)" "$context" "${removed_files[*]}")" >&2
        else
            print_info "$(printf "$(t cleanup_no_ctx)" "${removed_files[*]}")" >&2
        fi
    fi
}
