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
            echo -e "${RED}Por favor responde 'y' (sí) o 'n' (no)${NC}"
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
