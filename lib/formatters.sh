#!/bin/bash

print_severity_badge() {
    local severity=$1
    local text=$2
    
    case "$severity" in
        "critical") echo -e "${BOLD_RED}[CRITICAL]${NC} $text" ;;
        "high") echo -e "${RED}[HIGH]${NC} $text" ;;
        "medium") echo -e "${YELLOW}[MEDIUM]${NC} $text" ;;
        "low") echo -e "${BLUE}[LOW]${NC} $text" ;;
    esac
}

display_alert() {
    local icon=$1
    local severity=$2
    local summary=$3
    local package=$4
    local version=$5
    
    local text="$summary - $package"
    [ -n "$version" ] && text="$text → v$version"
    
    case "$severity" in
        "critical") echo -e "   $icon ${BOLD_RED}[CRITICAL]${NC} $text" ;;
        "high") echo -e "   $icon ${RED}[HIGH]${NC} $text" ;;
        "medium") echo -e "   $icon ${YELLOW}[MEDIUM]${NC} $text" ;;
        "low") echo -e "   $icon ${BLUE}[LOW]${NC} $text" ;;
    esac
}
