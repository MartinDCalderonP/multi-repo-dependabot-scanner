#!/bin/bash

display_repo_header() {
    local owner=$1
    local repo=$2
    local alerts_count=$3
    
    echo ""
    print_separator
    echo -e "${BLUE}📦 Repositorio: $owner/$repo${NC}"
    echo -e "${RED}🚨 $alerts_count alertas encontradas${NC}"
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

    [ "$critical" -gt 0 ] && echo -e "   ${RED}⛔ $critical críticas${NC}"
    [ "$high" -gt 0 ] && echo -e "   ${RED}⚠️  $high altas${NC}"
    [ "$medium" -gt 0 ] && echo -e "   ${YELLOW}⚠️  $medium medias${NC}"
    [ "$low" -gt 0 ] && echo -e "   ${BLUE}ℹ️  $low bajas${NC}"
    echo ""
    [ "$auto_fixable" -gt 0 ] && echo -e "   ${GREEN}✓ $auto_fixable auto-resolvibles${NC}" || echo -e "   ${YELLOW}⚠ 0 auto-resolvibles${NC}"
    [ "$breaking" -gt 0 ] && echo -e "   ${YELLOW}⚠ $breaking requieren actualización manual (breaking change)${NC}"
    [ "$blocked" -gt 0 ] && echo -e "   ${YELLOW}⊘ $blocked bloqueadas por Dependabot (constraints)${NC}"
    [ "$unfixable" -gt 0 ] && echo -e "   ${RED}✗ $unfixable sin versión patched${NC}"
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
    echo -e "${BLUE}📊 RESUMEN FINAL${NC}"
    echo "═══════════════════════════════════════════"
    echo "Total de repositorios: $total_repos"
    echo "Repositorios con alertas: $repos_with_alerts"
    echo "Total de alertas: $total_alerts"

    if [ "$mode" = "check" ] || [ "$mode" = "both" ]; then
        if [ "$total_alerts" -gt 0 ]; then
            echo ""
            echo -e "${GREEN}✓ Auto-resolvibles: $total_fixable${NC}"
            echo -e "${YELLOW}⚠ Requieren actualización manual (breaking): $total_breaking${NC}"
            echo -e "${YELLOW}⊘ Bloqueadas por Dependabot (constraints): $total_blocked${NC}"
            echo -e "${RED}✗ Sin versión patched: $total_unfixable${NC}"
        fi
    fi

    if [ "$mode" = "fix" ] || [ "$mode" = "both" ]; then
        echo "Repositorios actualizados: $repos_fixed"
    fi

    echo ""
}
