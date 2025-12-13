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

# Run individual modules
./scripts/core/install-homebrew.sh
./scripts/apps/setup-apps.sh
./scripts/config/setup-dotfiles.sh

# Lint (if shellcheck installed)
shellcheck scripts/**/*.sh

# Syntax check
bash -n scripts/main.sh
```

## Architecture

- `install.sh` - One-liner entry point for fresh macOS; installs Xcode CLI tools, clones repo, runs main.sh
- `config.sh` - Central configuration with `export_config` function; all options have environment variable overrides
- `scripts/main.sh` - Orchestrator that runs modules via `run_module()` based on config flags
- `scripts/common.sh` - Shared utilities: logging (`info|warn|error|success`), `parse_args`, `ask_for_sudo`, `run()` for DRY_RUN-aware execution, `ensure_brew_in_path`
- `scripts/core/` - System setup: macOS updates, Xcode CLI, Homebrew installation
- `scripts/apps/` - Application installation and Dock configuration
- `scripts/config/` - Dotfiles, SSH config, macOS defaults
- `files/` - Static assets symlinked to home directory (dotfiles, ssh config, ghostty config, oh-my-posh theme)
- `Brewfile` - Homebrew formulas, casks, and Mac App Store apps

## Coding Conventions

- Bash only; start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Use `common.sh` helpers for logging and utilities
- File naming: verb + scope (`install-*.sh`, `configure-*.sh`, `setup-*.sh`)
- Functions: `lower_snake_case`; constants: `UPPER_SNAKE_CASE` with `readonly`
- All modules must be idempotent; honor `DRY_RUN` and `VERBOSE` globals
- Use `run` wrapper for commands that should respect dry-run mode

## Commit Style

Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`

Example: `feat: add macOS defaults configuration script`
