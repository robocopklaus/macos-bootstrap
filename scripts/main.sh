#!/usr/bin/env bash

# macOS Bootstrap Main Script
# Description: Orchestrates the modular bootstrap process
# Version: 2.0.0
# Author: macOS Bootstrap Project

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Clone repository to MACOS_BOOTSTRAP_DIR
clone_repository() {
    info "Setting up repository in $MACOS_BOOTSTRAP_DIR"
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would clone repository to $MACOS_BOOTSTRAP_DIR"
        return 0
    fi
    
    info "Repository URL: $REPOSITORY_URL"
    info "Repository Branch: $REPOSITORY_BRANCH"
    
    if [[ ! -d "$MACOS_BOOTSTRAP_DIR" ]]; then
        info "Cloning repository..."
        if git clone -b "$REPOSITORY_BRANCH" "$REPOSITORY_URL" "$MACOS_BOOTSTRAP_DIR"; then
            success "Repository cloned successfully"
        else
            error "Failed to clone repository"
            return 1
        fi
    else
        info "Updating repository..."
        if git -C "$MACOS_BOOTSTRAP_DIR" pull --rebase origin "$REPOSITORY_BRANCH"; then
            success "Repository updated successfully"
        else
            error "Failed to update repository"
            return 1
        fi
    fi
}

# Run a module script
run_module() {
    local module_name="$1"
    local module_script="$2"
    local enabled_var="$3"
    
    # Check if module is enabled
    if [[ "${!enabled_var}" != "true" ]]; then
        info "Skipping disabled module: $module_name"
        return 0
    fi
    
    info "Running module: $module_name"
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would run $module_script"
        return 0
    fi
    
    if [[ -f "$module_script" ]]; then
        if bash "$module_script"; then
            success "✓ Module completed: $module_name"
        else
            error "✗ Module failed: $module_name"
            return 1
        fi
    else
        error "Module script not found: $module_script"
        return 1
    fi
}

# Main execution function
main() {
    info "Starting macOS bootstrap setup"
    info "Log file: $LOG_FILE"
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN MODE: No changes will be made"
    fi
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Run setup steps
    check_platform
    ask_for_sudo
    
    # Core system setup
    run_module "macOS Updates" "$SCRIPT_DIR/core/update-macos.sh" "INSTALL_MACOS_UPDATES"
    run_module "Xcode CLI Tools" "$SCRIPT_DIR/core/install-xcode-tools.sh" "INSTALL_XCODE_TOOLS"
    
    # Clone repository (needed for subsequent steps)
    clone_repository
    
    # Install tools and applications
    run_module "Homebrew" "$SCRIPT_DIR/core/install-homebrew.sh" "INSTALL_HOMEBREW"
    run_module "Applications" "$SCRIPT_DIR/apps/install-brewfile.sh" "INSTALL_APPLICATIONS"
    
    # Configuration
    run_module "Dotfiles" "$SCRIPT_DIR/config/setup-dotfiles.sh" "SETUP_DOTFILES"
    run_module "SSH Config" "$SCRIPT_DIR/config/configure-ssh.sh" "CONFIGURE_SSH"
    
    # Final setup
    run_module "Dock Setup" "$SCRIPT_DIR/apps/setup-dock.sh" "CUSTOMIZE_DOCK"
    
    success "macOS bootstrap setup completed successfully!"
    info "Log file saved to: $LOG_FILE"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_args "$@"
    main
fi 