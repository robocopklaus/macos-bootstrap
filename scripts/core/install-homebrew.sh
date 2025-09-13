#!/usr/bin/env bash

# Homebrew Installation
# Description: Installs Homebrew package manager

set -Eeuo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
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
    if run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        success "Homebrew installed successfully"
        
        # Add Homebrew to PATH for current session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            # Apple Silicon Mac
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            # Intel Mac
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        # Persist Homebrew to shell profiles if possible
        local shellenv_cmd
        if command -v brew >/dev/null 2>&1; then
            shellenv_cmd="$(brew shellenv)"
            # zsh default
            if [[ -n "${HOME:-}" ]]; then
                for profile in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.profile"; do
                    if [[ -f "$profile" ]] && grep -q "brew shellenv" "$profile"; then
                        continue
                    fi
                    if [[ "$DRY_RUN" == true ]]; then
                        info "DRY RUN: Would append Homebrew shellenv to $profile"
                    else
                        printf '\n# Homebrew\n%s\n' "$shellenv_cmd" >> "$profile"
                        success "Added Homebrew shellenv to $profile"
                    fi
                done
            fi
        fi

        # Update Homebrew
        info "Updating Homebrew..."
        run brew update
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
    setup_traps
    main
fi 
