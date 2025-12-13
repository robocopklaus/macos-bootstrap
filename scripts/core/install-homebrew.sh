#!/usr/bin/env bash

# Homebrew Installation

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
        
        # Persist Homebrew to .zprofile only (zsh login shell, standard location)
        if command -v brew >/dev/null 2>&1 && [[ -n "${HOME:-}" ]]; then
            local profile="$HOME/.zprofile"
            local shellenv_cmd

            # Determine the correct shellenv command based on architecture
            # shellcheck disable=SC2016  # Single quotes intentional - literal string for .zprofile
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                shellenv_cmd='eval "$(/opt/homebrew/bin/brew shellenv)"'
            else
                shellenv_cmd='eval "$(/usr/local/bin/brew shellenv)"'
            fi

            # Check if already present (robust check)
            if grep -qF "brew shellenv" "$profile" 2>/dev/null; then
                info "Homebrew shellenv already configured in $profile"
            elif [[ "$DRY_RUN" == true ]]; then
                info "DRY RUN: Would append Homebrew shellenv to $profile"
            else
                # Create file if it doesn't exist
                [[ ! -f "$profile" ]] && touch "$profile"
                printf '\n# Homebrew\n%s\n' "$shellenv_cmd" >> "$profile"
                success "Added Homebrew shellenv to $profile"
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
    init_script
    main
fi 
