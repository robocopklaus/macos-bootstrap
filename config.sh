#!/usr/bin/env bash

# macOS Bootstrap Configuration
# 
# This file contains all configuration options for the macOS bootstrap process.
# You can customize these settings to tailor the installation to your needs.
#
# Version: 1.0.0
# 
# Configuration Categories:
# - Repository: Git repository settings
# - Installation: What components to install
# - Dock: Dock customization settings
# - SSH: SSH configuration options
# - Logging: Logging and debugging options
# - Applications: Application paths for dock organization

# =============================================================================
# REPOSITORY CONFIGURATION
# =============================================================================

# Git repository URL for the bootstrap project
# Change this if you're using a fork or custom repository
REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/robocopklaus/macos-bootstrap.git}"

# Git branch to use (usually 'main' or 'master')
REPOSITORY_BRANCH="${REPOSITORY_BRANCH:-main}"

# Local directory where the bootstrap project will be stored
# This is where the repository will be cloned
MACOS_BOOTSTRAP_DIR="${MACOS_BOOTSTRAP_DIR:-$HOME/.macos-bootstrap}"

# =============================================================================
# INSTALLATION OPTIONS
# =============================================================================

# Whether to check for and install macOS updates
# Set to 'false' to skip macOS updates
INSTALL_MACOS_UPDATES="${INSTALL_MACOS_UPDATES:-true}"

# Whether to install Xcode Command Line Tools
# Required for development tools like Git
INSTALL_XCODE_TOOLS="${INSTALL_XCODE_TOOLS:-true}"

# Whether to install Homebrew package manager
# Required for installing applications
INSTALL_HOMEBREW="${INSTALL_HOMEBREW:-true}"

# Whether to install applications from Brewfile
# This installs all the applications defined in Brewfile
INSTALL_APPLICATIONS="${INSTALL_APPLICATIONS:-true}"

# Whether to set up dotfiles
# This configures shell and other configuration files
SETUP_DOTFILES="${SETUP_DOTFILES:-true}"

# Whether to configure SSH settings
# Sets up SSH with 1Password integration
CONFIGURE_SSH="${CONFIGURE_SSH:-true}"

# Whether to configure macOS system defaults
# Sets various macOS system preferences using the defaults command
MACOS_DEFAULTS_ENABLED="${MACOS_DEFAULTS_ENABLED:-true}"

# Whether to customize the Dock
# Organizes applications in the Dock by category
CUSTOMIZE_DOCK="${CUSTOMIZE_DOCK:-true}"

# =============================================================================
# DOCK CONFIGURATION
# =============================================================================

# Whether dock customization is enabled
# Set to 'false' to skip dock setup
DOCK_ENABLED="${DOCK_ENABLED:-true}"

# Comma-separated list of dock categories to create
# Categories: smart_home, music, browser, communication, productivity, development, system
DOCK_CATEGORIES="${DOCK_CATEGORIES:-smart_home,music,browser,communication,productivity,development,system}"

# =============================================================================
# SSH CONFIGURATION
# =============================================================================

# Whether to use 1Password SSH agent
# Enables 1Password for SSH key management
SSH_USE_1PASSWORD_AGENT="${SSH_USE_1PASSWORD_AGENT:-true}"

# Path to 1Password SSH agent socket
# Default location for 1Password SSH agent
SSH_AGENT_SOCKET="${SSH_AGENT_SOCKET:-~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock}"

# =============================================================================
# MACOS DEFAULTS CONFIGURATION
# =============================================================================

# Whether macOS defaults configuration is enabled
# Set to 'false' to skip macOS defaults configuration
MACOS_DEFAULTS_ENABLED="${MACOS_DEFAULTS_ENABLED:-true}"

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

# Pattern for log file names
# {timestamp} will be replaced with current timestamp
LOG_FILE_PATTERN="${LOG_FILE_PATTERN:-/tmp/macos-bootstrap-{timestamp}.log}"

# Whether to enable verbose logging
# Provides more detailed output during installation
VERBOSE_LOGGING="${VERBOSE_LOGGING:-false}"

# Whether to run in dry-run mode
# Shows what would be done without making changes
DRY_RUN_MODE="${DRY_RUN_MODE:-false}"

# =============================================================================
# APPLICATION PATHS (for dock customization)
# =============================================================================

# Smart home applications
DOCK_APPS_SMART_HOME="${DOCK_APPS_SMART_HOME:-/Applications/Home Assistant.app}"

# Music and audio applications
DOCK_APPS_MUSIC="${DOCK_APPS_MUSIC:-/System/Applications/Music.app,/Applications/Spotify.app}"

# Web browsers
DOCK_APPS_BROWSER="${DOCK_APPS_BROWSER:-/System/Cryptexes/App/System/Applications/Safari.app,/Applications/Google Chrome.app,/Applications/Zen.app}"

# Communication applications
DOCK_APPS_COMMUNICATION="${DOCK_APPS_COMMUNICATION:-/System/Applications/Mail.app,/Applications/Mimestream.app,/Applications/Slack.app,/System/Applications/Messages.app}"

# Productivity applications
DOCK_APPS_PRODUCTIVITY="${DOCK_APPS_PRODUCTIVITY:-/Applications/GCal for Google Calendar.app,/System/Applications/Calendar.app}"

# Development applications
DOCK_APPS_DEVELOPMENT="${DOCK_APPS_DEVELOPMENT:-/Applications/Cursor.app,/Applications/Ghostty.app}"

# System applications
DOCK_APPS_SYSTEM="${DOCK_APPS_SYSTEM:-/System/Applications/System Settings.app}"

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Function to load custom configuration
# Usage: load_custom_config "/path/to/custom-config.sh"
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

# Function to export configuration as environment variables
# This makes all configuration variables available to child processes
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
    export MACOS_DEFAULTS_ENABLED
    export CUSTOMIZE_DOCK
    export DOCK_ENABLED
    export DOCK_CATEGORIES
    export SSH_USE_1PASSWORD_AGENT
    export SSH_AGENT_SOCKET
    export LOG_FILE_PATTERN
    export VERBOSE_LOGGING
    export DRY_RUN_MODE
    export DOCK_APPS_SMART_HOME
    export DOCK_APPS_MUSIC
    export DOCK_APPS_BROWSER
    export DOCK_APPS_COMMUNICATION
    export DOCK_APPS_PRODUCTIVITY
    export DOCK_APPS_DEVELOPMENT
    export DOCK_APPS_SYSTEM
} 