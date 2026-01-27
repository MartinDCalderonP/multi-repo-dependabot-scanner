# Multi-Repo Dependabot Scanner

Modular tool to scan and manage Dependabot alerts across multiple GitHub repositories.

## 📁 Project Structure

```
multi-repo-dependabot-scanner/
├── dependabot-manager.sh       # Main script (~250 lines)
├── lib/
│   ├── colors.sh              # Color definitions (8 lines)
│   ├── package-managers.sh    # Package operations (57 lines)
│   ├── alerts.sh              # Alert analysis (29 lines)
│   ├── formatters.sh          # Alert formatting (31 lines)
│   ├── alert-lists.sh         # Alert lists (37 lines)
│   ├── summaries.sh           # Summaries and headers (67 lines)
│   └── git-operations.sh      # Git operations (63 lines)
└── README.md
```

**✅ All files < 100 lines**

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

## 📦 Modules

### `dependabot-manager.sh` (50 lines)

Main script that loads modules and executes `main()`

### `colors.sh` (10 lines)

Terminal color constants

### `utils.sh` (45 lines) ✨ DRY

Reusable utility functions:

- `prompt_yes_no()` - Interactive yes/no prompt
- `print_success()` - Success message
- `print_warning()` - Warning message
- `print_info()` - Info message
- `print_error()` - Error message
- `print_separator()` - Separator line

### `package-managers.sh` (54 lines)

Package manager management:

- `detect_package_manager()` - Detects npm/yarn/pnpm
- `fix_vulnerabilities()` - Runs audit fix
- `add_yarn_resolutions()` - Adds resolutions to package.json

### `alerts.sh` (31 lines)

Alert analysis:

- `calculate_alert_metrics()` - Calculates metrics
- `get_severity_counts()` - Counts by severity

### `formatters.sh` (33 lines)

Alert formatting:

- `print_severity_badge()` - Severity badge
- `display_alert()` - Consistent format (DRY)

### `alert-lists.sh` (33 lines)

Alert lists by category:

- `display_auto_fixable_alerts()`
- `display_breaking_alerts()`
- `display_unfixable_alerts()`

### `check-mode.sh` (34 lines)

Check mode:

- `display_check_mode()` - Shows categorized alerts

### `summaries.sh` (68 lines)

Summaries and headers:

- `display_repo_header()`
- `display_severity_summary()`
- `display_final_summary()`

### `git-operations.sh` (59 lines)

Git operations:

- `create_fix_branch()`, `commit_fixes()`
- `push_branch()`, `create_pull_request()`
- `has_uncommitted_changes()`

### `repository-processing.sh` (67 lines)

Repository processing:

- `process_repositories()` - Iterates repos
- `process_single_repository()` - Fetches alerts
- `process_alerts()` - Calculates metrics

### `fix-mode.sh` (80 lines)

Automatic fixes:

- `run_fix_mode()` - Executes fixes
- `apply_fixes()` - Applies audit fix
- `apply_yarn_resolutions()` - Yarn resolutions

### `commit-workflow.sh` (71 lines)

Interactive Git workflow:

- `handle_commit_workflow()` - Main orchestrator
- `prompt_review_changes()` - Review changes
- `prompt_create_commit()` - Create commit
- `execute_commit_workflow()` - Execute workflow
- `prompt_push()` - Push to remote
- `prompt_create_pr()` - Create PR

## ✨ Refactoring Benefits

### 1. **Separation of Concerns**

Each module has a clear and unique responsibility.

### 2. **DRY (Don't Repeat Yourself)**

- `display_alert()` function reused for all alert types
- Centralized color logic
- Shared Git operations

### 3. **Maintainability**

- Easy to locate and modify specific functionality
- Changes in one module don't affect others

### 4. **Testable**

Each module can be tested independently.

### 5. **Extensible**

Easy to add new package managers or alert types.

## � Requirements

- GitHub CLI (`gh`) installed and authenticated
- `jq` for JSON processing
- npm/yarn/pnpm depending on your projects

## 🔒 Security

- No hardcoded paths or credentials
- Uses GitHub CLI authentication (managed locally)
- Safe to share and publish publicly
