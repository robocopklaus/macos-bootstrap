#!/usr/bin/env bash

# macOS Bootstrap Configuration

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
VERBOSE_LOGGING="${VERBOSE_LOGGING:-false}"
DRY_RUN_MODE="${DRY_RUN_MODE:-false}"

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
    export INSTALL_MACOS_UPDATES INSTALL_XCODE_TOOLS INSTALL_HOMEBREW INSTALL_APPLICATIONS
    export SETUP_DOTFILES CONFIGURE_SSH MACOS_DEFAULTS_ENABLED CUSTOMIZE_DOCK
    export SSH_USE_1PASSWORD_AGENT SSH_AGENT_SOCKET
    export VERBOSE_LOGGING DRY_RUN_MODE
} 