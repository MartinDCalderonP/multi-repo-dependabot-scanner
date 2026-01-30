# Multi-Repo Dependabot Scanner

Modular tool to scan and manage Dependabot alerts across multiple GitHub repositories with intelligent version detection and automated fixes.

## ✨ Key Features

- **🎯 Accurate Breaking Change Detection**: Detects real installed versions instead of assuming from version ranges
- **🔧 Surgical Updates**: Only updates vulnerable packages, not all dependencies
- **📦 Monorepo Support**: Automatically detects and processes monorepo subdirectories
- **🌿 Smart Branch Detection**: Auto-detects main/master branch for PRs and commits
- **📝 Descriptive Commits**: Includes package names in commits, PRs, and branch names
- **♻️ DRY Architecture**: Modular and maintainable code
- **🔒 Secure**: No hardcoded credentials, uses GitHub CLI authentication

## 📁 Project Structure

```
multi-repo-dependabot-scanner/
├── dependabot-manager.sh          # Main orchestrator
├── lib/
│   ├── colors.sh                 # Color definitions
│   ├── utils.sh                  # General utilities
│   ├── package-managers.sh       # Package detection
│   ├── package-fixes.sh          # Fix operations
│   ├── alerts.sh                 # Alert enrichment
│   ├── formatters.sh             # Alert formatting
│   ├── alert-lists.sh            # Alert displays
│   ├── message-builders.sh       # Commit/PR messages
│   ├── summaries.sh              # Report summaries
│   ├── git-operations.sh         # Git commands
│   ├── repository-processing.sh  # Repo iteration
│   ├── check-mode.sh             # Check display
│   ├── fix-workflow.sh           # Fix workflow helpers
│   ├── fix-mode.sh               # Fix orchestration
│   └── commit-workflow.sh        # Interactive workflow
└── README.md
```

**✅ All 16 modules**

## 🚀 Usage

The script automatically detects its location and analyzes repositories:

```bash
# From the parent directory containing repos
cd /path/to/repos
./multi-repo-dependabot-scanner/dependabot-manager.sh check

# Or from within the script directory (auto-detects parent)
cd multi-repo-dependabot-scanner
./dependabot-manager.sh check
```

Commands:

- `check` - Display alerts only
- `fix` - Attempt to fix auto-resolvable alerts
- `both` - Check and fix in sequence

**Smart Detection:** If run from `multi-repo-dependabot-scanner/`, it automatically analyzes sibling directories in the parent folder.

## 🎯 How It Works

### Workflow Overview

1. **Repository Discovery**: Scans sibling directories or specified path
2. **Alert Fetching**: Uses GitHub CLI to fetch Dependabot alerts
3. **Version Enrichment**: Extracts real installed versions from package managers (`pnpm why`, `yarn list`, `npm list`)
4. **Classification**: Analyzes if updates are auto-fixable or breaking changes based on real versions
5. **Fix Application** (fix mode):
   - Syncs with remote main/master branch
   - Creates descriptive branch with package names
   - Applies targeted updates only to vulnerable packages
   - Shows changes and prompts user for confirmation
   - If confirmed: commits, pushes, and creates PR with descriptive messages
   - If rejected: discards changes, deletes temporary branch, and returns to main

### Monorepo Support

Automatically detects monorepo structures:

- Checks for `package.json` in subdirectories when root lacks it
- Processes all subdirectories with a single branch
- Creates one consolidated PR with all changes from all subdirectories
- Enriches alerts with correct versions from each workspace

### Breaking Change Detection

- Compares **real installed major version** vs **patched major version**
- Auto-fixable: `patched_major <= current_major` (e.g., 8.57.1 → 8.60.0)
- Breaking change: `patched_major > current_major` (e.g., 8.57.1 → 9.26.0)
- No false positives from version range assumptions

## 📦 Modules

Main orchestrator that loads all modules and executes the workflow

### `dependabot-manager.sh`

Main orchestrator that loads all 15 modules and executes `main()`

### `colors.sh`

Terminal color constants for formatted output

### `utils.sh` ✨ DRY

Reusable utility functions:

- `prompt_yes_no()` - Interactive yes/no prompts
- `print_success()`, `print_warning()`, `print_info()`, `print_error()` - Colored messages
- `print_separator()` - Visual separators

### `package-managers.sh`

Package manager detection and operations:

