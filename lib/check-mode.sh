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
        echo -e "   ${GREEN}Alertas auto-resolvibles:${NC}"
        display_auto_fixable_alerts "$alerts_json"
        echo ""
    fi
    
    if [ "$breaking" -gt 0 ]; then
        echo -e "   ${YELLOW}Requieren actualización manual (breaking change):${NC}"
        display_breaking_alerts "$alerts_json"
        echo ""
    fi

    if [ "$blocked" -gt 0 ]; then
        echo -e "   ${YELLOW}Dependabot no puede actualizar (constraints de dependencias):${NC}"
        display_blocked_alerts "$alerts_json"
        echo ""
    fi
    
    if [ "$unfixable" -gt 0 ]; then
        echo -e "   ${YELLOW}Alertas sin versión patched:${NC}"
        display_unfixable_alerts "$alerts_json"
    fi
}
