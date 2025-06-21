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
readonly MACOS_BOOTSTRAP_DIR="$HOME/.macos-bootstrap"
readonly REPOSITORY_URL="https://github.com/robocopklaus/macos-bootstrap.git"

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
        # Wait a moment for the process to terminate gracefully
        sleep 0.1
        # Force kill if still running
        kill -9 "$SUDO_PID" 2>/dev/null || true
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
    - Clone the repository to ~/.macos-bootstrap
    - Update macOS software (with user confirmation)
    - Install Xcode Command Line Tools if not present
    - Install Homebrew and applications from Brewfile
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

# Clone repository to MACOS_BOOTSTRAP_DIR
clone_repository() {
    info "Setting up repository in $MACOS_BOOTSTRAP_DIR"
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would clone repository to $MACOS_BOOTSTRAP_DIR"
        return 0
    fi
    
    info "Repository URL: $REPOSITORY_URL"
    
    if [[ ! -d "$MACOS_BOOTSTRAP_DIR" ]]; then
        info "Cloning repository..."
        if git clone "$REPOSITORY_URL" "$MACOS_BOOTSTRAP_DIR"; then
            success "Repository cloned successfully"
        else
            error "Failed to clone repository"
            return 1
        fi
    else
        info "Updating repository..."
        if git -C "$MACOS_BOOTSTRAP_DIR" pull --rebase; then
            success "Repository updated successfully"
        else
            error "Failed to update repository"
            return 1
        fi
    fi
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
                sudo -n true >/dev/null 2>&1
                sleep 50
                kill -0 "$$" >/dev/null 2>&1 || exit
            done
        ) >/dev/null 2>&1 &
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

# Create symlinks for dotfiles
setup_dotfiles() {
    info "Setting up dotfiles..."
    
    local files_dir="$MACOS_BOOTSTRAP_DIR/files"
    
    if [[ ! -d "$files_dir" ]]; then
        warn "Files directory not found at: $files_dir"
        return 0
    fi
    
    # Find all dotfiles in the files directory with null-delimited output
    local dotfiles
    dotfiles=$(find "$files_dir" -maxdepth 1 -name ".*" -type f -print0 2>/dev/null || true)
    
    if [[ -z "$dotfiles" ]]; then
        info "No dotfiles found in $files_dir"
        return 0
    fi
    
    info "Found dotfiles: $(echo "$dotfiles" | tr '\0' '\n' | xargs basename -a | tr '\n' ' ')"
    
    while IFS= read -r -d '' dotfile; do
        local filename
        filename=$(basename "$dotfile")
        local target="$HOME/$filename"
        
        if [[ "$DRY_RUN" == true ]]; then
            if [[ -L "$target" ]]; then
                info "DRY RUN: Would update symlink $target -> $dotfile"
            elif [[ -f "$target" ]]; then
                warn "DRY RUN: Would backup $target and create symlink to $dotfile"
            else
                info "DRY RUN: Would create symlink $target -> $dotfile"
            fi
            continue
        fi
        
        # Check if target already exists
        if [[ -L "$target" ]]; then
            # Check if it's already pointing to the right place
            if [[ "$(readlink "$target")" == "$dotfile" ]]; then
                success "✓ Symlink already exists: $target"
            else
                info "Updating symlink: $target"
                rm "$target"
                ln -s "$dotfile" "$target"
                success "✓ Updated symlink: $target"
            fi
        elif [[ -f "$target" ]]; then
            # Backup existing file
            local backup="$target.backup.$(date +%Y%m%d-%H%M%S)"
            info "Backing up existing file: $target -> $backup"
            mv "$target" "$backup"
            ln -s "$dotfile" "$target"
            success "✓ Created symlink: $target (backed up original to $backup)"
        else
            # Create new symlink
            ln -s "$dotfile" "$target"
            success "✓ Created symlink: $target"
        fi
    done < <(printf '%s' "$dotfiles")
}

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

