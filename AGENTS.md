# Repository Guidelines

## Project Structure & Module Organization
- `install.sh`: One-liner bootstrap entry for fresh macOS.
- `config.sh`: Central configuration (exports via `export_config`).
- `Brewfile`: Homebrew formulas/casks/mas apps.
- `scripts/`: All logic (Bash).
  - `main.sh`: Orchestrator; calls modules and logging.
  - `common.sh`: Logging, arg parsing, sudo keep-alive, traps.
  - `core/`: OS updates, Xcode CLI, Homebrew.
  - `apps/`: App install, Dock setup.
  - `config/`: Dotfiles, SSH, macOS defaults.

## Build, Test, and Development Commands
- Run full setup: `./scripts/main.sh`
- Dry run (no changes): `./scripts/main.sh --dry-run`
- Verbose logs: `./scripts/main.sh --verbose`
- Module-only examples:
  - `./scripts/core/install-homebrew.sh`
  - `./scripts/apps/setup-apps.sh`
- Lint Bash (if installed): `shellcheck scripts/**/*.sh`
- Syntax check: `bash -n scripts/main.sh`

## Coding Style & Naming Conventions
- Bash only; start scripts with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Use `common.sh` helpers: `info|warn|error|success`, `init_script`, `parse_args`, `ask_for_sudo`, `check_platform`, `run`, `ensure_brew_in_path`, `resolve_repo_root`.
- File naming: verbs + scope, e.g., `install-*.sh`, `configure-*.sh`, `update-*.sh`.
- Functions: lower_snake_case; constants `UPPER_SNAKE_CASE` with `readonly`.
- Idempotent modules: safe to re-run; honor `DRY_RUN` and `VERBOSE`.

## Testing Guidelines
- Prefer `--dry-run` first; then run modules individually.
- Validate syntax/lint: `bash -n`, `shellcheck` with `-x` for sourced files.
- Logs are written to `/tmp/macos-bootstrap-*.log`; inspect for warnings.
- Optional: add Bats tests under `tests/*.bats` for pure functions; mirror module names.

## Commit & Pull Request Guidelines
- Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:` (e.g., `feat: add macOS defaults configuration script`).
- Subject in imperative mood; body explains why and notable behavior changes.
- PRs include: summary, rationale, key commands run, sample log snippet (redacted), and screenshots if UI-visible effects (Dock).
- Link related issues; keep changes focused and minimal.

## Security & Configuration Tips
- Scripts may require `sudo`; never embed secrets. Use `dotfiles/.ssh/config` and 1Password agent sockets from `config.sh`.
- Be cautious modifying defaults and Dock—ensure settings match README and are reversible.
