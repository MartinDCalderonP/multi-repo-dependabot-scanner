#!/bin/bash

display_check_mode() {
    local alerts_json=$1
    local auto_fixable=$2
    local breaking=$3
    local unfixable=$4
    local blocked=$5
    
    read critical high medium low <<< $(get_severity_counts "$alerts_json")
    
    display_severity_summary "$critical" "$high" "$medium" "$low" \
                            "$auto_fixable" "$breaking" "$unfixable" "$blocked"
    
    echo ""
    
    if [ "$auto_fixable" -gt 0 ]; then
        echo -e "   ${GREEN}$(t section_auto_fixable)${NC}"
        display_auto_fixable_alerts "$alerts_json"
        echo ""
    fi
    
    if [ "$breaking" -gt 0 ]; then
        echo -e "   ${YELLOW}$(t section_breaking)${NC}"
        display_breaking_alerts "$alerts_json"
        echo ""
    fi

    if [ "$blocked" -gt 0 ]; then
        echo -e "   ${YELLOW}$(t section_blocked)${NC}"
        display_blocked_alerts "$alerts_json"
        echo ""
    fi
    
    if [ "$unfixable" -gt 0 ]; then
        echo -e "   ${YELLOW}$(t section_unfixable)${NC}"
        display_unfixable_alerts "$alerts_json"
    fi
}
