#!/usr/bin/env bash

# macOS Bootstrap Configuration
# Description: Configuration file for the bootstrap process
# Version: 1.0.0

# Repository Configuration
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
CUSTOMIZE_DOCK="${CUSTOMIZE_DOCK:-true}"

# Dock Configuration
DOCK_ENABLED="${DOCK_ENABLED:-true}"
DOCK_CATEGORIES="${DOCK_CATEGORIES:-smart_home,music,browser,communication,productivity,development,system}"

# SSH Configuration
SSH_USE_1PASSWORD_AGENT="${SSH_USE_1PASSWORD_AGENT:-true}"
SSH_AGENT_SOCKET="${SSH_AGENT_SOCKET:-~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock}"

# Logging Configuration
LOG_FILE_PATTERN="${LOG_FILE_PATTERN:-/tmp/macos-bootstrap-{timestamp}.log}"
VERBOSE_LOGGING="${VERBOSE_LOGGING:-false}"
DRY_RUN_MODE="${DRY_RUN_MODE:-false}"

# Function to load custom configuration
load_custom_config() {
    local custom_config="$1"
    
    if [[ -f "$custom_config" ]]; then
        info "Loading custom configuration from: $custom_config"
        source "$custom_config"
    fi
}

# Function to export configuration as environment variables
export_config() {
    export REPOSITORY_URL
    export REPOSITORY_BRANCH
    export MACOS_BOOTSTRAP_DIR
    export INSTALL_MACOS_UPDATES
    export INSTALL_XCODE_TOOLS
    export INSTALL_HOMEBREW
    export INSTALL_APPLICATIONS
    export SETUP_DOTFILES
    export CONFIGURE_SSH
    export CUSTOMIZE_DOCK
    export DOCK_ENABLED
    export DOCK_CATEGORIES
    export SSH_USE_1PASSWORD_AGENT
    export SSH_AGENT_SOCKET
    export LOG_FILE_PATTERN
    export VERBOSE_LOGGING
    export DRY_RUN_MODE
} 