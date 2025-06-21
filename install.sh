#!/usr/bin/env bash
set -euo pipefail

# macOS Bootstrap - Self-contained installer
# This script can be downloaded and run directly on a fresh macOS installation
# Usage: curl -fsSL https://raw.githubusercontent.com/robocopklaus/macos-bootstrap/main/install.sh | bash

REPO_URL="https://github.com/robocopklaus/macos-bootstrap.git"
CLONE_DIR="$HOME/.macos-bootstrap"
TEMP_DIR="/tmp/macos-bootstrap-$$"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "[$timestamp] [$level] $message"
}

info() { log "INFO" "$*"; }
warn() { log "WARN" "${YELLOW}$*${NC}"; }
error() { log "ERROR" "${RED}$*${NC}"; }
success() { log "SUCCESS" "${GREEN}$*${NC}"; }

# Cleanup function
cleanup() {
    info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR" 2>/dev/null || true
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress 2>/dev/null || true
}

# Error handler
error_handler() {
    local exit_code=$?
    error "Script failed with exit code $exit_code"
    cleanup
    exit "$exit_code"
}

# Set up error handling
trap error_handler ERR
trap cleanup EXIT

# Check if running on macOS
check_platform() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script is designed for macOS only"
        exit 1
    fi
    info "Platform check passed: macOS detected"
}

# Safely request sudo privileges
ask_for_sudo() {
    info "Requesting sudo privileges..."
    
    # Check if we already have sudo privileges
    if sudo -n true 2>/dev/null; then
        info "Already have sudo privileges"
        return 0
    fi
    
    # Request sudo
    sudo -v
    if sudo -n true 2>/dev/null; then
        success "Sudo privileges obtained"
    else
        error "Failed to obtain sudo privileges"
        exit 1
    fi
}

# Install Xcode Command Line Tools (includes Git)
install_xcode_tools() {
    info "Checking for Xcode Command Line Tools..."
    
    if xcode-select -p &>/dev/null; then
        success "Xcode Command Line Tools already installed"
        return 0
    fi
    
    info "Installing Xcode Command Line Tools..."
    warn "This may take several minutes and requires user interaction"
    
    # Create a temporary file to track installation progress
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    
    # Get the identifier for the Command Line Tools
    local PROD=$(softwareupdate -l | grep "\*.*Command Line Tools" | tail -n 1 | sed 's/^[^C]* //')
    
    if [[ -z "$PROD" ]]; then
        error "Could not find Command Line Tools package"
        return 1
    fi
    
    # Install the Command Line Tools
    softwareupdate -i "$PROD" --verbose
    
    # Remove the temporary file
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    
    # Verify installation
    if xcode-select -p &>/dev/null; then
        success "Xcode Command Line Tools installed successfully"
    else
        error "Failed to install Xcode Command Line Tools"
        return 1
    fi
}

# Clone or update the repository
setup_repository() {
    info "Setting up repository in $CLONE_DIR"
    
    if [[ ! -d "$CLONE_DIR" ]]; then
        info "Cloning repository..."
        if git clone "$REPO_URL" "$CLONE_DIR"; then
            success "Repository cloned successfully"
        else
            error "Failed to clone repository"
            return 1
        fi
    else
        info "Updating repository..."
        if git -C "$CLONE_DIR" pull --rebase; then
            success "Repository updated successfully"
        else
            error "Failed to update repository"
            return 1
        fi
    fi
}

# Main execution
main() {
    info "Starting macOS bootstrap setup"
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Run setup steps
    check_platform
    ask_for_sudo
    
    # Install Xcode CLI Tools first (includes Git)
    install_xcode_tools
    
    # Now we can use Git to clone the repository
    setup_repository
    
    # Change to the repository directory and run the main script
    cd "$CLONE_DIR"
    success "Bootstrap setup completed. Running main script..."
    exec ./scripts/main.sh "$@"
}

# Script entry point
# Check if script is being executed directly (not sourced)
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi 