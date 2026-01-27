#!/bin/bash

prompt_yes_no() {
    local question=$1
    local var_name=$2
    
    echo -e "${YELLOW}$question (y/n)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        eval "$var_name=true"
        return 0
    else
        eval "$var_name=false"
        return 1
    fi
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
