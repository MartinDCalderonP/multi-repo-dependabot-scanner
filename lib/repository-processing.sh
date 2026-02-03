#!/bin/bash

process_repositories() {
    if [ -n "$SPECIFIC_REPO" ]; then
        local target_dir="$WORKSPACE_DIR/$SPECIFIC_REPO"
        
        if [ ! -d "$target_dir" ]; then
            print_warning "No se encontró el repositorio: $SPECIFIC_REPO"
            return
        fi
        
        if [ ! -d "${target_dir}/.git" ]; then
            print_warning "$SPECIFIC_REPO no es un repositorio git"
            return
        fi
        
        print_info "📂 Procesando repositorio específico: $SPECIFIC_REPO"
        echo ""
        
        total_repos=1
        cd "$target_dir" || return
        process_single_repository
    else
        for dir in "$WORKSPACE_DIR"/*/; do
            [ -d "${dir}.git" ] || continue
            
            total_repos=$((total_repos + 1))
            cd "$dir" || continue
            
            process_single_repository
        done
    fi
}

process_single_repository() {
    local remote_url=$(git remote get-url origin 2>/dev/null)
    [ -z "$remote_url" ] && return
    
    # Extract owner/repo from GitHub URL
    if [[ $remote_url =~ github.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
        local owner="${BASH_REMATCH[1]}"
        local repo="${BASH_REMATCH[2]%.git}"
        
        local alerts_json=$(gh api "/repos/$owner/$repo/dependabot/alerts?state=open" 2>/dev/null)
        [ $? -ne 0 ] && return
        
        local alerts_count=$(echo "$alerts_json" | jq 'length' 2>/dev/null)
        
        if [ "$alerts_count" -eq 0 ]; then
            [ "$MODE" = "check" ] || [ "$MODE" = "both" ] && \
                echo -e "${BLUE}📦 $owner/$repo${NC} - ${GREEN}✅ Sin alertas${NC}"
            return
        fi
        
        repos_with_alerts=$((repos_with_alerts + 1))
        total_alerts=$((total_alerts + alerts_count))
        
        process_alerts "$owner" "$repo" "$alerts_json" "$alerts_count"
    fi
}

process_alerts() {
    local owner=$1
    local repo=$2
    local alerts_json=$3
    local alerts_count=$4
    
    local pm=$(detect_package_manager)
    
    if [ "$pm" = "unknown" ]; then
        local subdirs=$(find_monorepo_subdirs | head -1)
        
        if [ -n "$subdirs" ]; then
            cd "$subdirs" 2>/dev/null || true
            pm=$(detect_package_manager)
            if [ "$pm" != "unknown" ]; then
                alerts_json=$(enrich_alerts_with_versions "$alerts_json" "$pm")
            fi
            cd - > /dev/null
        fi
    else
        alerts_json=$(enrich_alerts_with_versions "$alerts_json" "$pm")
    fi
    
    read auto_fixable breaking unfixable <<< $(calculate_alert_metrics "$alerts_json" "$alerts_count")
    
    total_fixable=$((total_fixable + auto_fixable))
    total_breaking=$((total_breaking + breaking))
    total_unfixable=$((total_unfixable + unfixable))
    
    display_repo_header "$owner" "$repo" "$alerts_count"
    
    if [ "$MODE" = "check" ]; then
        display_check_mode "$alerts_json" "$auto_fixable" "$breaking" "$unfixable"
    fi
    
    if [ "$MODE" = "fix" ] || [ "$MODE" = "both" ]; then
        run_fix_mode "$alerts_json" "$alerts_count" "$auto_fixable"
    fi
    
    echo ""
}
