# Multi-Repo Dependabot Scanner

Modular tool to scan and manage Dependabot alerts across multiple GitHub repositories with intelligent version detection and automated fixes.

## ✨ Key Features

- **🎯 Accurate Breaking Change Detection**: Detects real installed versions instead of assuming from version ranges. For `0.x` packages, minor bumps are treated as breaking (e.g. `0.4 → 0.6`)
- **⊘ Blocked Alert Detection**: Uses GitHub GraphQL API to detect alerts Dependabot cannot fix due to dependency constraints or timeouts (`security_update_not_possible`, `dependabot_timed_out`)
- **🔧 Surgical Updates**: Only updates vulnerable packages, not all dependencies
- **📦 Monorepo Support**: Automatically detects and processes monorepo subdirectories
- **🧶 Yarn Berry Support**: Parses yarn.lock directly for transitive dependency versions (Yarn v2+)
- **🎯 Single Repo Mode**: Target specific repositories with optional parameter
- **🌿 Smart Branch Detection**: Auto-detects main/master/develop branch for PRs and commits
- **📝 Dynamic PR Descriptions**: Package manager-specific descriptions with accurate alert counts
- **🔗 PR Links Collection**: Displays all created PR URLs at the end for quick access
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
│   ├── yarn-fixes.sh             # Yarn-specific operations
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

## 🌐 Language

The tool defaults to **English**. Set `SCRIPT_LANG=es` to switch to Spanish:

```bash
SCRIPT_LANG=es ./dependabot-manager.sh check
```

Locale files are in `locales/en.json` and `locales/es.json`.

## 🚀 Usage

The script automatically detects its location and analyzes repositories:

```bash
# Check all repositories in parent directory
cd /path/to/repos
./multi-repo-dependabot-scanner/dependabot-manager.sh check

# Check specific repository only
./multi-repo-dependabot-scanner/dependabot-manager.sh check my-repo-name

# Fix all repositories
./multi-repo-dependabot-scanner/dependabot-manager.sh fix

# Fix specific repository only
./multi-repo-dependabot-scanner/dependabot-manager.sh fix my-repo-name

# Or from within the script directory (auto-detects parent)
cd multi-repo-dependabot-scanner
./dependabot-manager.sh check
./dependabot-manager.sh check specific-repo
```

Commands:

- `check [repo]` - Display alerts only (optionally for specific repo)
- `fix [repo]` - Attempt to fix auto-resolvable alerts (optionally for specific repo)
- `both [repo]` - Check and fix in sequence (optionally for specific repo)

**Smart Detection:** If run from `multi-repo-dependabot-scanner/`, it automatically analyzes sibling directories in the parent folder.

## 🎯 How It Works

### Workflow Overview

1. **Repository Discovery**: Scans sibling directories or specified repository
2. **Alert Fetching**: Uses GitHub CLI to fetch Dependabot alerts
3. **Version Enrichment**: Extracts real installed versions (pnpm/npm/yarn v1/yarn Berry)
4. **Classification**: Analyzes if updates are auto-fixable or breaking changes
5. **Fix Application** (fix mode):
   - Syncs with remote (main/master/develop)
   - Creates descriptive branch
   - Applies targeted updates to vulnerable packages
   - Automatically creates commit, push, and PR
6. **PR Collection**: Displays all created PR URLs at the end

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

### `utils.sh`

Reusable utility functions for prompts, pluralization, git checks, and colored output.

### `package-managers.sh`

Package manager detection and operations:

- `detect_package_manager()` - Detects npm/yarn/pnpm by lockfile
- `find_monorepo_subdirs()` - Finds subdirectories with package.json
- `get_installed_version()` - Extracts real installed version (Yarn Berry parses yarn.lock directly)
- `fix_vulnerabilities()` - Runs fixes specific to each PM

### `yarn-fixes.sh`

Yarn-specific operations:

- `add_yarn_resolutions()` - Adds Yarn resolutions to package.json for transitive deps

### `package-fixes.sh`

Fix orchestration:

- `apply_fixes()` - Applies fixes and shows results
- `apply_yarn_resolutions()` - Iterates alerts and adds Yarn resolutions

### `alerts.sh`

Alert enrichment with real versions and classification (auto-fixable/breaking/unfixable).

### `dependabot-status.sh`

GraphQL-based enrichment to detect alerts blocked by Dependabot errors (`security_update_not_possible`, `dependabot_timed_out`).

### `formatters.sh`

Alert formatting and colored severity badges.

### `alert-lists.sh`

Alert displays by category (auto-fixable, breaking, unfixable).

### `message-builders.sh`

Commit and PR message generation with package manager-specific descriptions.

### `check-mode.sh`

Check mode display without fixes.

### `fix-workflow.sh`

Fix workflow preparation and finalization.

### `fix-mode.sh`

Automatic fix orchestration for single repos and monorepos.

### `commit-workflow.sh`

Automatic Git workflow execution (commit, push, PR creation).

### `summaries.sh`

Report summaries and statistics.

### `git-operations.sh`

Git operations including branch detection (main/master/develop), PR creation with dynamic descriptions, and URL collection.

### `repository-processing.sh`

Repository processing for all or single specified repos with alert fetching and enrichment.

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

   Dependabot no puede actualizar (constraints de dependencias):
      Sin versión compatible posible:
   ⊘ [HIGH] node-tar Symlink Path Traversal - tar → v7.5.11
      Timeout de Dependabot:
   ⊘ [HIGH] urllib3 vulnerability - urllib3 → v2.6.0
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
