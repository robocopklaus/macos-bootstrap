#!/usr/bin/env bash

# Application Setup - Installs and configures applications

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

REPO_ROOT=$(resolve_repo_root "$SCRIPT_DIR")
readonly BREWFILE_PATH="$REPO_ROOT/Brewfile"

# Validate Brewfile location
ensure_brewfile_exists() {
    if [[ ! -f "$BREWFILE_PATH" ]]; then
        error "Brewfile not found at: $BREWFILE_PATH"
        return 1
    fi

    info "Using Brewfile: $BREWFILE_PATH"
}

# Install base Homebrew dependencies (formulae + taps).
install_base_dependencies() {
    info "Installing base Homebrew dependencies..."

    if ! ensure_brew_in_path; then
        error "brew not found. Ensure Homebrew is installed and available in PATH"
        return 1
    fi

    ensure_brewfile_exists || return 1

    if run env HOMEBREW_BUNDLE_CASK_SKIP=1 HOMEBREW_BUNDLE_MAS_SKIP=1 brew bundle --file="$BREWFILE_PATH"; then
        success "Base dependencies installed successfully"
    else
        error "Failed to install base dependencies"
        return 1
    fi
}

# Install cask apps one-by-one so optional app failures are non-fatal.
install_cask_apps() {
    if [[ "${INSTALL_CASK_APPS:-true}" != "true" ]]; then
        info "Skipping cask apps (INSTALL_CASK_APPS=false)"
        return 0
    fi

    info "Installing cask apps from Brewfile..."
    ensure_brewfile_exists || return 1

    local cask_apps=()
    local cask_line
    while IFS= read -r cask_line; do
        [[ -n "$cask_line" ]] && cask_apps+=("$cask_line")
    done < <(HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --cask --file="$BREWFILE_PATH" 2>/dev/null || true)

    if (( ${#cask_apps[@]} == 0 )); then
        info "No cask apps defined in Brewfile"
        return 0
    fi

    local failed_apps=()
    local cask_app
    for cask_app in "${cask_apps[@]}"; do
        if [[ "$DRY_RUN" != true ]] && brew list --cask "$cask_app" >/dev/null 2>&1; then
            if [[ "$VERBOSE" == true ]]; then
                info "Skipping $cask_app (already installed)"
            fi
            continue
        fi

        if run brew install --cask "$cask_app"; then
            if [[ "$DRY_RUN" != true ]]; then
                success "✓ Installed cask: $cask_app"
            fi
        else
            warn "Failed to install optional cask: $cask_app"
            failed_apps+=("$cask_app")
        fi
    done

    if (( ${#failed_apps[@]} > 0 )); then
        warn "Some optional cask installs failed: ${failed_apps[*]}"
        warn "Continuing bootstrap; re-run this module later to retry"
    else
        success "Cask apps processed successfully"
    fi
}

# Install Mac App Store apps as an optional, non-blocking phase.
install_mas_apps() {
    if [[ "${INSTALL_MAS_APPS:-false}" != "true" ]]; then
        info "Skipping Mac App Store apps (INSTALL_MAS_APPS=false)"
        return 0
    fi

    info "Installing Mac App Store apps from Brewfile..."

    ensure_brewfile_exists || return 1

    if [[ "$DRY_RUN" != true ]] && ! command -v mas >/dev/null 2>&1; then
        warn "mas CLI not found. Skipping Mac App Store apps"
        warn "Install mas and sign in to the App Store, then re-run this module"
        return 0
    fi

    local mas_entries=()
    local mas_line
    while IFS= read -r mas_line; do
        [[ -n "$mas_line" ]] && mas_entries+=("$mas_line")
    done < <(
        awk -F'"' '/^[[:space:]]*mas[[:space:]]*"/ {
            name=$2
            if (match($0, /id:[[:space:]]*[0-9]+/)) {
                id=substr($0, RSTART + 3, RLENGTH - 3)
                gsub(/[[:space:]]/, "", id)
                print name "|" id
            }
        }' "$BREWFILE_PATH"
    )

    if (( ${#mas_entries[@]} == 0 )); then
        info "No Mac App Store apps defined in Brewfile"
        return 0
    fi

    local installed_ids=""
    if [[ "$DRY_RUN" != true ]]; then
        installed_ids="$(mas list 2>/dev/null | awk '{print $1}')"
    fi

    local failed_apps=()
    local entry
    for entry in "${mas_entries[@]}"; do
        local app_name="${entry%%|*}"
        local app_id="${entry##*|}"

        if [[ "$DRY_RUN" != true ]] && grep -qx "$app_id" <<< "$installed_ids"; then
            if [[ "$VERBOSE" == true ]]; then
                info "Skipping $app_name (already installed from App Store)"
            fi
            continue
        fi

        if run mas install "$app_id"; then
            if [[ "$DRY_RUN" != true ]]; then
                success "✓ Installed MAS app: $app_name"
                installed_ids+=$'\n'"$app_id"
            fi
        else
            warn "Failed to install optional MAS app: $app_name"
            failed_apps+=("$app_name")
        fi
    done

    if (( ${#failed_apps[@]} > 0 )); then
        warn "Some optional MAS installs failed: ${failed_apps[*]}"
        warn "Continuing bootstrap; re-run this module after App Store login/state fixes"
    else
        success "Mac App Store apps processed successfully"
    fi
}

# Resolve an app path across common install locations.
resolve_app_path() {
    local app_path="$1"
    local app_name
    app_name="$(basename "$app_path")"

    local candidates=(
        "$app_path"
        "/Applications/$app_name"
        "$HOME/Applications/$app_name"
        "/System/Applications/$app_name"
        "/System/Cryptexes/App/System/Applications/$app_name"
    )

    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -d "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
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
            local resolved_app
            if resolved_app="$(resolve_app_path "$app")"; then
                if dock_item_exists "$resolved_app"; then
                    if [[ "$VERBOSE" == true ]]; then
                        info "Skipping $resolved_app (already in Dock)"
                    fi
                elif dockutil --no-restart --add "$resolved_app" >/dev/null 2>&1; then
                    success "✓ Added $resolved_app to Dock"
                    ((added_count++))
                else
                    warn "Failed to add $resolved_app to Dock"
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
    install_base_dependencies
    install_cask_apps
    install_mas_apps

    if [[ "${CUSTOMIZE_DOCK:-true}" == "true" ]]; then
        setup_dock
    else
        info "Dock customization disabled via CUSTOMIZE_DOCK=false"
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_script
    parse_args "$@"
    main
fi
