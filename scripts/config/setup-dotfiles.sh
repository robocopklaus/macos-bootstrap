#!/usr/bin/env bash

# Dotfiles Setup using GNU Stow

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

REPO_ROOT=$(resolve_repo_root "$SCRIPT_DIR")

# Back up any real files in $HOME that would conflict with dotfile symlinks.
# Conflicts are moved to ~/.dotfiles-backup-<timestamp>/ so they are not lost.
# Already-stowed symlinks are not touched, making this safe to re-run.
backup_conflicts() {
    local dotfiles_dir="$REPO_ROOT/dotfiles"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="$HOME/.dotfiles-backup-$timestamp"
    local backed_up=false

    while IFS= read -r -d '' src_file; do
        local rel_path="${src_file#"$dotfiles_dir"/}"
        local target="$HOME/$rel_path"

        # Conflict: target exists as a real file (not a symlink, not a directory)
        if [[ -f "$target" && ! -L "$target" ]]; then
            if [[ "$backed_up" == false ]]; then
                info "Backing up conflicting dotfiles to $backup_dir"
                backed_up=true
            fi
            if [[ "$DRY_RUN" == true ]]; then
                info "  DRY RUN: Would back up ~/$rel_path"
            else
                mkdir -p "$(dirname "$backup_dir/$rel_path")"
                mv "$target" "$backup_dir/$rel_path"
                info "  Backed up ~/$rel_path"
            fi
        fi
    done < <(find "$dotfiles_dir" -type f -print0)

    if [[ "$backed_up" == true && "$DRY_RUN" != true ]]; then
        success "Conflicting files backed up to $backup_dir"
    fi
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
    backup_conflicts

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
    main
fi
