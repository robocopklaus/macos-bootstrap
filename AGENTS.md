# AGENTS.md
Guidance for coding agents operating in this repository.

## Scope and priorities
- This is a Bash-first macOS bootstrap project.
- Prefer safe, idempotent changes that can be re-run.
- Default to dry-run validation before real execution.
- Respect repository patterns over generic shell patterns.

## Repository map
- `install.sh`: bootstrap entrypoint for fresh macOS systems.
- `config.sh`: central feature flags and exported environment.
- `Brewfile`: packages, casks, and Mac App Store apps.
- `scripts/main.sh`: orchestrates module execution.
- `scripts/common.sh`: shared helpers, traps, logging, and arg parsing.
- `scripts/core/*.sh`: macOS updates, Xcode CLI tools, Homebrew.
- `scripts/apps/setup-apps.sh`: brew bundle + Dock setup.
- `scripts/config/setup-dotfiles.sh`: stow-based dotfile linking.
- `scripts/config/configure-macos-defaults.sh`: `defaults write` settings.
- `dotfiles/`: GNU Stow package contents for `$HOME`.
- `.github/workflows/ci.yml`: syntax + ShellCheck checks.

## Build, lint, and test commands
There is no compile step. Validation is syntax checks, linting, and dry-run behavior.

### Primary execution
- Full run: `./scripts/main.sh`
- Dry run (recommended first): `./scripts/main.sh --dry-run`
- Verbose run: `./scripts/main.sh --verbose`
- Non-interactive run: `./scripts/main.sh --yes`
- Custom config: `./scripts/main.sh --config custom-config.sh`

### Run individual modules
- macOS updates: `./scripts/core/update-macos.sh`
- Xcode tools: `./scripts/core/install-xcode-tools.sh`
- Homebrew: `./scripts/core/install-homebrew.sh`
- Apps and Dock: `./scripts/apps/setup-apps.sh`
- Dotfiles: `./scripts/config/setup-dotfiles.sh`
- macOS defaults: `./scripts/config/configure-macos-defaults.sh`

Most modules support common flags via `parse_args` (`--dry-run`, `--verbose`, `--yes`, `--config`).

### Syntax checks
- Main script syntax: `bash -n scripts/main.sh`
- All scripts syntax (CI-equivalent):
  - `find scripts -type f -name '*.sh' -print0 | xargs -0 -I{} bash -n {}`

### Linting
- Lint all scripts (preferred):
  - `find scripts -type f -name '*.sh' -print0 | xargs -0 shellcheck -x`
- Lint glob form (works in many shells):
  - `shellcheck -x scripts/**/*.sh`
- Lint one file:
  - `shellcheck -x scripts/config/setup-dotfiles.sh`

`.shellcheckrc` sets `source-path=SCRIPTDIR`; keep sourced paths resolvable.

### Single-test / targeted validation
There is currently no committed `tests/` suite.

Use one of these as the "single test" equivalent:
- Single script syntax check:
  - `bash -n scripts/core/install-homebrew.sh`
- Single script lint check:
  - `shellcheck -x scripts/core/install-homebrew.sh`
- Single module dry-run smoke test:
  - `./scripts/apps/setup-apps.sh --dry-run`

If Bats tests are added later:
- Run one test file: `bats tests/setup-dotfiles.bats`
- Run one named case: `bats --filter 'backs up conflicts' tests/setup-dotfiles.bats`

### Logs and diagnostics
- Runtime logs: `/tmp/macos-bootstrap-YYYYMMDD-HHMMSS.log`
- Find warnings/errors quickly:
  - `grep -E '\[WARN\]|\[ERROR\]' /tmp/macos-bootstrap-*.log`

## Code style guidelines

### Language, headers, and strict mode
- Bash only (`#!/usr/bin/env bash`).
- Executable scripts should initialize with `init_script` from `common.sh`.
- `init_script` sets `set -Eeuo pipefail` and traps; avoid ad-hoc trap logic unless intentionally standalone (`install.sh`).

### Sourcing / imports
- Compute script directory robustly:
  - `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- Source shared helpers with absolute paths from `SCRIPT_DIR`.
- Add ShellCheck source hints for non-obvious paths:
  - `# shellcheck source=../config.sh`
- Prefer `resolve_repo_root "$SCRIPT_DIR"` over fragile relative paths.

### Formatting and structure
- Follow `.editorconfig`: spaces, 2-space indentation, LF, final newline, trim trailing whitespace.
- Keep functions small and task-focused.
- Keep orchestration in `main()` and call it from a guarded entrypoint.
- Use comments for non-obvious logic only.

### Naming conventions
- Files: `verb-scope.sh` (for example `install-homebrew.sh`, `setup-dotfiles.sh`).
- Functions: `lower_snake_case`.
- Constants and env knobs: `UPPER_SNAKE_CASE`.
- Mark constants readonly when practical (`readonly NAME`).

### Variables and types (Bash semantics)
- Use `local` inside functions.
- Quote expansions unless word splitting is intentional.
- Represent booleans as strings: `true` / `false`.
- Compare booleans explicitly: `[[ "$DRY_RUN" == true ]]`.
- Prefer arrays for command options and invoke with `"${opts[@]}"`.

### Command execution and idempotency
- Prefer `run ...` for mutating commands that should respect `DRY_RUN`.
- Function-level `DRY_RUN` guards are also acceptable for grouped operations.
- Always check current state before mutating.
- Keep scripts safe to re-run without harmful side effects.
- Add guards for macOS assumptions (`Darwin`) and privilege assumptions (`sudo` / non-root).

### Error handling and logging
- Fail fast with strict mode.
- Use `return 1` inside functions, and `exit 1` at script boundary when needed.
- Use `info`, `warn`, `error`, and `success` for consistent logs.
- Prefer actionable errors over generic failures.
- Preserve rollback/cleanup behavior when mutating user state (see dotfiles backup logic).

### External tools and portability
- Assume macOS first.
- Keep dependencies explicit: Homebrew, dockutil, stow, softwareupdate.
- Before calling `brew` in modules, run `ensure_brew_in_path`.

## Working rules for agentic changes
- Prefer minimal diffs; avoid broad rewrites unless requested.
- Do not remove `DRY_RUN`, `NON_INTERACTIVE`, trap cleanup, or safety checks.
- Keep module scripts independently runnable where currently supported.
- If adding a new flag, wire it through `parse_args` compatibility expectations.
- Update docs (`README.md`, `AGENTS.md`) when behavior/commands change.

## CI and PR expectations
- CI currently runs:
  - Bash syntax checks for all `scripts/**/*.sh`
  - `shellcheck -x` for all `scripts/**/*.sh`
- Before opening a PR, run at least:
  - `bash -n scripts/main.sh`
  - `find scripts -type f -name '*.sh' -print0 | xargs -0 shellcheck -x`
  - `./scripts/main.sh --dry-run`

Commit style follows Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`).

## Security and safety notes
- Never commit secrets (`.env`, private SSH material, machine-specific tokens).
- Keep privilege escalation narrowly scoped.
- Dock/defaults changes should be reversible and clearly logged.

## Cursor/Copilot rules discovery
Checked for additional agent rule files in this repo:
- `.cursor/rules/`: not present
- `.cursorrules`: not present
- `.github/copilot-instructions.md`: not present

If these files are added later, treat them as higher-priority instructions and merge them into this guide.
