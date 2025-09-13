#!/usr/bin/env bash

# Brewfile Installation
# Description: Installs applications from Brewfile

set -Eeuo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
source "$SCRIPT_DIR/../common.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Install applications from Brewfile
install_brewfile() {
    info "Installing applications from Brewfile..."
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would install applications from Brewfile"
        return 0
    fi
    
    # Use the Brewfile from the repository root
    local brewfile_path="$REPO_ROOT/Brewfile"
    
    if [[ ! -f "$brewfile_path" ]]; then
        error "Brewfile not found at: $brewfile_path"
        return 1
    fi
    
    info "Using Brewfile: $brewfile_path"
    
    # Install from Brewfile
    if run brew bundle --file="$brewfile_path"; then
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
    setup_traps
    main
fi 
