#!/usr/bin/env bash

# Brewfile Installation
# Description: Installs applications from Brewfile
# Version: 1.0.0

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Configuration
readonly MACOS_BOOTSTRAP_DIR="$HOME/.macos-bootstrap"

# Install applications from Brewfile
install_brewfile() {
    info "Installing applications from Brewfile..."
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would install applications from Brewfile"
        return 0
    fi
    
    # Use the Brewfile from the cloned repository
    local brewfile_path="$MACOS_BOOTSTRAP_DIR/Brewfile"
    
    if [[ ! -f "$brewfile_path" ]]; then
        error "Brewfile not found at: $brewfile_path"
        return 1
    fi
    
    info "Using Brewfile: $brewfile_path"
    
    # Install from Brewfile
    if brew bundle --file="$brewfile_path"; then
        success "Applications installed successfully from Brewfile"
    else
        error "Failed to install applications from Brewfile"
        return 1
    fi
}

# Main function
main() {
    install_brewfile
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 