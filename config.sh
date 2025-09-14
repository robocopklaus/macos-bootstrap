#!/usr/bin/env bash

# macOS Bootstrap Configuration

# Repository
REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/robocopklaus/macos-bootstrap.git}"
REPOSITORY_BRANCH="${REPOSITORY_BRANCH:-main}"
MACOS_BOOTSTRAP_DIR="${MACOS_BOOTSTRAP_DIR:-$HOME/.macos-bootstrap}"

# Installation Options
INSTALL_MACOS_UPDATES="${INSTALL_MACOS_UPDATES:-true}"
INSTALL_XCODE_TOOLS="${INSTALL_XCODE_TOOLS:-true}"
INSTALL_HOMEBREW="${INSTALL_HOMEBREW:-true}"
INSTALL_APPLICATIONS="${INSTALL_APPLICATIONS:-true}"
SETUP_DOTFILES="${SETUP_DOTFILES:-true}"
CONFIGURE_SSH="${CONFIGURE_SSH:-true}"
MACOS_DEFAULTS_ENABLED="${MACOS_DEFAULTS_ENABLED:-true}"
CUSTOMIZE_DOCK="${CUSTOMIZE_DOCK:-true}"

# SSH Configuration
SSH_USE_1PASSWORD_AGENT="${SSH_USE_1PASSWORD_AGENT:-true}"
SSH_AGENT_SOCKET="${SSH_AGENT_SOCKET:-~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock}"

# Logging
LOG_FILE_PATTERN="${LOG_FILE_PATTERN:-/tmp/macos-bootstrap-{timestamp}.log}"
VERBOSE_LOGGING="${VERBOSE_LOGGING:-false}"
DRY_RUN_MODE="${DRY_RUN_MODE:-false}"

# Dock Application Paths
DOCK_CATEGORIES="${DOCK_CATEGORIES:-smart_home,music,browser,communication,productivity,development,system}"
DOCK_APPS=(
    [smart_home]="/Applications/Home Assistant.app"
    [music]="/System/Applications/Music.app,/Applications/Spotify.app"
    [browser]="/System/Cryptexes/App/System/Applications/Safari.app,/Applications/Google Chrome.app,/Applications/Zen.app"
    [communication]="/System/Applications/Mail.app,/Applications/Mimestream.app,/Applications/Slack.app,/System/Applications/Messages.app"
    [productivity]="/Applications/GCal for Google Calendar.app,/System/Applications/Calendar.app"
    [development]="/Applications/Cursor.app,/Applications/Ghostty.app"
    [system]="/System/Applications/System Settings.app"
)

# Helper Functions
load_custom_config() {
    local custom_config="$1"
    if [[ -f "$custom_config" ]]; then
        info "Loading custom configuration from: $custom_config"
        source "$custom_config"
    else
        error "Custom configuration file not found: $custom_config"
        return 1
    fi
}

export_config() {
    export REPOSITORY_URL REPOSITORY_BRANCH MACOS_BOOTSTRAP_DIR
    export INSTALL_MACOS_UPDATES INSTALL_XCODE_TOOLS INSTALL_HOMEBREW INSTALL_APPLICATIONS
    export SETUP_DOTFILES CONFIGURE_SSH MACOS_DEFAULTS_ENABLED CUSTOMIZE_DOCK
    export SSH_USE_1PASSWORD_AGENT SSH_AGENT_SOCKET
    export LOG_FILE_PATTERN VERBOSE_LOGGING DRY_RUN_MODE
    export DOCK_CATEGORIES
    declare -p DOCK_APPS > /dev/null 2>&1 && export DOCK_APPS
} 