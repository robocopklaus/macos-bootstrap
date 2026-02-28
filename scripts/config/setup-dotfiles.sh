#!/usr/bin/env bash

# Dotfiles Setup using GNU Stow

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

REPO_ROOT=$(resolve_repo_root "$SCRIPT_DIR")

# Conflict classification results
CONFLICT_BACKUPS=()
CONFLICT_BLOCKERS=()
SKIP_STOW_DRY_RUN=false

# Check if a symlink target resolves to this repository's managed dotfile.
is_managed_dotfile_symlink() {
    local link_path="$1"
    local rel_path="$2"
    local link_target
    link_target="$(readlink "$link_path" 2>/dev/null || true)"

    if [[ -z "$link_target" ]]; then
        return 1
    fi

    local resolved_target
    if [[ "$link_target" == /* ]]; then
        resolved_target="$link_target"
    else
        local target_dir
        target_dir="$(cd "$(dirname "$link_path")" && pwd -P)"
        local target_parent
        target_parent="$(cd "$target_dir/$(dirname "$link_target")" 2>/dev/null && pwd -P)" || return 1
        resolved_target="$target_parent/$(basename "$link_target")"
    fi

    [[ "$resolved_target" == "$REPO_ROOT/dotfiles/$rel_path" ]]
}

# Collect target conflicts for dotfiles package.
# - Existing regular files/directories are backup candidates.
# - Symlinks that do not point to this package are blocking conflicts.
collect_conflicts() {
    local dotfiles_dir="$REPO_ROOT/dotfiles"
    CONFLICT_BACKUPS=()
    CONFLICT_BLOCKERS=()

    while IFS= read -r -d '' src_file; do
        local rel_path="${src_file#"$dotfiles_dir"/}"
        local target="$HOME/$rel_path"

        if [[ -L "$target" ]]; then
            # Treat links to this package as managed/stowed; everything else blocks.
            if is_managed_dotfile_symlink "$target" "$rel_path"; then
                continue
            fi

            CONFLICT_BLOCKERS+=("$rel_path")
            continue
        fi

        if [[ -e "$target" ]]; then
            CONFLICT_BACKUPS+=("$rel_path")
        fi
    done < <(
        find "$dotfiles_dir" -type f \
            ! -name '.stow-local-ignore' \
            ! -name '.stow-global-ignore' \
            ! -name '.stowrc' \
            -print0
    )
}

# Back up existing conflict paths in $HOME before stowing, without partial changes.
backup_conflicts() {
    collect_conflicts

    if (( ${#CONFLICT_BLOCKERS[@]} > 0 )); then
        error "Found conflicting symlinks not owned by stow:"
        local blocker
        for blocker in "${CONFLICT_BLOCKERS[@]}"; do
            error "  ~/$blocker"
        done
        error "Resolve these symlink conflicts first, then re-run setup-dotfiles."
        return 1
    fi

    if (( ${#CONFLICT_BACKUPS[@]} == 0 )); then
        return 0
    fi

    local rel_path
    if [[ "$DRY_RUN" == true ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d-%H%M%S)
        local backup_dir="$HOME/.dotfiles-backup-$timestamp"
        info "Backing up conflicting dotfiles to $backup_dir"
        for rel_path in "${CONFLICT_BACKUPS[@]}"; do
            info "  DRY RUN: Would back up ~/$rel_path"
        done
        # stow --no still conflicts while files exist; skip and report simulation.
        SKIP_STOW_DRY_RUN=true
        return 0
    fi

    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="$HOME/.dotfiles-backup-$timestamp"
    local moved_paths=()

    info "Backing up conflicting dotfiles to $backup_dir"
    for rel_path in "${CONFLICT_BACKUPS[@]}"; do
        mkdir -p "$(dirname "$backup_dir/$rel_path")"
        if mv "$HOME/$rel_path" "$backup_dir/$rel_path"; then
            moved_paths+=("$rel_path")
            info "  Backed up ~/$rel_path"
        else
            error "Failed to back up ~/$rel_path"
            warn "Attempting rollback of previously moved files..."
            local moved
            for moved in "${moved_paths[@]}"; do
                mkdir -p "$(dirname "$HOME/$moved")"
                mv "$backup_dir/$moved" "$HOME/$moved" 2>/dev/null || \
                    warn "Could not restore ~/$moved from backup"
            done
            return 1
        fi
    done

    success "Conflicting files backed up to $backup_dir"
}

# Create symlinks for dotfiles using GNU Stow
setup_dotfiles() {
    info "Setting up dotfiles with GNU Stow..."

    # Ensure brew (and brew-installed tools like stow) are in PATH
    if ! ensure_brew_in_path; then
        error "brew not found. Ensure Homebrew is installed and available in PATH"
        return 1
    fi

    local stow_dir="$REPO_ROOT"

    if [[ ! -d "$stow_dir/dotfiles" ]]; then
        warn "Dotfiles package not found at: $stow_dir/dotfiles"
        return 0
    fi

    # Check if stow is available
    if ! command -v stow &>/dev/null; then
        error "GNU Stow is not installed. Please install it with: brew install stow"
        return 1
    fi

    # Back up any conflicting real files before stowing so repo dotfiles are
    # never silently overwritten
    backup_conflicts || return 1

    if [[ "$DRY_RUN" == true && "$SKIP_STOW_DRY_RUN" == true ]]; then
        warn "DRY RUN: Skipping stow simulation because conflicts would be moved first"
        return 0
    fi

    local stow_opts=(--dir="$stow_dir" --target="$HOME")

    if [[ "$VERBOSE" == true ]]; then
        stow_opts+=(--verbose=2)
    else
        stow_opts+=(--verbose=1)
    fi

    if [[ "$DRY_RUN" == true ]]; then
        stow_opts+=(--no)
        info "DRY RUN: Would stow dotfiles to $HOME"
    fi

    # Use --restow to handle re-runs gracefully (removes then re-stows)
    # Use --no-folding to create individual file symlinks (enables .stow-local-ignore patterns)
    if stow "${stow_opts[@]}" --restow --no-folding dotfiles; then
        success "Dotfiles stowed successfully"
    else
        error "Failed to stow dotfiles"
        return 1
    fi

    # Fix SSH permissions (stow doesn't handle this)
    if [[ "$DRY_RUN" != true && -d "$HOME/.ssh" ]]; then
        chmod 700 "$HOME/.ssh" 2>/dev/null || true
        chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
        success "SSH permissions set (700 for .ssh, 600 for config)"
    fi
}

# Main function
main() {
    setup_dotfiles
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_script
    parse_args "$@"
    main
fi
