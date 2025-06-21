#!/usr/bin/env bash

# Homebrew Installation
# Description: Installs Homebrew package manager
# Version: 1.0.0

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Install Homebrew
install_homebrew() {
    info "Checking Homebrew installation..."
    
    if command -v brew >/dev/null 2>&1; then
        success "Homebrew is already installed"
        return 0
    fi
    
    info "Homebrew not found. Installing..."
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would install Homebrew"
        return 0
    fi
    
    # Install Homebrew
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        success "Homebrew installed successfully"
        
        # Add Homebrew to PATH for current session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            # Apple Silicon Mac
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            # Intel Mac
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        # Update Homebrew
        info "Updating Homebrew..."
        brew update
        success "Homebrew updated"
    else
        error "Failed to install Homebrew"
        return 1
    fi
}

# Verify Homebrew installation
verify_homebrew() {
    info "Verifying Homebrew installation..."
    
    if command -v brew >/dev/null 2>&1; then
        success "✓ Homebrew is available"
        local brew_version
        brew_version=$(brew --version 2>/dev/null | head -n 1 || echo "version check failed")
        info "Homebrew version: $brew_version"
    else
        error "✗ Homebrew is not available"
        return 1
    fi
}

# Main function
main() {
    install_homebrew
    verify_homebrew
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 