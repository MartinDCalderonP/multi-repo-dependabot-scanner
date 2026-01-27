#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/package-managers.sh"
source "$SCRIPT_DIR/lib/alerts.sh"
source "$SCRIPT_DIR/lib/formatters.sh"
source "$SCRIPT_DIR/lib/alert-lists.sh"
source "$SCRIPT_DIR/lib/summaries.sh"
source "$SCRIPT_DIR/lib/git-operations.sh"
source "$SCRIPT_DIR/lib/repository-processing.sh"
source "$SCRIPT_DIR/lib/check-mode.sh"
source "$SCRIPT_DIR/lib/fix-mode.sh"
source "$SCRIPT_DIR/lib/commit-workflow.sh"

MODE="${1:-check}"

if [ "$(basename "$(pwd)")" = "multi-repo-dependabot-scanner" ]; then
    WORKSPACE_DIR="$(dirname "$(pwd)")"
else
    WORKSPACE_DIR="$(pwd)"
fi

total_repos=0
repos_with_alerts=0
total_alerts=0
total_fixable=0
total_breaking=0
total_unfixable=0
repos_fixed=0

main() {
    echo "🔍 Analizador de Alertas de Dependabot"
    echo "══════════════════════════════════════"
    echo ""
    
    process_repositories
    
    display_final_summary "$total_repos" "$repos_with_alerts" "$total_alerts" \
                         "$total_fixable" "$total_breaking" "$total_unfixable" \
                         "$MODE" "$repos_fixed"
}

main
