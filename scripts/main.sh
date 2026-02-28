#!/usr/bin/env bash

# macOS Bootstrap Main Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Determine and export repository root for all modules
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export REPO_ROOT

# Ensure single-run log file for all modules
LOG_FILE="${LOG_FILE:-/tmp/macos-bootstrap-$(date +%Y%m%d-%H%M%S).log}"
export LOG_FILE

# Load configuration
if [[ -f "$SCRIPT_DIR/../config.sh" ]]; then
    # shellcheck source=../config.sh
    source "$SCRIPT_DIR/../config.sh"
    export_config
fi

# Run a module script
run_module() {
    local module_name="$1"
    local module_script="$2"
    local enabled_var="$3"
    
    # Check if module is enabled
    if [[ "${!enabled_var}" != "true" ]]; then
        info "Skipping disabled module: $module_name"
        return 0
    fi
    
    info "Running module: $module_name"

    if [[ -f "$module_script" ]]; then
        if bash "$module_script"; then
            success "✓ Module completed: $module_name"
        else
            error "✗ Module failed: $module_name"
            return 1
        fi
    else
        error "Module script not found: $module_script"
        return 1
    fi
}

# Main execution function
main() {
    setup_traps
    info "Starting macOS bootstrap setup"
    info "Log file: $LOG_FILE"
    
    if [[ "$DRY_RUN" == true ]]; then
        warn "DRY RUN MODE: No changes will be made"
    fi
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Run setup steps
    check_platform
    ask_for_sudo
    
    # Core system setup
    run_module "macOS Updates" "$SCRIPT_DIR/core/update-macos.sh" "INSTALL_MACOS_UPDATES"
    run_module "Xcode CLI Tools" "$SCRIPT_DIR/core/install-xcode-tools.sh" "INSTALL_XCODE_TOOLS" || exit 1

    # Install tools and applications (Homebrew is critical - apps depend on it)
    run_module "Homebrew" "$SCRIPT_DIR/core/install-homebrew.sh" "INSTALL_HOMEBREW" || exit 1
    run_module "Applications & Dock" "$SCRIPT_DIR/apps/setup-apps.sh" "INSTALL_APPLICATIONS"

    # Configuration
    run_module "Dotfiles" "$SCRIPT_DIR/config/setup-dotfiles.sh" "SETUP_DOTFILES"
    run_module "macOS Defaults" "$SCRIPT_DIR/config/configure-macos-defaults.sh" "MACOS_DEFAULTS_ENABLED"
    
    success "macOS bootstrap setup completed successfully!"
    info "Log file saved to: $LOG_FILE"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_script
    parse_args "$@"
    export DRY_RUN VERBOSE NON_INTERACTIVE
    main
fi 
