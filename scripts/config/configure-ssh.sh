#!/usr/bin/env bash

# SSH Configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

REPO_ROOT=$(resolve_repo_root "$SCRIPT_DIR")

# Check if 1Password is available
check_1password_agent() {
    # Expand ~ in SSH_AGENT_SOCKET from config
    local agent_socket="${SSH_AGENT_SOCKET/#\~/$HOME}"

    if [[ -S "$agent_socket" ]]; then
        success "✓ 1Password SSH agent socket found"
        return 0
    else
        warn "1Password SSH agent socket not found at: $agent_socket"
        info "You may need to install 1Password and enable SSH agent"
        return 1
    fi
}

# Setup SSH config symlink
setup_ssh_config() {
    info "Setting up SSH config symlink..."
    
    local ssh_dir="$HOME/.ssh"
    local ssh_config_source="$REPO_ROOT/files/ssh/config"
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
    
    # Check 1Password agent availability (informational only, don't fail if missing)
    check_1password_agent || true

    # Create symlink for SSH config
    create_symlink "$ssh_config_source" "$ssh_config_target"

    # Set proper permissions on SSH config
    if [[ "$DRY_RUN" != true ]]; then
        chmod 600 "$ssh_config_target"
    fi
    success "SSH config symlink created successfully."
}

# Main function
main() {
    setup_ssh_config
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_script
    main
fi 
