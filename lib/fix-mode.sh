#!/bin/bash

run_fix_mode() {
    local alerts_json=$1
    local alerts_count=$2
    local auto_fixable=$3
    local fix_candidates

    fix_candidates=$(echo "$alerts_json" | jq '[.[] | select(.is_auto_fixable == true or (.is_blocked == true and .blocked_reason != "dependabot_timed_out" and .security_vulnerability.first_patched_version.identifier != null))] | length' 2>/dev/null)
    
    if [ "$fix_candidates" -eq 0 ]; then
        read manual_review timed_out blocked_without_patch <<< $(get_fix_reason_counts "$alerts_json")

        print_warning "$(t skip_no_fix_candidates)"

        [ "$manual_review" -gt 0 ] && print_warning "$(printf "$(t skip_manual_review_needed)" "$manual_review")"
        [ "$timed_out" -gt 0 ] && print_info "$(printf "$(t skip_timed_out_retry)" "$timed_out")"
        [ "$blocked_without_patch" -gt 0 ] && print_warning "$(printf "$(t skip_blocked_without_patch)" "$blocked_without_patch")"

        return
    fi
    
    local pm=$(detect_package_manager)
    
    if [ "$pm" = "unknown" ]; then
        local subdirs=$(find_monorepo_subdirs)
        
        if [ -n "$subdirs" ]; then
            print_info "$(t monorepo_detected)"
            run_fix_mode_monorepo "$alerts_json" "$auto_fixable" "$subdirs"
            return
        else
            print_warning "$(t no_pm_detected)"
            return
        fi
    fi
    
    run_fix_mode_single "$alerts_json" "$fix_candidates" "$pm"
}

run_fix_mode_monorepo() {
    local alerts_json=$1
    local auto_fixable=$2
    local subdirs=$3
    
    local package_names=$(prepare_fix_workflow "$alerts_json")
    [ $? -ne 0 ] && return
    
    local branch_name=$(create_fix_branch "$package_names")
    
    echo ""
    print_info "$(t fixing_subdirs)"
    echo ""
    
    local last_pm="unknown"
    while IFS= read -r subdir; do
        echo ""
        print_info "$(printf "$(t processing_subdir)" "$subdir")"
        cd "$subdir" || continue
        
        local pm=$(detect_package_manager)
        if [ "$pm" != "unknown" ]; then
printf "$(t pm_label): ${GREEN}%s${NC}\n" "$pm"
            apply_fixes "$pm" "$alerts_json"
            last_pm="$pm"
        fi

        cd - > /dev/null
    done < <(echo "$subdirs")

    finalize_fix_workflow "$auto_fixable" "$branch_name" "$package_names" "$last_pm"
}

run_fix_mode_single() {
    local alerts_json=$1
    local auto_fixable=$2
    local pm=$3

    printf "$(t pm_label): ${GREEN}%s${NC}\n" "$pm"
    
    local package_names=$(prepare_fix_workflow "$alerts_json")
    [ $? -ne 0 ] && return
    
    local branch_name=$(create_fix_branch "$package_names")
    
    echo ""
    print_info "$(t fixing_auto)"
    echo ""
    
    apply_fixes "$pm" "$alerts_json"
    
    finalize_fix_workflow "$auto_fixable" "$branch_name" "$package_names" "$pm"
}
