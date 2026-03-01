# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macOS bootstrap scripts for setting up a fresh macOS installation with development tools, applications, and system configuration.

## Commands

```bash
# Full setup
./scripts/main.sh

# Preview changes (no modifications)
./scripts/main.sh --dry-run

# Verbose output
./scripts/main.sh --verbose

# Custom config
./scripts/main.sh --config custom-config.sh

# Non-interactive mode
./scripts/main.sh --yes

# Run individual modules (setup-apps.sh and setup-dotfiles.sh support standalone flags;
# core scripts require main.sh or pre-set env vars)
./scripts/apps/setup-apps.sh
./scripts/config/setup-dotfiles.sh

# Lint (if shellcheck installed)
shellcheck scripts/**/*.sh

# Syntax check
bash -n scripts/main.sh
```

`shellcheck` and syntax checks also run in CI via `.github/workflows/ci.yml`.

## Architecture

- `install.sh` - One-liner entry point for fresh macOS; installs Xcode CLI tools, clones repo, runs main.sh
- `config.sh` - Central configuration with `export_config` function; all options have environment variable overrides
- `scripts/main.sh` - Orchestrator that runs modules via `run_module()` based on config flags
- `scripts/common.sh` - Shared utilities: logging (`info|warn|error|success`), `init_script()` (sets `set -Eeuo pipefail`, error traps, platform checks), `parse_args`, `ask_for_sudo`, `run()` for DRY_RUN-aware execution, `ensure_brew_in_path`, `resolve_repo_root`
- `scripts/core/` - System setup: macOS updates, Xcode CLI, Homebrew installation
- `scripts/apps/` - Application installation and Dock configuration
- `scripts/config/` - Dotfiles, macOS defaults
- `dotfiles/` - GNU Stow package: dotfiles symlinked to $HOME (mirrors home directory structure)
- `Brewfile` - Homebrew formulas, casks, and Mac App Store apps

## Coding Conventions

- Bash only; start with `#!/usr/bin/env bash` and call `init_script()` (which sets `set -Eeuo pipefail` with ERR trap inheritance); `install.sh` uses `set -euo pipefail` directly
- Use `common.sh` helpers for logging and utilities
- File naming: verb + scope (`install-*.sh`, `configure-*.sh`, `setup-*.sh`, `update-*.sh`)
- Functions: `lower_snake_case`; constants: `UPPER_SNAKE_CASE` with `readonly`
- All modules must be idempotent; honor `DRY_RUN` and `VERBOSE` globals
- Prefer `run` for mutating commands that should respect dry-run mode; function-level `DRY_RUN` guards are also acceptable for grouped operations

## Commit Style

Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`

Example: `feat: add macOS defaults configuration script`
