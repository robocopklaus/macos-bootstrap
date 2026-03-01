#!/usr/bin/env bash

# macOS Bootstrap Configuration

# Installation Options
INSTALL_MACOS_UPDATES="${INSTALL_MACOS_UPDATES:-true}"
INSTALL_XCODE_TOOLS="${INSTALL_XCODE_TOOLS:-true}"
INSTALL_HOMEBREW="${INSTALL_HOMEBREW:-true}"
INSTALL_APPLICATIONS="${INSTALL_APPLICATIONS:-true}"
INSTALL_CASK_APPS="${INSTALL_CASK_APPS:-true}"
INSTALL_MAS_APPS="${INSTALL_MAS_APPS:-false}"
SETUP_DOTFILES="${SETUP_DOTFILES:-true}"
MACOS_DEFAULTS_ENABLED="${MACOS_DEFAULTS_ENABLED:-false}"
CUSTOMIZE_DOCK="${CUSTOMIZE_DOCK:-true}"

# Logging
VERBOSE_LOGGING="${VERBOSE_LOGGING:-false}"
DRY_RUN_MODE="${DRY_RUN_MODE:-false}"

# Helper Functions
load_custom_config() {
    local custom_config="$1"
    if [[ -f "$custom_config" ]]; then
        printf '[INFO] Loading custom configuration from: %s\n' "$custom_config"
        # shellcheck source=/dev/null
        source "$custom_config"
    else
        printf '[ERROR] Custom configuration file not found: %s\n' "$custom_config" >&2
        return 1
    fi
}

export_config() {
    export INSTALL_MACOS_UPDATES INSTALL_XCODE_TOOLS INSTALL_HOMEBREW INSTALL_APPLICATIONS
    export INSTALL_CASK_APPS INSTALL_MAS_APPS
    export SETUP_DOTFILES MACOS_DEFAULTS_ENABLED CUSTOMIZE_DOCK
    export VERBOSE_LOGGING DRY_RUN_MODE
}
