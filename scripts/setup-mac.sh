#!/usr/bin/env bash

# macOS Bootstrap Setup Script
# Description: Safely updates macOS and installs essential development tools
# Version: 2.0.0
# Author: macOS Bootstrap Project

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/tmp/macos-bootstrap-$(date +%Y%m%d-%H%M%S).log"
readonly TEMP_DIR="/tmp/macos-bootstrap-$$"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
DRY_RUN=false
VERBOSE=false
SUDO_PID=""

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

info() { log "INFO" "$*"; }
warn() { log "WARN" "${YELLOW}$*${NC}"; }
error() { log "ERROR" "${RED}$*${NC}"; }
success() { log "SUCCESS" "${GREEN}$*${NC}"; }

# Cleanup function
cleanup() {
    info "Cleaning up..."
    
    # Kill background sudo process if it exists
    if [[ -n "$SUDO_PID" ]] && kill -0 "$SUDO_PID" 2>/dev/null; then
        kill "$SUDO_PID" 2>/dev/null || true
    fi
    
    # Remove temporary files
    rm -rf "$TEMP_DIR" 2>/dev/null || true
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress 2>/dev/null || true
    
    info "Cleanup completed"
}

# Error handler
error_handler() {
    local exit_code=$?
    error "Script failed with exit code $exit_code"
    error "Check log file: $LOG_FILE"
    cleanup
    exit "$exit_code"
}

# Set up error handling
trap error_handler ERR
trap cleanup EXIT

# Display usage information
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
    -d, --dry-run    Preview what the script will do without making changes
    -v, --verbose    Enable verbose output
    -h, --help       Show this help message

Description:
    This script safely updates macOS and installs essential development tools.
    It will:
    - Update macOS software (with user confirmation)
    - Install Xcode Command Line Tools if not present
    - Provide detailed logging of all operations

Examples:
    $SCRIPT_NAME                    # Run normally
    $SCRIPT_NAME --dry-run          # Preview changes
    $SCRIPT_NAME --verbose          # Run with verbose output

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

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
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would request sudo privileges"
        return 0
    fi
    
    # Check if we already have sudo privileges
    if sudo -n true 2>/dev/null; then
        info "Already have sudo privileges"
        return 0
    fi
    
    # Request sudo and keep it alive
    sudo -v
    if sudo -n true 2>/dev/null; then
        # Start background process to keep sudo alive
        (
            while true; do
                sudo -n true
                sleep 50
                kill -0 "$$" || exit
            done
        ) &
        SUDO_PID=$!
        success "Sudo privileges obtained and maintained"
    else
        error "Failed to obtain sudo privileges"
        exit 1
    fi
}

# Check for available updates
check_for_updates() {
    info "Checking for available macOS updates..."
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would check for updates"
        return 0
    fi
    
    # Get the update list and check for available updates
    local update_output
    update_output=$(softwareupdate -l 2>/dev/null)
    
    # Check if the output contains "No new software available"
    if echo "$update_output" | grep -q "No new software available"; then
        success "No updates available"
        return 0
    fi
    
    # Check if there are any updates (lines starting with *)
    if echo "$update_output" | grep -q "^\*"; then
        local update_count
        update_count=$(echo "$update_output" | grep -c "^\*" | tr -d '[:space:]')
        info "Found $update_count update(s) available"
        echo "$update_output" | grep "^\*" | sed 's/^[ *]*//'
        return 1
    else
        success "No updates available"
        return 0
    fi
}

# Update macOS with user confirmation
update_macos() {
    info "Checking for macOS updates..."
    
    if ! check_for_updates; then
        echo
        warn "Updates are available. This may include system updates that require a restart."
        echo -n "Do you want to install available updates? (y/N): "
        read -r response
        
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            warn "Skipping macOS updates"
            return 0
        fi
        
        if [[ "$DRY_RUN" == true ]]; then
            warn "DRY RUN: Would install macOS updates"
            return 0
        fi
        
        info "Installing macOS updates..."
        if sudo softwareupdate -i -a; then
            success "macOS updates installed successfully"
            warn "System restart may be required"
        else
            error "Failed to install macOS updates"
            return 1
        fi
    fi
}

# Check if Xcode CLI tools are installed
check_xcode_cli_tools() {
    local git_path="/Library/Developer/CommandLineTools/usr/bin/git"
    
    # Check if git exists in the expected location
    if [[ -e "$git_path" ]]; then
        # Verify xcode-select points to the right location
        local xcode_path
        xcode_path=$(xcode-select -p 2>/dev/null)
        if [[ "$xcode_path" == "/Library/Developer/CommandLineTools" ]]; then
            return 0
        fi
    fi
    
    # Alternative check: try to run git directly
    if command -v git >/dev/null 2>&1; then
        # Check if git is from Command Line Tools
        local git_location
        git_location=$(which git 2>/dev/null)
        if [[ "$git_location" == "/usr/bin/git" ]] || [[ "$git_location" == "/Library/Developer/CommandLineTools/usr/bin/git" ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Install Xcode Command Line Tools
install_xcode_cli_tools() {
    info "Checking Xcode Command Line Tools..."
    
    if check_xcode_cli_tools; then
        success "Xcode Command Line Tools are already installed"
        return 0
    fi
    
    info "Xcode Command Line Tools not found. Installing..."
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would install Xcode Command Line Tools"
        return 0
    fi
    
    # Create temporary file to trigger installation
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    
    # Get the product identifier
    local product_id
    product_id=$(softwareupdate -l 2>/dev/null | \
        grep "\*.*Command Line Tools" | \
        tail -n 1 | \
        sed 's/^[^C]* //' | \
        sed 's/ .*//' | \
        tr -d '[:space:]')
    
    if [[ -z "$product_id" ]] || [[ "$product_id" == "Command" ]]; then
        error "Could not find Command Line Tools product identifier"
        error "Command Line Tools may already be installed or not available"
        rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        return 1
    fi
    
    info "Installing Command Line Tools: $product_id"
    
    if sudo softwareupdate -i "$product_id" --verbose; then
        success "Xcode Command Line Tools installed successfully"
        rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    else
        error "Failed to install Xcode Command Line Tools"
        rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        return 1
    fi
}

# Verify installation
verify_installation() {
    info "Verifying installation..."
    
    local all_good=true
    
    # Check Xcode CLI tools
    if check_xcode_cli_tools; then
        success "✓ Xcode Command Line Tools verified"
    else
        error "✗ Xcode Command Line Tools verification failed"
        info "Checking git location: $(which git 2>/dev/null || echo 'git not found')"
        info "Checking xcode-select path: $(xcode-select -p 2>/dev/null || echo 'xcode-select failed')"
        all_good=false
    fi
    
    # Check git
    if command -v git >/dev/null 2>&1; then
        success "✓ Git is available"
        local git_version
        git_version=$(git --version 2>/dev/null || echo "version check failed")
        info "Git version: $git_version"
    else
        error "✗ Git is not available"
        all_good=false
    fi
    
    if [[ "$all_good" == true ]]; then
        success "All verifications passed!"
    else
        error "Some verifications failed"
        warn "You may need to restart your terminal or run 'xcode-select --install' manually"
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
    update_macos
    install_xcode_cli_tools
    verify_installation
    
    success "macOS bootstrap setup completed successfully!"
    info "Log file saved to: $LOG_FILE"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_args "$@"
    main
fi
