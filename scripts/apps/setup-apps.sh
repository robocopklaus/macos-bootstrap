#!/usr/bin/env bash

# Application Setup - Installs and configures applications

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

REPO_ROOT=$(resolve_repo_root "$SCRIPT_DIR")

# Install applications from Brewfile
install_brewfile() {
    info "Installing applications from Brewfile..."

    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would install applications from Brewfile"
        return 0
    fi

    # Ensure brew command is available in this shell
    if ! ensure_brew_in_path; then
        error "brew not found. Ensure Homebrew is installed and available in PATH"
        return 1
    fi

    local brewfile_path="$REPO_ROOT/Brewfile"

    if [[ ! -f "$brewfile_path" ]]; then
        error "Brewfile not found at: $brewfile_path"
        return 1
    fi

    info "Using Brewfile: $brewfile_path"

    if run brew bundle --file="$brewfile_path"; then
        success "Applications installed successfully from Brewfile"
    else
        error "Failed to install applications from Brewfile"
        return 1
    fi
}

# Check if application exists
app_exists() {
    local app_path="$1"
    [[ -d "$app_path" ]]
}

# Check if app is already in the Dock
dock_item_exists() {
    local app_path="$1"
    local app_name
    app_name="$(basename "$app_path" .app)"
    dockutil --find "$app_name" >/dev/null 2>&1
}

# Setup Dock items
setup_dock() {
    info "Setting up Dock items..."

    if ! command -v dockutil >/dev/null 2>&1; then
        warn "dockutil not found. Dock customization will be skipped."
        info "dockutil should be installed via Homebrew. You can run dock customization manually later."
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would customize Dock with applications and folders"
        return 0
    fi

    # Function to add applications to the Dock (idempotent - skips existing items)
    add_apps_to_dock() {
        local category="$1"
        shift
        local apps=("$@")
        local added_count=0

        info "Adding $category applications to Dock..."
        for app in "${apps[@]}"; do
            if app_exists "$app"; then
                if dock_item_exists "$app"; then
                    if [[ "$VERBOSE" == true ]]; then
                        info "Skipping $app (already in Dock)"
                    fi
                elif dockutil --no-restart --add "$app" >/dev/null 2>&1; then
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

    # Reset Dock before setup by default (controlled by DOCK_RESET_BEFORE_SETUP env var)
    if [[ "${DOCK_RESET_BEFORE_SETUP:-true}" == "true" ]]; then
        info "Clearing existing Dock items..."
        # Backup Dock plist before modification
        local dock_plist="$HOME/Library/Preferences/com.apple.dock.plist"
        if [[ -f "$dock_plist" ]]; then
            local backup
            backup="$HOME/Library/Preferences/com.apple.dock.plist.backup.$(date +%Y%m%d-%H%M%S)"
            if cp "$dock_plist" "$backup"; then
                success "✓ Backed up Dock plist to $backup"
            else
                warn "Failed to back up Dock plist"
            fi
        fi

        if dockutil --no-restart --remove all >/dev/null 2>&1; then
            success "✓ Cleared existing Dock items"
        else
            warn "Failed to clear existing Dock items"
        fi
    else
        info "Merging apps into existing Dock (set DOCK_RESET_BEFORE_SETUP=false to keep this behavior)"
    fi

    # Define application categories and their paths
    local smart_home_apps=("/Applications/Home Assistant.app")
    local music_apps=("/System/Applications/Music.app")
    local browser_apps=("/System/Cryptexes/App/System/Applications/Safari.app" "/Applications/Google Chrome.app" "/Applications/Zen.app")
    local communication_apps=("/System/Applications/Mail.app" "/Applications/Mimestream.app" "/Applications/Slack.app" "/System/Applications/Messages.app")
    local productivity_apps=("/Applications/ChatGPT.app" "/Applications/GCal for Google Calendar.app" "/System/Applications/Calendar.app")
    local development_tools=("/Applications/Cursor.app" "/Applications/Ghostty.app")
    local system_preferences=("/System/Applications/System Settings.app")

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

    if dockutil --no-restart --add "$HOME/Downloads" --view auto --display folder --sort dateadded >/dev/null 2>&1; then
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

    success "Dock customization completed successfully!"
}

# Main function
main() {
    install_brewfile
    setup_dock
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_script
    main
fi