#!/bin/bash

apply_fixes() {
    local pm=$1
    local alerts_json=$2
    
    fix_vulnerabilities "$pm" "$alerts_json"
    apply_yarn_resolutions "$pm" "$alerts_json"
    
    if has_uncommitted_changes; then
        print_success "$(t fixes_applied)"
    else
        print_warning "$(t fixes_failed_indirect)"
    fi
}

apply_yarn_resolutions() {
    local pm=$1
    local alerts_json=$2
    
    [ "$pm" != "yarn" ] && return
    
    echo ""
    print_info "$(t checking_remaining)"
    
    echo "$alerts_json" | jq -c '.[]' | while read -r alert; do
        local package_name=$(echo "$alert" | jq -r '.dependency.package.name')
        local patched_version=$(echo "$alert" | jq -r '.security_vulnerability.first_patched_version.identifier // empty')
        local patched_major=$(echo "$patched_version" | cut -d'.' -f1)
        
        if [ -n "$patched_version" ] && [ "$patched_major" -lt 2 ] 2>/dev/null; then
            printf "   ${CYAN}$(t adding_resolution)${NC}\n" "$package_name"
            add_yarn_resolutions "$package_name" "$patched_version"
        fi
    done
    
    if has_uncommitted_changes; then
        echo ""
        print_info "$(t reinstalling)"
        yarn install 2>/dev/null
    fi
}

fix_pnpm_overrides() {
    local details=$1 yaml="pnpm-workspace.yaml"
    [ ! -f "$yaml" ] && return
    while IFS=$'\t' read -r pkg _ ver; do
        [ -z "$pkg" ] || [ -z "$ver" ] && continue
        local safe_pkg="${pkg//./\\.}"
        while IFS= read -r line; do
            if [[ "$line" =~ ^([[:space:]]*)(\"?)(${safe_pkg})(\"?): ]]; then
                printf '%s%s%s%s: %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$pkg" "${BASH_REMATCH[4]}" "$ver"
            else
                printf '%s\n' "$line"
            fi
        done < "$yaml" > "${yaml}.tmp"
        mv "${yaml}.tmp" "$yaml"
    done <<< "$details"
}
