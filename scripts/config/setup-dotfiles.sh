#!/usr/bin/env bash

# Dotfiles Setup
# Description: Creates symlinks for dotfiles
# Version: 1.0.0

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Configuration
readonly MACOS_BOOTSTRAP_DIR="$HOME/.macos-bootstrap"

# Create symlinks for dotfiles
setup_dotfiles() {
    info "Setting up dotfiles..."
    
    local files_dir="$MACOS_BOOTSTRAP_DIR/files"
    
    if [[ ! -d "$files_dir" ]]; then
        warn "Files directory not found at: $files_dir"
        return 0
    fi
    
    # Find all dotfiles in the files directory with null-delimited output
    local dotfiles
    dotfiles=$(find "$files_dir" -maxdepth 1 -name ".*" -type f -print0 2>/dev/null || true)
    
    if [[ -z "$dotfiles" ]]; then
        info "No dotfiles found in $files_dir"
        return 0
    fi
    
    info "Found dotfiles: $(echo "$dotfiles" | tr '\0' '\n' | xargs basename -a | tr '\n' ' ')"
    
    while IFS= read -r -d '' dotfile; do
        local filename
        filename=$(basename "$dotfile")
        local target="$HOME/$filename"
        
        if [[ "$DRY_RUN" == true ]]; then
            if [[ -L "$target" ]]; then
                info "DRY RUN: Would update symlink $target -> $dotfile"
            elif [[ -f "$target" ]]; then
                warn "DRY RUN: Would backup $target and create symlink to $dotfile"
            else
                info "DRY RUN: Would create symlink $target -> $dotfile"
            fi
            continue
        fi
        
        # Check if target already exists
        if [[ -L "$target" ]]; then
            # Check if it's already pointing to the right place
            if [[ "$(readlink "$target")" == "$dotfile" ]]; then
                success "✓ Symlink already exists: $target"
            else
                info "Updating symlink: $target"
                rm "$target"
                ln -s "$dotfile" "$target"
                success "✓ Updated symlink: $target"
            fi
        elif [[ -f "$target" ]]; then
            # Backup existing file
            local backup="$target.backup.$(date +%Y%m%d-%H%M%S)"
            info "Backing up existing file: $target -> $backup"
            mv "$target" "$backup"
            ln -s "$dotfile" "$target"
            success "✓ Created symlink: $target (backed up original to $backup)"
        else
            # Create new symlink
            ln -s "$dotfile" "$target"
            success "✓ Created symlink: $target"
        fi
    done < <(printf '%s' "$dotfiles")
}

# Main function
main() {
    setup_dotfiles
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 