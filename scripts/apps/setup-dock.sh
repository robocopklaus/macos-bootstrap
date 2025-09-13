#!/usr/bin/env bash

# Dock Setup
# Description: Customizes Dock with organized application categories

set -Eeuo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Check if application exists
app_exists() {
    local app_path="$1"
    [[ -d "$app_path" ]]
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
        local added_count=0
        
        info "Adding $category applications to Dock..."
        for app in "${apps[@]}"; do
            if app_exists "$app"; then
                if dockutil --no-restart --add "$app" >/dev/null 2>&1; then
                    success "✓ Added $app to Dock"
                    ((added_count++))
                else
                    warn "Failed to add $app to Dock"
                fi
            else
                if [[ "$VERBOSE" == true ]]; then
                    info "Skipping $app (not installed)"
                fi
            fi
        done
        
        # Add spacer after each category if apps were added
        if [[ $added_count -gt 0 ]]; then
            dockutil --no-restart --add '' --type small-spacer --section apps >/dev/null 2>&1
        fi
    }
    
    info "Clearing existing Dock items..."
    # Backup Dock plist before modification
    if [[ "$DRY_RUN" != true ]]; then
        local dock_plist="$HOME/Library/Preferences/com.apple.dock.plist"
        if [[ -f "$dock_plist" ]]; then
            local backup="$HOME/Library/Preferences/com.apple.dock.plist.backup.$(date +%Y%m%d-%H%M%S)"
            cp "$dock_plist" "$backup" && success "✓ Backed up Dock plist to $backup" || warn "Failed to back up Dock plist"
        fi
    fi
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

# Main function
main() {
    setup_dock
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_traps
    main
fi 
