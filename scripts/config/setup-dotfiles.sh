#!/usr/bin/env bash

# Dotfiles Setup using GNU Stow

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

REPO_ROOT=$(resolve_repo_root "$SCRIPT_DIR")

# Create symlinks for dotfiles using GNU Stow
setup_dotfiles() {
    info "Setting up dotfiles with GNU Stow..."

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

    # Use --adopt to take ownership of existing files/symlinks (safe for migrations)
    # Use --restow to handle re-runs gracefully (removes then re-stows)
    if stow "${stow_opts[@]}" --adopt --restow dotfiles; then
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
