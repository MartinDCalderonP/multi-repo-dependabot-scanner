#!/bin/bash

set -euo pipefail

FIXED_BRANCH_SUFFIX="20250101-120000"
_git_mock_diff_cached_count=0

build_git_mock() {
    _gm_symbolic_ref="${1}"
    _gm_show_ref_mode="${2:-fail}"
    _gm_show_ref_branch="${3:-}"
    _gm_branch_create_fail="${4:-0}"
    _gm_checkout_create_fail="${5:-0}"
    _gm_show_current="${6:-main}"

    git() {
        case "$1" in
            symbolic-ref) echo "$_gm_symbolic_ref"; return 0 ;;
            show-ref)
                case "$_gm_show_ref_mode" in
                    match)
                        case "$*" in
                            *"$_gm_show_ref_branch"*) return 0 ;;
                            *) return 1 ;;
                        esac
                        ;;
                esac
                return 1
                ;;
            branch)
                case "${2:-}" in
                    -b) return "$_gm_branch_create_fail" ;;
                    -D) return 0 ;;
                    --show-current) echo "$_gm_show_current"; return 0 ;;
                esac
                return 0
                ;;
            checkout)
                if [ "${2:-}" = "-b" ] && [ "$_gm_checkout_create_fail" -gt 0 ]; then
                    return 1
                fi
                return 0
                ;;
            add) return 0 ;;
            diff)
                if [ "${2:-}" = "--cached" ]; then
                    if [ "$_git_mock_diff_cached_count" -gt 0 ]; then
                        echo "diff --git a/foo b/foo"
                        return 1
                    fi
                    return 0
                fi
                echo "diff --git a/foo b/foo"
                return 0
                ;;
            commit) return 0 ;;
            push) return 0 ;;
            remote) return 0 ;;
            clean) return 0 ;;
        esac
        return 0
    }
}
