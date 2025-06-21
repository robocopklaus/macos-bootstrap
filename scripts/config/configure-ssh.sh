#!/usr/bin/env bash

# SSH Configuration
# Description: Sets up SSH config with 1Password integration
# Version: 1.0.0

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Configuration
readonly MACOS_BOOTSTRAP_DIR="$HOME/.macos-bootstrap"

# Setup SSH config symlink
setup_ssh_config() {
    info "Setting up SSH config symlink..."
    
    local ssh_dir="$HOME/.ssh"
    local ssh_config_source="$MACOS_BOOTSTRAP_DIR/files/ssh/config"
    local ssh_config_target="$ssh_dir/config"
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would create SSH directory: $ssh_dir"
        if [[ -f "$ssh_config_source" ]]; then
            info "DRY RUN: Would create symlink: $ssh_config_target -> $ssh_config_source"
        else
            warn "DRY RUN: Warning: $ssh_config_source not found"
        fi
        return 0
    fi
    
    # Create SSH directory with proper permissions
    if mkdir -p "$ssh_dir" && chmod 700 "$ssh_dir"; then
        success "✓ SSH directory created/verified: $ssh_dir"
    else
        error "Failed to create SSH directory: $ssh_dir"
        return 1
    fi
    
    # Check if SSH config source exists
    if [[ ! -f "$ssh_config_source" ]]; then
        warn "SSH config source not found: $ssh_config_source"
        return 0
    fi
    
    # Create symlink for SSH config
    if [[ -L "$ssh_config_target" ]]; then
        # Check if it's already pointing to the right place
        if [[ "$(readlink "$ssh_config_target")" == "$ssh_config_source" ]]; then
            success "✓ SSH config symlink already exists: $ssh_config_target"
        else
            info "Updating SSH config symlink: $ssh_config_target"
            rm "$ssh_config_target"
            ln -sf "$ssh_config_source" "$ssh_config_target"
            success "✓ Updated SSH config symlink: $ssh_config_target"
        fi
    elif [[ -f "$ssh_config_target" ]]; then
        # Backup existing file
        local backup="$ssh_config_target.backup.$(date +%Y%m%d-%H%M%S)"
        info "Backing up existing SSH config: $ssh_config_target -> $backup"
        mv "$ssh_config_target" "$backup"
        ln -sf "$ssh_config_source" "$ssh_config_target"
        success "✓ Created SSH config symlink: $ssh_config_target (backed up original to $backup)"
    else
        # Create new symlink
        ln -sf "$ssh_config_source" "$ssh_config_target"
        success "✓ Created SSH config symlink: $ssh_config_target"
    fi
    
    success "SSH config symlink created successfully."
}

# Main function
main() {
    setup_ssh_config
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 