# Setup Dock items
setup_dock() {
    info "Setting up Dock items..."
    
    # Check if dockutil is available (it should be installed via Homebrew)
    if ! command -v dockutil >/dev/null 2>&1; then
        warn "dockutil not found. Dock customization will be skipped."
        info "dockutil should be installed via Homebrew. You can run dock customization manually later."
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would customize Dock with applications and folders"
        return 0
    fi
    
    # Function to add applications to the Dock
    add_apps_to_dock() {
        local category="$1"
        shift
        local apps=("$@")
        
        info "Adding $category applications to Dock..."
        for app in "${apps[@]}"; do
            if dockutil --no-restart --add "$app" >/dev/null 2>&1; then
                success "✓ Added $app to Dock"
            else
                warn "Failed to add $app to Dock (may not be installed)"
            fi
        done
        # Add spacer after each category
        dockutil --no-restart --add '' --type small-spacer --section apps >/dev/null 2>&1
    }
    
    info "Clearing existing Dock items..."
    if dockutil --no-restart --remove all >/dev/null 2>&1; then
        success "✓ Cleared existing Dock items"
    else
        warn "Failed to clear existing Dock items"
    fi
    
    # Define application categories and their paths
    local smart_home_apps=(
        "/Applications/Home Assistant.app"
    )
    
    local music_apps=(
        "/System/Applications/Music.app"
        "/Applications/Spotify.app"
    )
    
    local browser_apps=(
        "/System/Cryptexes/App/System/Applications/Safari.app"
        "/Applications/Google Chrome.app"
        "/Applications/Zen.app"
    )
    
    local communication_apps=(
        "/System/Applications/Mail.app"
        "/Applications/Mimestream.app"
        "/Applications/Slack.app"
        "/System/Applications/Messages.app"
    )
    
    local productivity_apps=(
        "/Applications/ChatGPT.app"
        "/Applications/GCal for Google Calendar.app"
        "/System/Applications/Calendar.app"
    )
    
    local development_tools=(
        "/Applications/Cursor.app"
        "/Applications/Ghostty.app"
    )
    
    local system_preferences=(
        "/System/Applications/System Settings.app"
    )
    
    # Add applications to the Dock
    add_apps_to_dock "Smart Home" "${smart_home_apps[@]}"
    add_apps_to_dock "Music" "${music_apps[@]}"
    add_apps_to_dock "Browser" "${browser_apps[@]}"
    add_apps_to_dock "Communication" "${communication_apps[@]}"
    add_apps_to_dock "Productivity" "${productivity_apps[@]}"
    add_apps_to_dock "Development" "${development_tools[@]}"
    add_apps_to_dock "System Preferences" "${system_preferences[@]}"
    
    # Add folders to the Dock
    info "Adding folders to Dock..."
    if dockutil --no-restart --add "/Applications" --view auto --display folder --sort name >/dev/null 2>&1; then
        success "✓ Added Applications folder to Dock"
    else
        warn "Failed to add Applications folder to Dock"
    fi
    
    if dockutil --no-restart --add '~/Downloads' --view auto --display folder --sort dateadded >/dev/null 2>&1; then
        success "✓ Added Downloads folder to Dock"
    else
        warn "Failed to add Downloads folder to Dock"
    fi
    
    # Restart Dock to apply changes
    info "Restarting Dock to apply changes..."
    if killall Dock >/dev/null 2>&1; then
        success "✓ Dock restarted successfully"
    else
        warn "Failed to restart Dock (changes may still be applied)"
    fi
    
    success "Dock customization completed successfully! 🚀"
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
    clone_repository
    install_homebrew
    install_brewfile
    setup_dotfiles
    setup_ssh_config
    verify_homebrew
    setup_dock
    
    success "macOS bootstrap setup completed successfully!"
    info "Log file saved to: $LOG_FILE"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_args "$@"
    main
fi
