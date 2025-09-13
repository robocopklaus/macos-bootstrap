#!/bin/bash

# macOS Defaults Configuration Script
# This script configures various macOS system preferences using the `defaults` command

set -Eeuo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
source "$SCRIPT_DIR/../common.sh"

# Configuration
MACOS_DEFAULTS_ENABLED="${MACOS_DEFAULTS_ENABLED:-true}"

# Function to set a default with error handling
set_default() {
    local domain="$1"
    local key="$2"
    local value="$3"
    local data_type="${4:-string}"
    local description="${5:-}"
    
    if [[ -n "$description" ]]; then
        info "Setting $description..."
    else
        info "Setting $domain $key = $value ($data_type)"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would set: defaults write $domain $key -$data_type $value"
        return 0
    fi
    
    if defaults write "$domain" "$key" -"$data_type" "$value"; then
        success "✓ Set $domain $key = $value ($data_type)"
    else
        error "✗ Failed to set $domain $key = $value ($data_type)"
        return 1
    fi
}

# Helper functions for common data types
set_bool() {
    local domain="$1"
    local key="$2"
    local value="$3"
    local description="${4:-}"
    set_default "$domain" "$key" "$value" "bool" "$description"
}

set_int() {
    local domain="$1"
    local key="$2"
    local value="$3"
    local description="${4:-}"
    set_default "$domain" "$key" "$value" "int" "$description"
}

set_float() {
    local domain="$1"
    local key="$2"
    local value="$3"
    local description="${4:-}"
    set_default "$domain" "$key" "$value" "float" "$description"
}

set_string() {
    local domain="$1"
    local key="$2"
    local value="$3"
    local description="${4:-}"
    set_default "$domain" "$key" "$value" "string" "$description"
}

# Function to log section headers
log_section() {
    local section="$1"
    info "=== $section ==="
}

# Function to configure Dock settings
configure_dock() {
    log_section "Configuring Dock"

    set_int "com.apple.dock" "tilesize" "36" "Dock tile size"
    set_int "com.apple.dock" "largesize" "100" "Dock magnification size"
    set_bool "com.apple.dock" "magnification" "true" "Enable Dock magnification"
    set_bool "com.apple.dock" "show-recents" "false" "Hide recent applications in Dock"
}

# Function to configure Desktop settings
configure_desktop() {
    log_section "Configuring Desktop"
    
    set_bool "com.apple.WindowManager" "EnableTopTilingByEdgeDrag" "false" "Don't drag menus to menu bar to fill screen"
}

# Function to configure Sound settings
configure_sound() {
    log_section "Configuring Sound"
    
    set_bool "NSGlobalDomain" "com.apple.sound.beep.feedback" "true" "Enable sound feedback"
}

# Function to configure Finder settings
configure_finder() {
    log_section "Configuring Finder"
    
    # Keep folders on top, set new window target to home, hide external drives, etc.
    set_bool "com.apple.finder" "_FXSortFoldersFirst" "true" "Keep folders on top"
    set_string "com.apple.finder" "NewWindowTarget" "PfHm" "Set new window target to home"
    set_string "com.apple.finder" "NewWindowTargetPath" "file://${HOME}" "Set new window target path to home"
    set_bool "com.apple.finder" "ShowExternalHardDrivesOnDesktop" "false" "Hide external drives on desktop"
    set_bool "com.apple.finder" "ShowRecentTags" "false" "Hide recent tags"
    set_string "com.apple.finder" "FXDefaultSearchScope" "SCcf" "Set default search scope to current folder"
    set_bool "com.apple.finder" "ShowPathbar" "true" "Show path bar"
    set_bool "com.apple.finder" "ShowStatusBar" "true" "Show status bar"
    set_string "com.apple.finder" "FXPreferredViewStyle" "clmv" "Set default view style to column view"

    # Update Finder plist if present
    local finder_plist="$HOME/Library/Preferences/com.apple.finder.plist"
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would update Finder plist: show item info and arrange by name"
    else
        if [[ -f "$finder_plist" ]]; then
            /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" "$finder_plist" || warn "Could not set showItemInfo"
            /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy name" "$finder_plist" || warn "Could not set arrangeBy"
        else
            warn "Finder plist not found at $finder_plist; skipping PlistBuddy edits"
        fi
    fi
}

# Function to configure system preferences
configure_system_preferences() {
    log_section "Configuring System Preferences"
    
}

# Function to configure security settings
configure_security() {
    log_section "Configuring Security Settings"
    
}

# Function to configure trackpad settings
configure_trackpad() {
    log_section "Configuring Trackpad"

    set_int "NSGlobalDomain" "com.apple.mouse.tapBehavior" "1" "Tap with one finger"
    
    set_bool "com.apple.AppleMultitouchTrackpad" "Clicking" "true" "Enable tapping"
    set_bool "com.apple.AppleMultitouchTrackpad" "Dragging" "true" "Enable dragging"
    set_bool "com.apple.AppleMultitouchTrackpad" "TrackpadThreeFingerDrag" "true" "Enable three finger drag"
    
    set_bool "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Clicking" "true" "Enable tapping"
    set_bool "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Dragging" "true" "Enable dragging"
    set_bool "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadThreeFingerDrag" "true" "Enable three finger drag"
    
}

# Function to configure keyboard settings
configure_keyboard() {
    log_section "Configuring Keyboard"
    
    set_int "NSGlobalDomain" "KeyRepeat" "2" "Set keyboard repeat rate"
    set_int "NSGlobalDomain" "InitialKeyRepeat" "15" "Set initial key repeat delay"
}

# Function to configure Safari settings
configure_safari() {
    log_section "Configuring Safari"
    
}

# Function to configure Terminal settings
configure_terminal() {
    log_section "Configuring Terminal"
    
}

# Function to configure other applications
configure_other_apps() {
    log_section "Configuring Other Applications"
    
}

# Function to restart affected applications
restart_applications() {
    log_section "Restarting Affected Applications"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would restart: Dock, Finder, SystemUIServer"
        return 0
    fi
    
    info "Restarting Dock..."
    killall Dock 2>/dev/null || true
    
    info "Restarting Finder..."
    killall Finder 2>/dev/null || true
    
    info "Restarting SystemUIServer..."
    killall SystemUIServer 2>/dev/null || true
    
    success "✓ Applications restarted"
}

# Main function
main() {
    info "Starting macOS defaults configuration..."
    
    if [[ "$MACOS_DEFAULTS_ENABLED" != "true" ]]; then
        info "macOS defaults configuration is disabled. Skipping..."
        return 0
    fi
    
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script is designed for macOS only"
        exit 1
    fi
    
    # Check if running as root
    if [[ "$EUID" -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
    
    configure_dock
    configure_finder
    configure_system_preferences
    configure_security
    configure_trackpad
    configure_keyboard
    configure_safari
    configure_terminal
    configure_other_apps
    
    if [[ "$DRY_RUN" != "true" ]]; then
        restart_applications
    fi
    
    success "macOS defaults configuration completed successfully!"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_traps
    parse_args "$@"
    main
fi 
