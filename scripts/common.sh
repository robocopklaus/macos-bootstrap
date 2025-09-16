#!/usr/bin/env bash

# Common functions for macOS bootstrap scripts
# Description: Shared utilities and functions

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../config.sh
if [[ -f "$SCRIPT_DIR/../config.sh" ]]; then
    source "$SCRIPT_DIR/../config.sh"
    export_config
fi

# Configuration
# Avoid SC2155: declare and assign separately
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
# Respect pre-set LOG_FILE/TEMP_DIR to enable single-run logging across modules
LOG_FILE="${LOG_FILE:-/tmp/macos-bootstrap-$(date +%Y%m%d-%H%M%S).log}"
TEMP_DIR="${TEMP_DIR:-/tmp/macos-bootstrap-$$}"
export LOG_FILE TEMP_DIR

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Global variables (can be overridden by calling scripts or config)
DRY_RUN=${DRY_RUN:-${DRY_RUN_MODE:-false}}
VERBOSE=${VERBOSE:-${VERBOSE_LOGGING:-false}}
SUDO_PID=${SUDO_PID:-""}
NON_INTERACTIVE=${NON_INTERACTIVE:-false}

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

info() { log "INFO" "$*"; }
warn() { log "WARN" "${YELLOW}$*${NC}"; }
error() { log "ERROR" "${RED}$*${NC}"; }
success() { log "SUCCESS" "${GREEN}$*${NC}"; }

# Helper to run commands with DRY_RUN awareness
run() {
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN: Would run: $*"
        return 0
    fi
    "$@"
}

# Ensure Homebrew is available in PATH for the current session
ensure_brew_in_path() {
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi

    local brew_bin=""
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        brew_bin="/opt/homebrew/bin/brew"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        brew_bin="/usr/local/bin/brew"
    fi

    if [[ -n "$brew_bin" ]]; then
        # Use brew shellenv to configure PATH and related vars
        # shellcheck disable=SC2046
        eval "$($brew_bin shellenv)"
        if command -v brew >/dev/null 2>&1; then
            info "Configured Homebrew environment for current session"
            return 0
        fi
    fi

    # Fallback: prepend common brew bin directories
    if [[ -d "/opt/homebrew/bin" ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
    if [[ -d "/usr/local/bin" ]]; then
        export PATH="/usr/local/bin:$PATH"
    fi

    if command -v brew >/dev/null 2>&1; then
        return 0
    fi

    warn "Homebrew not found in PATH"
    return 1
}

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

# Shared script initialization
init_script() {
    set -Eeuo pipefail
    setup_traps
}

# Trap setup is opt-in to avoid side effects when sourcing.
setup_traps() {
    # Ensure ERR traps propagate into functions and subshells
    set -E
    trap error_handler ERR
    trap cleanup EXIT
}

# Check if running on macOS
check_platform() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script is designed for macOS only"
        exit 1
    fi
    info "Platform check passed: macOS detected"
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

# Display usage information
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
    -d, --dry-run    Preview what the script will do without making changes
    -v, --verbose    Enable verbose output
    -h, --help       Show this help message
    -c, --config     Specify custom configuration file
    -y, --yes        Non-interactive mode; auto-confirm prompts

Description:
    This script safely updates macOS and installs essential development tools.
    It will:
    - Update macOS software (with user confirmation)
    - Install Xcode Command Line Tools if not present
    - Install Homebrew and applications from Brewfile
    - Provide detailed logging of all operations

Examples:
    $SCRIPT_NAME                    # Run normally
    $SCRIPT_NAME --dry-run          # Preview changes
    $SCRIPT_NAME --verbose          # Run with verbose output
    $SCRIPT_NAME --config my-config.sh  # Use custom config
    $SCRIPT_NAME --yes                  # Auto-confirm prompts

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
            -y|--yes)
                NON_INTERACTIVE=true
                shift
                ;;
            -c|--config)
                if [[ -n "${2:-}" ]]; then
                    if load_custom_config "$2"; then
                        export_config
                    else
                        exit 1
                    fi
                    shift 2
                else
                    error "Config file path required for --config option"
                    exit 1
                fi
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
