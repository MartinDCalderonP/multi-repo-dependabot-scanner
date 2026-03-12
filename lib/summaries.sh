#!/bin/bash

display_repo_header() {
    local owner=$1
    local repo=$2
    local alerts_count=$3
    
    echo ""
    print_separator
    printf "${BLUE}$(t repo_header)${NC}\n" "$owner" "$repo"
    printf "${RED}$(t alerts_found)${NC}\n" "$alerts_count"
    print_separator
}

display_severity_summary() {
    local critical=$1
    local high=$2
    local medium=$3
    local low=$4
    local auto_fixable=$5
    local breaking=$6
    local unfixable=$7
    local blocked=$8

    [ "$critical" -gt 0 ] && printf "   ${RED}$(t severity_critical)${NC}\n" "$critical"
    [ "$high" -gt 0 ] && printf "   ${RED}$(t severity_high)${NC}\n" "$high"
    [ "$medium" -gt 0 ] && printf "   ${YELLOW}$(t severity_medium)${NC}\n" "$medium"
    [ "$low" -gt 0 ] && printf "   ${BLUE}$(t severity_low)${NC}\n" "$low"
    echo ""
    [ "$auto_fixable" -gt 0 ] && printf "   ${GREEN}$(t count_auto_fixable)${NC}\n" "$auto_fixable" || echo -e "   ${YELLOW}$(t count_zero_auto_fixable)${NC}"
    [ "$breaking" -gt 0 ] && printf "   ${YELLOW}$(t count_breaking)${NC}\n" "$breaking"
    [ "$blocked" -gt 0 ] && printf "   ${YELLOW}$(t count_blocked)${NC}\n" "$blocked"
    [ "$unfixable" -gt 0 ] && printf "   ${RED}$(t count_unfixable)${NC}\n" "$unfixable"
}

display_final_summary() {
    local total_repos=$1
    local repos_with_alerts=$2
    local total_alerts=$3
    local total_fixable=$4
    local total_breaking=$5
    local total_unfixable=$6
    local mode=$7
    local repos_fixed=$8
    local total_blocked=$9

    echo ""
    echo "═══════════════════════════════════════════"
    echo -e "${BLUE}$(t summary_title)${NC}"
    echo "═══════════════════════════════════════════"
    printf "$(t summary_total_repos)\n" "$total_repos"
    printf "$(t summary_repos_with_alerts)\n" "$repos_with_alerts"
    printf "$(t summary_total_alerts)\n" "$total_alerts"

    if [ "$mode" = "check" ] || [ "$mode" = "both" ]; then
        if [ "$total_alerts" -gt 0 ]; then
            echo ""
            printf "${GREEN}$(t summary_auto_fixable)${NC}\n" "$total_fixable"
            printf "${YELLOW}$(t summary_breaking)${NC}\n" "$total_breaking"
            printf "${YELLOW}$(t summary_blocked)${NC}\n" "$total_blocked"
            printf "${RED}$(t summary_unfixable)${NC}\n" "$total_unfixable"
        fi
    fi

    if [ "$mode" = "fix" ] || [ "$mode" = "both" ]; then
        printf "$(t summary_repos_fixed)\n" "$repos_fixed"
    fi

    echo ""
}