- `detect_package_manager()` - Detects npm/yarn/pnpm by lockfile
- `find_monorepo_subdirs()` - Finds subdirectories with package.json
- `get_installed_version()` - Extracts real installed version from package manager
- `fix_vulnerabilities()` - Runs audit fix + targeted updates
- `add_yarn_resolutions()` - Adds Yarn resolutions to package.json

### `package-fixes.sh`

Fix orchestration:

- `apply_fixes()` - Applies fixes and shows results
- `apply_yarn_resolutions()` - Iterates alerts and adds Yarn resolutions

### `alerts.sh`

Alert enrichment and classification:

- `enrich_alerts_with_versions()` - Adds `installed_version`, `current_major`, `patched_major`, `is_auto_fixable`, `is_breaking` to alerts
- `calculate_alert_metrics()` - Uses pre-computed fields for metrics
- `get_severity_counts()` - Counts by severity level

### `formatters.sh`

Alert formatting:

- `print_severity_badge()` - Colored severity badges
- `display_alert()` - Consistent alert display format (DRY)

### `alert-lists.sh`

Alert lists by category:

- `display_alerts_by_version_comparison()` - Generic display using `is_auto_fixable`/`is_breaking`
- `display_auto_fixable_alerts()` - Wrapper for auto-fixable
- `display_breaking_alerts()` - Wrapper for breaking changes
- `display_unfixable_alerts()` - Alerts without patches

### `message-builders.sh`

Commit and PR message generation:

- `build_fix_title()` - Creates "fix: update package1, package2"
- `build_package_list()` - Markdown list of packages
- `build_branch_name()` - Creates "fix/dependabot-packages-date"

### `check-mode.sh`

Check mode display:

- `display_check_mode()` - Shows categorized alerts without fixes

### `fix-workflow.sh`

Fix workflow helpers:

- `prepare_fix_workflow()` - Validates state, syncs with remote, extracts package names
- `finalize_fix_workflow()` - Handles commit workflow or cleanup if no changes

### `fix-mode.sh`

Automatic fix orchestration:

- `run_fix_mode()` - Detects monorepo vs single repo and delegates
- `run_fix_mode_monorepo()` - Processes all subdirectories with single PR
- `run_fix_mode_single()` - Processes single repository

### `commit-workflow.sh`

Interactive Git workflow:

- `handle_commit_workflow()` - Shows changes and prompts user with validation
- `execute_full_workflow()` - Executes commit → push → PR

### `summaries.sh`

Report summaries and headers:

- `display_repo_header()` - Repository header with alert count
- `display_severity_summary()` - Severity breakdown
- `display_final_summary()` - Overall statistics

### `git-operations.sh`

Git operations:

- `get_default_branch()` - Detects main/master branch
- `create_fix_branch()` - Creates branch with package names
- `commit_fixes()` - Commits with descriptive message
- `push_branch()`, `create_pull_request()` - Push and PR creation
- `checkout_main_branch()`, `discard_changes()`, `delete_branch()`, `has_uncommitted_changes()`

### `repository-processing.sh`

Repository processing:

- `process_repositories()` - Iterates workspace directories
- `process_single_repository()` - Fetches alerts from GitHub API
- `process_alerts()` - Enriches alerts (with monorepo support) and displays/fixes

## 📊 Output Example

```
📦 Repositorio: username/my-app
🚨 4 alertas encontradas
═══════════════════════════════════════════
   ⚠️  2 altas
   ⚠️  2 medias

   ✓ 3 auto-resolvibles
   ⚠ 1 requieren actualización manual (breaking change)

   Alertas auto-resolvibles:
   ✓ [HIGH] Vulnerability in tar - tar → v7.5.7
   ✓ [MEDIUM] Issue in micromatch - micromatch → v4.0.8
   ✓ [MEDIUM] Issue in path-to-regexp - path-to-regexp → v0.1.12

   Requieren actualización manual (breaking change):
   ⚠ [HIGH] eslint Stack Overflow - eslint → v9.26.0
```

## 🔧 Requirements

- GitHub CLI (`gh`) installed and authenticated
- `jq` for JSON processing
- npm/yarn/pnpm depending on your projects

## 🔒 Security

- No hardcoded paths or credentials
- Uses GitHub CLI authentication (managed locally)
- Safe to share and publish publicly
- Only updates explicitly vulnerable packages
